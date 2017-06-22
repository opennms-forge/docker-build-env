# Docker build environment

This container can be used to compile and assemble OpenNMS from source code.
Primary distribution for OpenNMS RHEL or CentOS.
The environment is built on official vanilla CentOS 7 and uses Docker multi-stage build which requires an edge release of Docker.

The versions in Ubuntu or CentOS are too old so please use the [Docker install instructions](https://docs.docker.com/engine/installation).
As a result it will give you a container image which is ready to run.

It is recommended to use [Docker Compose](https://docs.docker.com/compose/install/) to describe your service stack.
The minimal service stack needs PostgreSQL and your OpenNMS container image.

## Build Stages

Compiling and installing is realized within the following stages:

* Stage 1: Install current OpenJDK 8 development kit
* Stage 2: Install current Apache Maven
* Stage 3: Install build environment dependencies for JICMP, JICMP6, JRRD2 and OpenNMS
* Stage 4: Compile JICMP
* Stage 5: Compile JICMP6
* Stage 6: Compile JRRD2
* Stage 7: Compile and assemble OpenNMS
* Stage 8: Build runnable containers with installed artifacts

## Advanced Hints

To remove as many dependencies as possible and to make migration to other base images easier, the installation uses a distribution neutral mechanism by just extracting the assembled OpenNMS to `/opt/opennms`.
In the build process, dependencies against Perl and other Bash scripts where removed and native Maven commands are executed which makes the whole build process more transparent.

## Requirements

* Docker 17.05.0-ce Edge version
* Docker Compose 1.8+
* Internet connectivity

## Usage

Compile and assemble OpenNMS, by default the official OpenNMS GitHub repository is used and the _develop_ branch will be checked out.

```
docker build -t myopennms https://github.com/opennms-forge/docker-build-env.git
```

In the GitHub repository is a sample `docker-compose.yml` file which can be used to build and run the service stack.

HINT: Verify the image name you have specified with `-t myopennms` is used in `docker-compose.yml` file.

Run OpenNMS
```
docker-compose up -d
```

## Modify build using build arguments

The following build arguments can be used with (`--build-arg myarg=value`) to overwrite the default behavior.

Example to compile a specific OpenNMS branch named _jira/NMS-9328_ by setting build arguments and set the container image name to the issue number:

```
docker build \
       -t nms-9328 \
       https://github.com/opennms-forge/docker-build-env.git \
       --build-arg OPENNMS_GIT_BRANCH_REF=jira/NMS-9328
```


| Argument                 | Default                              | Description                                                     |
|:-------------------------|:-------------------------------------|:----------------------------------------------------------------|
| _JAVA_VERSION_           | `1.8.0`                              | Major OpenJDK version                                           | 
| _JAVA_VERSION_DETAIL_    | `1.8.0.131`                          | Version number used in OpenJDK RPM package                      |
| _MAVEN_VERSION_          | `3.5.0`                              | Version number for Apache Maven                                 |
| _MAVEN_URL_              | `http://ftp.halifax.rwth-aachen.de`  | Server URL for Apache Maven package                             |
| _MAVEN_PKG_              | `${MAVEN_URL}/apache/maven/maven-3/${MAVEN_VERSION}/binaries/apache-maven-${MAVEN_VERSION}-bin.tar.gz` | Maven binary package URL |
| _MAVEN_PROXY_URL_        | _not set_ uses the OpenNMS provided Maven repo                                                         | Alternative Maven proxy server, e.g. with JFrog `http://<jfrog-ip>:8081/artifactory/remote-repos/` |
| _NSIS_RPM_URL_           | `http://yum.opennms.org/branches/develop/rhel7/nsis/mingw32-nsis-2.50-1.el7.centos.x86_64.rpm`         | Make NSIS Package URL    |
| _JICMP_GIT_REPO_URL_     | `https://github.com/opennms/jicmp`   | Git repository URL for JICMP                                    |
| _JICMP_GIT_BRANCH_REF_   | `jicmp-2.0.4-1`                      | Tag or branch for JICMP                                         |
| _JICMP_SRC_              | `/usr/src/jicmp`                     | Source directory for JICMP                                      |
| _JICMP6_GIT_REPO_URL_    | `https://github.com/opennms/jicmp6`  | Git repository URL for JICMP6                                   |
| _JICMP6_GIT_BRANCH_REF_  | `jicmp6-2.0.3-1`                     | Tag or branch for JICMP6                                        |
| _JICMP6_SRC_             | `/usr/src/jicmp6`                    | Source directory for JICMP6                                     |
| _JRRD2_GIT_REPO_URL_     | `https://github.com/opennms/jrrd2`   | Git repository URL for JRRD2                                    |
| _JRRD2_GIT_BRANCH_REF_   | `2.0.4`                              | Tag or branch for JRRD2                                         |
| _JRRD2_SRC_              | `/usr/src/jrrd2`                     | Source directory for JRRD2                                      |
| _OPENNMS_SRC_            | `/usr/src/opennms`                   | Source directory for OpenNMS                                    |
| _OPENNMS_HOME_           | `/opt/opennms`                       | Target directory for OpenNMS                                    |
| _MAVEN_OPTS_             | `"-XX:MaxHeapSize=2G -XX:ReservedCodeCacheSize=512m -XX:+TieredCompilation -XX:TieredStopAtLevel=1 -XX:-UseGCOverheadLimit -XX:+UseParallelGC -XX:+UseParallelOldGC"`                                  | Default Maven options to compile and assemble OpenNMS from source                                      |
| _OPENNMS_GIT_REPO_URL_   | `https://github.com/opennms/opennms` | Git repository URL for OpenNMS
| _OPENNMS_GIT_BRANCH_REF_ | `develop`                            | Tag or branch for OpenNMS
| _BUILD_OPTIONS_          | `"-q -DskipTests"`                   | Custom Maven options for compile and assembly                   |

## Author

[Ronny Trommer](mailto:ronny@opennms.org)
