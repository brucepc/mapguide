#!/bin/bash
# Note: I've written this using sh so it works in the busybox container too
set -e

export PATH=${MG_PATH}/server/bin:$PATH
export MENTOR_DICTIONARY_PATH=${MG_PATH}/share/gis/coordsys
export LD_LIBRARY_PATH=/usr/local/fdo-${FDOVER}/lib:"$LD_LIBRARY_PATH"
export NLSPATH=/usr/local/fdo-${FDOVER}/nls/%N:"$NLSPATH"
mkdir -p /var/lock/mgserver
ln -sf ${MG_PATH}/server/bin/mapguidectl /usr/local/bin/mapguidectl

SLEEPTIME=1
NO_APACHE=0
NO_TOMCAT=0
MG_PIDFILE=/var/run/mapguide.pid

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
  ${MG_PATH}/server/bin/mapguidectl start
  $MG_PATH/server/bin/mapguidectl status | perl -pe 's/\D//g' | tee $MG_PIDFILE
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
  echo "--crash-time\t1\tSeconds to sleep before restart, after crash"
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
    --crash-time)
      shift
      if ! [ $1 =~'^[0-9]+$' ];then
        echo "error: the --crash-time must be any number">&2;
        exit 1;
      fi
      SLEEPTIME=$1
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

start_mg

if [ $NO_APACHE -eq 0 ]; then
  start_apache
fi

if [ $NO_TOMCAT -eq 0 ]; then
  start_tomcat
fi

while true; do
  sleep $SLEEPTIME
  pid=$(cat ${MG_PIDFILE})
  if [ ! -e /proc/$pid -a /proc/$pid/exe ]; then
    echo "Mapguide foi parado inesperadamente e sera reiniciando..."
    start_mg
  fi
done
