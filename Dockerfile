FROM opennms/maven:latest

LABEL maintainer "Ronny Trommer <ronny@opennms.org>"

ARG NSIS_RPM_URL="http://yum.opennms.org/stable/rhel7/nsis/mingw32-nsis-2.50-1.el7.centos.x86_64.rpm"

ENV PATH /opt/rh/rh-ruby24/root/usr/bin:/opt/rh/rh-ruby22/root/usr/local/bin:${PATH}
ENV LIBRARY_PATH /opt/rh/v8314/root/usr/lib64
ENV LD_LIBRARY_PATH /opt/rh/v8314/root/usr/lib64:/opt/rh/nodejs010/root/usr/lib64:/opt/rh/rh-ruby24/root/usr/lib64

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
                   rh-ruby24 \
                   rh-ruby24-ruby-devel \
                   rh-ruby24-rubygem-rake \
                   v8314 \
                   rh-ruby24-rubygem-bundler \
                   scl-utils \
                   ${NSIS_RPM_URL} \
                   rpm-build \
                   redhat-rpm-config && \
    yum clean all && \
    rm -rf /var/cache/yum

RUN scl enable rh-ruby24 -- gem install listen && \
    scl enable rh-ruby24 -- gem install ascii_binder && \
    scl enable rh-ruby24 -- gem install sass

RUN useradd -m circleci

USER circleci
