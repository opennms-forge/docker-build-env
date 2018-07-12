#!/bin/bash -e
# =====================================================================
# Build script running OpenNMS in Docker environment
#
# Source: https://github.com/opennms-forge/docker-horizon-core-web
# Web: https://www.opennms.org
#
# =====================================================================

OPENNMS_DATASOURCES_TPL=/tmp/opennms-datasources.xml.tpl
OPENNMS_DATASOURCES_CFG=${OPENNMS_HOME}/etc/opennms-datasources.xml
OPENNMS_OVERLAY_CFG=/opt/opennms-etc-overlay

OPENNMS_UPGRADE_GUARD=${OPENNMS_HOME}/etc/do-upgrade
OPENNMS_CONFIGURED_GUARD=${OPENNMS_HOME}/etc/configured

OPENNMS_KARAF_TPL=/tmp/org.apache.karaf.shell.cfg.tpl
OPENNMS_KARAF_CFG=${OPENNMS_HOME}/etc/org.apache.karaf.shell.cfg

# Error codes
E_ILLEGAL_ARGS=126

# Help function used in error messages and -h option
usage() {
  echo ""
  echo "Docker entry script for OpenNMS service container"
  echo ""
  echo "Overlay Config file:"
  echo "If you want to overwrite the default configuration with your custom config, you can use an overlay config"
  echo "folder in which needs to be mounted to ${OPENNMS_OVERLAY_CFG}."
  echo "Every file in this folder is overwriting the default configuration file in ${OPENNMS_HOME}/etc."
  echo ""
  echo "-f: Start OpenNMS in foreground with an existing configuration."
  echo "-h: Show this help."
  echo "-i: Initialize Java environment, database and pristine OpenNMS configuration files and do *NOT* start OpenNMS."
  echo "    The database and config file initialization is skipped when a configured file exist."
  echo "-s: Initialize environment like -i and start OpenNMS in foreground."
  echo ""
}

doInitOrUpgrade() {
  if [ -f ${OPENNMS_UPGRADE_GUARD} ]; then
    echo "Enforce config and database update."
    rm -rf ${OPENNMS_CONFIGURED_GUARD}
    ${OPENNMS_HOME}/bin/runjava -s
    ${OPENNMS_HOME}/bin/install -dis
    rm -rf ${OPENNMS_UPGRADE_GUARD}
    rm -rf ${OPENNMS_OVERLAY_CFG}/do-upgrade
  fi
}

# Initialize database and configure Karaf
initConfig() {
  if [ ! -d ${OPENNMS_HOME} ]; then
    echo "OpenNMS home directory doesn't exist in ${OPENNMS_HOME}."
    exit ${E_ILLEGAL_ARGS}
  fi

  if [ ! "$(ls --ignore .git --ignore .gitignore --ignore ${OPENNMS_DATASOURCES_CFG} --ignore ${OPENNMS_KARAF_CFG} -A ${OPENNMS_HOME}/etc)"  ]; then
    echo "No existing configuration in ${OPENNMS_HOME}/etc found. Initialize from etc-pristine."
    cp -r ${OPENNMS_HOME}/share/etc-pristine/* ${OPENNMS_HOME}/etc/
  fi

  if [ ! -f ${OPENNMS_CONFIGURED_GUARD} ]; then
    echo "Initialize database and Karaf configuration and do install or upgrade the database schema."
    envsubst < ${OPENNMS_DATASOURCES_TPL} > ${OPENNMS_DATASOURCES_CFG}
    envsubst < ${OPENNMS_KARAF_TPL} > ${OPENNMS_KARAF_CFG}
    ${OPENNMS_HOME}/bin/runjava -s
    ${OPENNMS_HOME}/bin/install -dis
  fi
}

applyOverlayConfig() {
  if [ "$(ls -A ${OPENNMS_OVERLAY_CFG})" ]; then
    echo "Apply custom configuration from ${OPENNMS_OVERLAY_CFG}."
    cp -r ${OPENNMS_OVERLAY_CFG}/* ${OPENNMS_HOME}/etc
  else
    echo "No custom config found in ${OPENNMS_OVERLAY_CFG}. Use default configuration."
  fi
}

# Start opennms in foreground
start() {
  cd ${OPENNMS_HOME}
  local OPENNMS_JAVA_OPTS="-Djava.endorsed.dirs=/opt/opennms/lib/endorsed \
  -Dopennms.home=/opt/opennms \
  -Dcom.sun.management.jmxremote.authenticate=true \
  -Dcom.sun.management.jmxremote.login.config=opennms \
  -Dcom.sun.management.jmxremote.access.file=/opt/opennms/etc/jmxremote.access \
  -DisThreadContextMapInheritable=true \
  -Dgroovy.use.classvalue=true \
  -Djava.io.tmpdir=/opt/opennms/data/tmp \
  -XX:+HeapDumpOnOutOfMemoryError"
  exec java ${OPENNMS_JAVA_OPTS} ${JAVA_OPTS} -jar /opt/opennms/lib/opennms_bootstrap.jar start
}

# Evaluate arguments for build script.
if [[ "${#}" == 0 ]]; then
  usage
  exit ${E_ILLEGAL_ARGS}
fi

# Evaluate arguments for build script.
while getopts fhis flag; do
  case ${flag} in
    f)
      applyOverlayConfig
      start
      exit
      ;;
    h)
      usage
      exit
      ;;
    i)
      initConfig
      applyOverlayConfig
      doInitOrUpgrade
      exit
      ;;
    s)
      initConfig
      applyOverlayConfig
      doInitOrUpgrade
      start
      exit
      ;;
    *)
      usage
      exit ${E_ILLEGAL_ARGS}
      ;;
  esac
done

# Strip of all remaining arguments
shift $((OPTIND - 1));

# Check if there are remaining arguments
if [[ "${#}" > 0 ]]; then
  echo "Error: To many arguments: ${*}."
  usage
  exit ${E_ILLEGAL_ARGS}
fi
