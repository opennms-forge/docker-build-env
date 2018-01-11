FROM opennms/maven:latest

LABEL maintainer "Ronny Trommer <ronny@opennms.org>"

ARG NSIS_RPM_URL="http://yum.opennms.org/stable/rhel7/nsis/mingw32-nsis-2.50-1.el7.centos.x86_64.rpm"

ARG OPENNMS_SRC_ROOT=/usr/src/opennms

ARG JICMP_GIT_REPO_URL="https://github.com/opennms/jicmp"
ARG JICMP_GIT_BRANCH_REF="jicmp-2.0.4-1"
ARG JICMP_SRC=/usr/src/jicmp

ARG JICMP6_GIT_REPO_URL="https://github.com/opennms/jicmp6"
ARG JICMP6_GIT_BRANCH_REF="jicmp6-2.0.3-1"
ARG JICMP6_SRC=/usr/src/jicmp6

ARG JRRD2_GIT_REPO_URL="https://github.com/opennms/jrrd2"
ARG JRRD2_GIT_BRANCH_REF="2.0.4"
ARG JRRD2_SRC=/usr/src/jrrd2

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install gettext \
                   git \
                   which \
                   expect \
                   make \
                   cmake \
                   gcc-c++ \
                   rrdtool-devel \
                   automake \
                   libtool \
                   rpm-build \
                   redhat-rpm-config \
                   ${NSIS_RPM_URL} && \
    yum clean all && \
    rm -rf /var/cache/yum && \
    mkdir ${OPENNMS_SRC_ROOT}

RUN git clone ${JICMP_GIT_REPO_URL} ${JICMP_SRC} && \
    cd ${JICMP_SRC} && \
    git checkout ${JICMP_GIT_BRANCH_REF} && \
    git submodule update --init --recursive && \
    autoreconf -fvi && \
    ./configure && \
    make -j$(nproc) && \
    cp jicmp.jar /usr/share/java/jicmp.jar && \
    cp libjicmp.la /usr/lib64/libjicmp.la && \
    cp .libs/libjicmp.so /usr/lib64/libjicmp.so && \
    rm -rf ${JICMP_SRC}

LABEL org.opennms.jicmp.git.repo.url="${JICMP_GIT_REPO_URL}" \
      org.opennms.jicmp.git.repo.branch.ref="${JICMP_GIT_BRANCH_REF}" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

RUN git clone ${JICMP6_GIT_REPO_URL} ${JICMP6_SRC} && \
    cd ${JICMP6_SRC} && \
    git checkout ${JICMP6_GIT_BRANCH_REF} && \
    git submodule update --init --recursive && \
    autoreconf -fvi && \
    ./configure && \
    make -j$(nproc) && \
    cp jicmp6.jar /usr/share/java/jicmp6.jar && \
    cp .libs/libjicmp6.la /usr/lib64/libjicmp6.la && \
    cp .libs/libjicmp6.so /usr/lib64/libjicmp6.so && \
    rm -rf ${JICMP6_SRC}

LABEL org.opennms.jicmp6.git.repo.url="${JICMP6_GIT_REPO_URL}" \
      org.opennms.jicmp6.git.repo.branch.ref="${JICMP6_GIT_BRANCH_REF}" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

RUN git clone ${JRRD2_GIT_REPO_URL} ${JRRD2_SRC} && \
    cd ${JRRD2_SRC} && \
    git checkout ${JRRD2_GIT_BRANCH_REF} && \
    mkdir build && \
    cd java && \
    mvn clean compile && \
    cd ../build && \
    cmake ../jni/ && \
    make -j$(nproc) && \
    cd ../java && \
    mvn package && \
    cd .. && \
    cp java/target/jrrd2-api-*.jar /usr/share/java/ && \
    cp dist/libjrrd2.so /usr/lib64/libjrrd2.so && \
    rm -rf ${JRRD2_SRC} ~/.m2

LABEL org.opennms.jrrd2.git.repo.url="${JRRD2_GIT_REPO_URL}" \
      org.opennms.jrrd2.git.repo.branch.ref="${JRRD2_GIT_BRANCH_REF}" \
      license="AGPLv3" \
      vendor="OpenNMS Community"

COPY ./assets/opennms-datasources.xml.tpl /tmp
COPY ./assets/org.apache.karaf.shell.cfg.tpl /tmp
COPY ./docker-entrypoint.sh /

RUN useradd -m circleci

WORKDIR ${OPENNMS_SRC_ROOT}
