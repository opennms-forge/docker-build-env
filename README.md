# Docker build environment

This container can be used to compile and assemble OpenNMS from source code.
It is basically a static linked Apache Maven with Oracle JDK 8 in a CentOS 7 environment.

The source code is checked out on the local machine and the container is used to compile the source code and assemble the runnable OpenNMS software.

## Requirements

* Docker installed
* Git to checkout the source code locally

## Usage

The container runs by default the `mvn -h` command.
As `ENTRYPOINT` the binary `mvn` is set and as `CMD` the `-h` is used as default and can be overwritten.
Additionally the environment has set the _Maven_ options to

NOTE: By default OpenNMS build profiles are set to `-DskipTests=false` and `-DskipITs=true`.
      If you want to have a different behavior set the `-DskipTests` and `-DskipITs` accordingly.

Inside the container the following directories are used:

* `/opt/opennms/src`: Working directory which contains the OpenNMS source code
* `/root/.m2`: Maven repository with downloaded dependencies

Create a workspace with the source code:

    mkdir workspace
    cd workspace
    git clone https://github.com/opennms/opennms

Get the docker compile environment:

    docker pull indigo/docker-compile-opennms

If you just run the container without arguments it will just execute `mvn -h`.
The binary `mvn` can't be overriden and is used as `ENTRYPOINT` of the container.
Any other argument will override `-h` and is then executed.

Run the compiler and make sure the compiled artefacts get persisted locally:

    docker run -v ~/workspace/opennms:/opt/src/opennms indigo/docker-compile-opennms -Dbuild.profile=default -Dmaven.metadata.legacy=true -Djava.awt.headless=true -DfailIfNoTests=false install

In case you want to reuse a local Maven repository, just mount the directory in the container.
Add a second `-v` command to the `docker run` command.

Mount local Maven repository with docker run command:

    -v ~/.m2:/root/.m2

## Maven default settings

The docker environment is set to a good default which allows you to compile OpenNMS.

Default Maven options to compile OpenNMS from:

    MAVEN_OPTS="-XX:MaxHeapSize=2G \
                -XX:ReservedCodeCacheSize=512m \
                -XX:+TieredCompilation \
                -XX:TieredStopAtLevel=1 \
                -XX:-UseGCOverheadLimit \
                -XX:+UseParallelGC \
                -XX:+UseParallelOldGC`

It is possible to override the default settings by overriding the `MAVEN_OPTS` by using the `-e, --env=[]` argument of the `docker run` command.
