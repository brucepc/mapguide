#!/bin/bash
# Note: I've written this using sh so it works in the busybox container too
set -e

# start service in background here
echo "Starting Apache"
cd /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/apache2/bin
./apachectl start

echo "Starting tomcat"
cd /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/webserverextensions/tomcat/bin
./startup.sh

echo "Starting mgserver"
cd /usr/local/mapguideopensource-${MGVER_MAJOR_MINOR_REV}/server/bin
./mgserver.sh run

