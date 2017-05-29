#
# Stage 1: Build image with OpenJDK development kit
#
FROM centos:7 as java-dev

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG JAVA_VERSION=1.8.0
ARG JAVA_VERSION_DETAIL=1.8.0.131
ENV JAVA_HOME /usr/lib/jvm/java

LABEL vendor="OpenJDK" \
      org.opennms.java.version="openjdk-${JAVA_VERSION}-{JAVA_VERSION_DETAIL}"

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install java-${JAVA_VERSION}-openjdk-devel-${JAVA_VERSION_DETAIL} && \
    yum -y clean all

#
# Stage 2: Build image with Apache Maven
#
FROM java-dev as maven

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG MAVEN_VERSION="3.5.0"
ARG MAVEN_URL="http://ftp.halifax.rwth-aachen.de"
ARG MAVEN_PKG="${MAVEN_URL}/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz"
ENV MAVEN_HOME /opt/apache-maven-${MAVEN_VERSION}
ENV PATH /usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:${MAVEN_HOME}/bin

LABEL org.opennms.maven.version="${MAVEN_VERSION}"

WORKDIR /opt

RUN curl ${MAVEN_PKG} | tar xz

#
# Stage 3: Create build environment
#
FROM maven as build-env

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG NSIS_RPM_URL="http://yum.opennms.org/branches/develop/rhel7/nsis/mingw32-nsis-2.50-1.el7.centos.x86_64.rpm"
ARG MAVEN_PROXY_URL

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install git \
                   which \
                   expect \
                   make \
                   cmake \
                   gcc-c++ \
                   rrdtool-devel \
                   automake \
                   libtool && \
    yum install -y ${NSIS_RPM_URL} && \
    yum install -y rpm-build \
                   redhat-rpm-config && \
    yum clean all

# In case there is a MAVEN_PROXY_URL set, the settings.xml will be generated otherwise an empty settings.xml is created.
RUN mkdir -p ${HOME}/.m2 && \
    if [ -z ${MAVEN_PROXY_URL} ]; then \
      echo '<settings />' > ${HOME}/.m2/settings.xml; \
    else \
      echo "<settings><mirrors><mirror><id>maven-proxy</id><url>${MAVEN_PROXY_URL}</url><mirrorOf>*</mirrorOf></mirror></mirrors></settings>" > ${HOME}/.m2/settings.xml; \
    fi

#
# Stage 4: Compile JICMP
#
FROM build-env as jicmp-build

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG JICMP_GIT_REPO_URL="https://github.com/opennms/jicmp"
ARG JICMP_GIT_BRANCH_REF="jicmp-2.0.4-1"
ARG JICMP_SRC=/usr/src/jicmp

LABEL org.opennms.jicmp.git.repo.url="${JICMP_GIT_REPO_URL}" \
      org.opennms.jicmp.git.repo.branch.ref="${JICMP_GIT_BRANCH_REF}" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

RUN git clone ${JICMP_GIT_REPO_URL} ${JICMP_SRC} && \
    cd ${JICMP_SRC} && \
    git checkout ${JICMP_GIT_BRANCH_REF} && \
    git describe --all > git.describe && \
    git submodule update --init --recursive && \
    autoreconf -fvi && \
    ./configure && \
    make

#
# Stage 5: Compile JICMP6
#
FROM build-env as jicmp6-build

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG JICMP6_GIT_REPO_URL="https://github.com/opennms/jicmp6"
ARG JICMP6_GIT_BRANCH_REF="jicmp6-2.0.3-1"
ARG JICMP6_SRC=/usr/src/jicmp6

LABEL org.opennms.jicmp6.git.repo.url="${JICMP6_GIT_REPO_URL}" \
      org.opennms.jicmp6.git.repo.branch.ref="${JICMP6_GIT_BRANCH_REF}" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

RUN git clone ${JICMP6_GIT_REPO_URL} ${JICMP6_SRC} && \
    cd ${JICMP6_SRC} && \
    git checkout ${JICMP6_GIT_BRANCH_REF} && \
    git describe --all > git.describe && \
    git submodule update --init --recursive && \
    autoreconf -fvi && \
    ./configure && \
    make -j$(nproc)

#
# Stage 6: Compile JRRD2
#
FROM build-env as jrrd2-build

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG JRRD2_GIT_REPO_URL="https://github.com/opennms/jrrd2"
ARG JRRD2_GIT_BRANCH_REF="2.0.4"
ARG JRRD2_SRC=/usr/src/jrrd2

LABEL org.opennms.jrrd2.git.repo.url="${JRRD2_GIT_REPO_URL}" \
      org.opennms.jrrd2.git.repo.branch.ref="${JRRD2_GIT_BRANCH_REF}" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

RUN git clone ${JRRD2_GIT_REPO_URL} ${JRRD2_SRC} && \
    cd ${JRRD2_SRC} && \
    git checkout ${JRRD2_GIT_BRANCH_REF} && \
    git describe --all > git.describe && \
    mkdir build && \
    cd java && \
    mvn clean compile && \
    cd ../build && \
    cmake ../jni/ && \
    make -j$(nproc) && \
    cd ../java && \
    mvn package

#
# Stage 7: Compile and assembly OpenNMS
#
FROM build-env as opennms-build

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG OPENNMS_SRC=/usr/src/opennms
ARG OPENNMS_HOME=/opt/opennms
ARG MAVEN_OPTS="-XX:MaxHeapSize=2G -XX:ReservedCodeCacheSize=512m -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:-UseGCOverheadLimit -XX:+UseParallelGC -XX:+UseParallelOldGC"
ARG OPENNMS_GIT_REPO_URL="https://github.com/opennms/opennms"
ARG OPENNMS_GIT_BRANCH_REF="develop"
ARG BUILD_OPTIONS="-q -DskipTests"

