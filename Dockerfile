FROM opennms/maven:3.5.0_8u131-jdk

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG OPENNMS_VERSION=develop

ENV OPENNMS_SRC /usr/src/opennms
ENV OPENNMS_HOME /opt/opennms

ENV MAVEN_OPTS "-XX:MaxHeapSize=2G -XX:ReservedCodeCacheSize=512m -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:-UseGCOverheadLimit -XX:+UseParallelGC -XX:+UseParallelOldGC"

RUN yum -y --setopt=tsflags=nodocs update && \
    rpm -Uvh http://yum.opennms.org/repofiles/opennms-repo-${OPENNMS_VERSION}-rhel7.noarch.rpm && \
    rpm --import http://yum.opennms.org/OPENNMS-GPG-KEY && \
    yum -y install git \
                   mingw32-nsis \
                   which \
                   expect \
                   iplike \
                   rrdtool \
                   jrrd2 \
                   jicmp \
                   jicmp6 && \
    yum install -y rpm-build \
                   redhat-rpm-config && \
    yum clean all

COPY ./assets/opennms-datasources.xml.tpl /tmp
COPY ./fullbuild.sh /
COPY ./opennms.sh /

WORKDIR ${OPENNMS_SRC}

VOLUME ["/root/.m2", "/usr/src/opennms"]

CMD [ "/fullbuild.sh" ]
