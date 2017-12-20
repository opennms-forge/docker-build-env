FROM opennms/build-env:refactor

LABEL maintainer "Markus von Rüden <mvr@opennms.com"

# Override user from build-env
USER root

# Install required dependencies for test-environment
RUN yum -y --setopt=tsflags=nodocs update && \
    yum -y install R && \
    yum clean all && \
    rm -rf /var/cache/yum

# Install JICMP
RUN rpm -i http://yum.opennms.org/stable/rhel7/jicmp/jicmp-2.0.3-1.el7.centos.x86_64.rpm && \
    rpm -i http://yum.opennms.org/stable/rhel7/jicmp6/jicmp6-2.0.2-1.el7.centos.x86_64.rpm

# CIRCLECI expects a user named circleci.
# We may have to run the image as root, but we stay conform anyways
USER circleci