LABEL org.opennms.git.repo.url="${OPENNMS_GIT_REPO_URL}" \
      org.opennms.git.repo.branch.ref="${OPENNMS_GIT_BRANCH_REF}" \
      org.opennms.home.dir="${OPENNMS_HOME}" \
      org.opennms.distribution="Horizon" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

RUN git clone ${OPENNMS_GIT_REPO_URL} ${OPENNMS_SRC} && \
    cd ${OPENNMS_SRC} && \
    git fetch --all && \
    git checkout ${OPENNMS_GIT_BRANCH_REF} && \
    git describe --all > git.describe

WORKDIR ${OPENNMS_SRC}

RUN mvn -Dbuild.profile=default \
        -Droot.dir=${OPENNMS_SRC} \
        -Dopennms.home=${OPENNMS_HOME} \
        -Dmaven.metadata.legacy=true \
        -Djava.awt.headless=true \
        ${BUILD_OPTIONS} \
        install && \
    cd ${OPENNMS_SRC}/core/build && \
    mvn -Dbuild.profile=dir \
        -Droot.dir=${OPENNMS_SRC} \
        -Dopennms.home=${OPENNMS_HOME} \
        -Dmaven.metadata.legacy=true \
        -Djava.awt.headless=true \
        ${BUILD_OPTIONS} \
        install && \
    cd ${OPENNMS_SRC}/container/features && \
    mvn -Dbuild.profile=dir \
        -Droot.dir=${OPENNMS_SRC} \
        -Dopennms.home=${OPENNMS_HOME} \
        -Dmaven.metadata.legacy=true \
        -Djava.awt.headless=true \
        ${BUILD_OPTIONS} \
        install && \
    cd ${OPENNMS_SRC}/opennms-full-assembly && \
    mvn -Dbuild.profile=default \
        -Droot.dir=${OPENNMS_SRC} \
        -Dopennms.home=${OPENNMS_HOME} \
        -Dmaven.metadata.legacy=true \
        -Djava.awt.headless=true \
        ${BUILD_OPTIONS} \
        install

#
# Step 8: Install OpenNMS and create runnable image
#
FROM java-dev as opennms

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG OPENNMS_HOME=/opt/opennms/

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install rrdtool \
           gettext && \
    yum clean all && \
    mkdir -p ${OPENNMS_HOME} 

WORKDIR /opt/opennms

# Install JRRD2 artifacts 
COPY --from=jrrd2-build /usr/src/jrrd2/java/target/jrrd2-api-*.jar /usr/share/java/
COPY --from=jrrd2-build /usr/src/jrrd2/dist/libjrrd2.so /usr/lib64/libjrrd2.so
COPY --from=jrrd2-build /usr/src/jrrd2/git.describe /usr/share/java/jrrd2.git.describe

# Install JICMP artifacts 
COPY --from=jicmp-build /usr/src/jicmp/jicmp.jar /usr/share/java/jicmp.jar
COPY --from=jicmp-build /usr/src/jicmp/libjicmp.la /usr/lib64/libjicmp.la
COPY --from=jicmp-build /usr/src/jicmp/.libs/libjicmp.so /usr/lib64/libjicmp.so
COPY --from=jicmp-build /usr/src/jicmp/git.describe /usr/share/java/jicmp.git.describe

# Install JICMP6 artifacts 
COPY --from=jicmp6-build /usr/src/jicmp6/jicmp6.jar /usr/share/java/jicmp6.jar
COPY --from=jicmp6-build /usr/src/jicmp6/.libs/libjicmp6.la /usr/lib64/libjicmp6.la
COPY --from=jicmp6-build /usr/src/jicmp6/.libs/libjicmp6.so /usr/lib64/libjicmp6.so
COPY --from=jicmp6-build /usr/src/jicmp6/git.describe /usr/share/java/jicmp6.git.describe

# Install OpenNMS artifacts
COPY --from=opennms-build /usr/src/opennms/target/opennms-*.tar.gz ${OPENNMS_HOME}
COPY --from=opennms-build /usr/src/opennms/git.describe /opt/opennms/opennms.git.describe

COPY ./assets/opennms-datasources.xml.tpl /tmp
COPY ./docker-entrypoint.sh /

RUN cd ${OPENNMS_HOME} && \
    rm -f *-source.tar.gz && \
    tar xzf opennms-*.tar.gz && \
    rm -rf *.tar.gz
RUN rm -rf /root/.m2 && \
    rm -rf /usr/src/opennms/

## Volumes for storing data outside of the container
VOLUME ["/opt/opennms/etc", "/opt/opennms/share/rrd", "/opt/opennms/share/reports"]

HEALTHCHECK --interval=10s --timeout=3s CMD curl --fail -s -I http://localhost:8980/opennms/login.jsp | grep "HTTP/1.1 200 OK" || exit 1

LABEL license="AGPLv3" \
      org.opennms.horizon.version="${OPENNMS_VERSION}" \
      vendor="OpenNMS Community" \
      name="Horizon"

ENTRYPOINT [ "/docker-entrypoint.sh" ]

CMD [ "-h" ]

##------------------------------------------------------------------------------
## EXPOSED PORTS
##------------------------------------------------------------------------------
## -- OpenNMS HTTP        8980/TCP
## -- OpenNMS JMX        18980/TCP
## -- OpenNMS KARAF RMI   1099/TCP
## -- OpenNMS KARAF SSH   8101/TCP
## -- OpenNMS MQ         61616/TCP
## -- OpenNMS Eventd      5817/TCP
## -- SNMP Trapd           162/UDP
## -- Syslog Receiver      514/UDP
EXPOSE 8980 18980 1099 8101 61616 5817 162/udp 514/udp
