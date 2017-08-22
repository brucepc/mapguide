#!/bin/bash
# Note: I've written this using sh so it works in the busybox container too
set -e

export PATH=${MG_PATH}/server/bin:$PATH
export MENTOR_DICTIONARY_PATH=${MG_PATH}/share/gis/coordsys
export LD_LIBRARY_PATH=/usr/local/fdo-${FDOVER}/lib:"$LD_LIBRARY_PATH"
export NLSPATH=/usr/local/fdo-${FDOVER}/nls/%N:"$NLSPATH"
mkdir -p /var/lock/mgserver

NO_APACHE=0
NO_TOMCAT=0

start_apache(){
  echo "Starting Apache..."
  cd ${MG_PATH}/webserverextensions/apache2/bin
  ./apachectl start
}

start_tomcat(){
  echo "Starting tomcat..."
  cd ${MG_PATH}/webserverextensions/tomcat/bin
  ./startup.sh
}

start_mg(){
  echo "Starting mgserver..."
  cd ${MG_PATH}/server/bin
  ./mapguidectl start
}

stop_all(){
  if [ $NO_APACHE -eq 0 ]; then
    echo "Stopping Apache server..."
    cd ${MG_PATH}/webserverextensions/apache2/bin
    ./apachectl stop
  fi

  if [ $NO_TOMCAT -eq 0 ]; then
    echo "Stopping Tomcat server..."
    cd ${MG_PATH}/webserverextensions/tomcat/bin
    ./shutdown.sh
  fi

  echo "Stopping Mapguide server..."
  cd ${MG_PATH}/server/bin
  ./mapguidectl stop
}

print_help(){
  echo "Help: "
  echo  ""
  echo "--only-mapguide\t\tstart only mapguide server"
  echo "--no-apache\t\tdon't start apache server"
  echo "--no-tomcat\t\tdon't start tomcat server"
  echo "--help show this help"
}

while test $# -gt 0; do
  case "$1" in
    -h|--help)
     print_help
      exit 0
    ;;
    --only-mapguide)
      shift
      NO_APACHE=1
      NO_TOMCAT=1
      exit 0
    ;;
    --no-apache)
      shift
      NO_APACHE=1
    ;;
    --no-tomcat)
      shift
      NO_TOMCAT=1
    ;;
    *)
      echo "Invalid option please use as bellow"
      echo "$package --help"
      exit 2
      break
    ;;
  esac
done

trap stop_all SIGINT SIGTERM

if [ $NO_APACHE -eq 0 ]; then
  start_apache
fi

if [ $NO_TOMCAT -eq 0 ]; then
  start_tomcat
fi

start_mg

while true; do
  sleep 300
done
