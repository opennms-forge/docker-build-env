#!/bin/bash -e
# =====================================================================
# Build script to compile and assemble OpenNMS in Docker environment.
#
# Source: https://github.com/opennms/build-container
# Author: ronny@opennms.org
#
# =====================================================================

cd ${OPENNMS_SRC}
mvn -Dbuild.profile=default -Droot.dir=${OPENNMS_SRC} -Dopennms.home=${OPENNMS_HOME} -Dmaven.metadata.legacy=true -Djava.awt.headless=true ${@} install

cd ${OPENNMS_SRC}/core/build
mvn -Dbuild.profile=dir -Droot.dir=${OPENNMS_SRC} -Dopennms.home=${OPENNMS_HOME} -Dmaven.metadata.legacy=true -Djava.awt.headless=true ${@} install

cd ${OPENNMS_SRC}/container/features
mvn -Dbuild.profile=dir -Droot.dir=${OPENNMS_SRC} -Dopennms.home=${OPENNMS_HOME} -Dmaven.metadata.legacy=true -Djava.awt.headless=true ${@} install

cd ${OPENNMS_SRC}/opennms-full-assembly
mvn -Dbuild.profile=fulldir -Droot.dir=${OPENNMS_SRC} -Dopennms.home=${OPENNMS_HOME} -Dmaven.metadata.legacy=true -Djava.awt.headless=true ${@} install

cd ${OPENNMS_SRC}/target
ln -s opennms-**/ /opt/opennms
