#!/bin/bash

SCRIPTPATH=$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")
# validate OpenEdge variables and java
source ${SCRIPTPATH}/validate.sh

# Validations related to starting a DB
if [ -z ${DB_BROKER_PORT} ]; then echo "Environment variable DB_BROKER_PORT is not set"; exit 1; fi
if [ -z ${DB_MINPORT} ]; then echo "Environment variable DB_MINPORT is not set"; exit 1; fi
if [ -z ${DB_MAXPORT} ]; then echo "Environment variable DB_MAXPORT is not set"; exit 1; fi

# read common properties required for create and start db
source ${SCRIPTPATH}/db.properties

# cd to directory where created db is supposed to be
cd ${DB_DIR}

# create db params string
DB_PARAMS="-S ${DB_BROKER_PORT} -minport ${DB_MINPORT} -maxport ${DB_MAXPORT}"
# add param file to the db params, if it exists
if [ -f ${STARTUP_PF} ]; then
  DB_PARAMS="${DB_PARAMS}"
fi
echo "Database startup parameters: '${DB_PARAMS}'"

echo "Starting the database '${DB_NAME}'"
proserve ${DB_NAME} ${DB_PARAMS}
proserve ${DB_NAME} -pf ${STARTUP_PF}

echo -e "
###############################   Important Note   ###############################
Ports and port range mentioned below should be exposed outside the container on exactly same ports:
\t DB_BROKER_PORT:${DB_BROKER_PORT}
\t DB_MINPORT-DB_MAXPORT:${DB_MINPORT}-${DB_MAXPORT}
Explaination:\tClient connections get assigned to one of the ports in range inside container 
\t\tand then client tries to communicate on same assigned port from outside the container
##################################################################################"

# Extract the pid of database server process
# Retry 10 times with a delay of 1 second
RETRIES=0
while pid=`pgrep -x _mprosrv`; status=$?; [ $status -ne 0 ]
do
  if [ "${RETRIES}" -gt 10 ]
  then
    break
  fi
  sleep 1
  RETRIES=$((RETRIES+1))
done

# Exit with exit code if database server did not start
if [ $status -ne 0 ]
then
  { echo "ERROR: Failed to start database server!. Exiting. \($status\)"; exit $status; }
fi

shutdown_gracefully() {
  echo "Shutdown the database '${DB_NAME}'"
  cd ${DB_DIR}
  proshut -by ${DB_NAME}

  # sleep for sometime, to get the logs
  sleep 10
  
  # exit with code 0 as it's a graceful shutdown
  exit 0
}

# trap SIGTERM and call the handler to cleanup processes
trap 'shutdown_gracefully' SIGTERM SIGINT

# start fluent-bit process
/usr/local/bin/fluent-bit -c /etc/fluent-bit/fluent-bit.conf &

# start oecc agent process
/usr/oecc_agent/oeccagent start &
# keep the container running
tail -f /dev/null &
# This is required such that a trap on main process is triggered
wait ${!}