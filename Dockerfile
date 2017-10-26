FROM opennms/maven:latest

LABEL maintainer "Ronny Trommer <ronny@opennms.org>"

ARG NSIS_RPM_URL="http://yum.opennms.org/stable/rhel7/nsis/mingw32-nsis-2.50-1.el7.centos.x86_64.rpm"
ARG ASCIIBINDER_SEARCH_PLUGIN_REPO_URL="git+https://github.com/opennms-forge/ascii_binder_search_plugin"

ENV PATH /opt/rh/rh-ruby22/root/usr/bin:${PATH}
ENV LIBRARY_PATH /opt/rh/v8314/root/usr/lib64
ENV LD_LIBRARY_PATH /opt/rh/v8314/root/usr/lib64:/opt/rh/nodejs010/root/usr/lib64:/opt/rh/rh-ruby22/root/usr/lib64

RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install epel-release \
                   centos-release-scl && \
    yum -y install python34 \
                   python34-pip \
                   git \
                   which \
                   expect \
                   make \
                   cmake \
                   gcc-c++ \
                   rrdtool-devel \
                   automake \
                   libtool \
                   rh-ruby22 \
                   rh-ruby22-ruby-devel \
                   rh-ruby22-rubygem-rake \
                   v8314 \
                   rh-ruby22-rubygem-bundler \
                   scl-utils \
                   ${NSIS_RPM_URL} \
                   rpm-build \
                   redhat-rpm-config && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN scl enable rh-ruby22 -- gem install listen -v 3.0.8 && \
    scl enable rh-ruby22 -- gem install ascii_binder && \
    pip3 install ${ASCIIBINDER_SEARCH_PLUGIN_REPO_URL}

RUN useradd -m circleci

USER circleci
