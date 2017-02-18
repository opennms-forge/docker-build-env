# Docker build environment

This container can be used to compile and assemble OpenNMS from source code.
It is basically a static linked Apache Maven with Oracle JDK 8 in a CentOS 7 environment.

The source code is checked out on the local machine and the container is used to compile the source code and assemble the runnable OpenNMS software.

## Requirements

* Docker 1.8+ installed
* Docker Compose 1.8+ installed
* Git to checkout the source code locally

## Usage

Checkout out the environment and the source code:
```
git clone https://github.com/opennms-forge/docker-build-env.git
cd docker-build-env
git clone https://github.com/OpenNMS/opennms.git
```

Compile and assemble OpenNMS from source
```
docker-compose up -d
```

Run OpenNMS
```
docker-compose -f opennms.yml up -d
```

For the reason you can run multiple instances of OpenNMS and PostgreSQL on the same machine the ports are assigned dynamically.
Please check with `docker ps` which ports are assigned for Postgres database and the OpenNMS WebUI.
By default OpenNMS is started with Debug port enabled using the `-t` option in the `opennms.yml` file.

## Using external maven proxy like JFrog

In case you want to use a Maven proxy, you can use something like [JFrog](https://www.jfrog.com).
There is an opennms-jfrog.yml file which provides it as a service as well.
The default repositories can be found in the assets directory.

Mount a `settings.xml` into the container in the `docker-compose.xml`
```
- ./assets/settings.xml:/root/.m2/settings.xml
```
