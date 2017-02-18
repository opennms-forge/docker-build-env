FROM indigo/centos-maven:openjdk-8u121-jdk_3.3.9

MAINTAINER Ronny Trommer <ronny@opennms.org>

ARG OPENNMS_VERSION=develop

ENV OPENNMS_SRC /usr/src/opennms
ENV OPENNMS_HOME /opt/opennms

ENV NSIS_RPM_URL http://www6.atomicorp.com/channels/atomic/centos/7/x86_64/RPMS/mingw32-nsis-2.46-12.el7.art.x86_64.rpm

ENV MAVEN_OPTS "-XX:MaxHeapSize=2G -XX:ReservedCodeCacheSize=512m -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:-UseGCOverheadLimit -XX:+UseParallelGC -XX:+UseParallelOldGC"

RUN yum -y --setopt=tsflags=nodocs update && \
    rpm -Uvh http://yum.opennms.org/repofiles/opennms-repo-${OPENNMS_VERSION}-rhel7.noarch.rpm && \
    rpm --import http://yum.opennms.org/OPENNMS-GPG-KEY && \
    yum -y install git \
                   iplike \
                   rrdtool \
                   jrrd2 \
                   jicmp \
                   jicmp6 && \
    rpm -i ${NSIS_RPM_URL} && \
    yum install -y rpm-build \
                   redhat-rpm-config && \
    yum clean all

COPY ./assets/opennms-datasources.xml.tpl /tmp
COPY ./fullbuild.sh /
COPY ./opennms.sh /

WORKDIR ${OPENNMS_SRC}

VOLUME ["/root/.m2", "/usr/src/opennms"]

CMD [ "/fullbuild.sh" ]
