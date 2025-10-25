#!/bin/bash

# This script first tries to establish the database name (DBNAME). Therefor it searches for a .db file.
# if not it search for a .df file. If none of these are found, the script exits.
# 
# If a database is not present:
#     based on the .df (& .st) it builds an empty db based on those definitions.
#     The .df is hashed and the hash is written in /app/db/<dbname>.schema.hash
# 
# If database exists, it is checked in /app/schema if there's a <dbname>.df present. If so, this
# .df file is hashed and that hash is compared to the hash in <dbname>.schema.hash
#
# If these hashes are not the same, an empty database is created with the schema in /app/schema and
# a delta.df is created and applied. A new /app/db/<dbname>.schema.hash is generated.
#

function startServer() {
    ${DLC}/bin/proserve /app/db/${DBNAME} -pf /app/db/db.pf -pf /app/tmp/dbports.pf
    echo "database started..."
    ps -ef
}

function stopServer() {
    echo "attempt to bring down ${DBNAME} gracefully"
    if [ -f "/app/db/${DBNAME}.lk" ]; then
        echo ".lk found; execute proshut"
        ${DLC}/bin/proshut /app/db/${DBNAME} -by
        echo "database stopped..."
    fi
    exit 0
}

function getDbname() {
    dbname=`find . -type f -name "*.db"`
    if [[ -z $dbname ]]; then 
        dbname=`find . -type f -name "*.df"`
    fi

    if [[ -z $dbname ]]; then 
        exit 1
    fi

    dbname=`basename "$dbname"`
    dbname=`echo "$dbname" | cut -d'.' -f1`

    echo $dbname
}

function initDb() {

    if [[ -f ${DBNAME}.lk ]] ; then

        if [[ "${DEL_LK_FILE}" == "true" ]]; then
            rm -f ${DBNAME}.lk
        else
            echo ${DBNAME}.lk found, exiting...
            exit 1
        fi
    fi

    if [[ ! -f ${DBNAME}.db ]]; then 

        if [[ ! -f ${DBNAME}.df ]] && [[ -f ${DEFDIR}/${DBNAME}.df ]] ; then 
            cp ${DEFDIR}/${DBNAME}.df .
        fi

        if [[ ! -f ${DBNAME}.st ]] && [[ -f ${DEFDIR}/${DBNAME}.st ]] ; then 
            cp ${DEFDIR}/${DBNAME}.st .
        fi

        if [[ -f ${DBNAME}.df ]] && [[ -f ${DBNAME}.st ]] ; then 
            echo "db not found, create one" 

            if grep -Fq "MULTITENANT yes" ${DBNAME}.df ; then
                echo "MULTITENANT yes found in ${DBNAME}.df"
                echo "creating multi-tenant db"
                MULTITENANT=true
            else
                echo "creating single-tenant db"
                MULTITENANT=false
            fi

            $DLC/ant/bin/ant -f /app/scripts/database-tasks.xml -lib $DLC/pct/PCT.jar -DDBNAME=${DBNAME} -DMULTITENANT=${MULTITENANT} createdb
            $HASH ${DBNAME}.df > ${DBNAME}.schema.hash
        else
            echo database \"${DBNAME}\" not found, no df for building db found
            exit 1
        fi
    else
        # db exists, check for updates
        echo DB ${DBNAME} exist, checking df diffs
        if [[ -f ${DEFDIR}/${DBNAME}.df ]]; then 
        
            newdf=$($HASH ${DEFDIR}/${DBNAME}.df)
            curdf=$(cat ${DBNAME}.schema.hash)
            echo new sha\: ${newdf}
            echo cur sha\: ${curdf}

            if [[ ${newdf} != ${curdf} ]]; then 
                echo db needs updating...
                # this part needs to go to the update-schema.sh script 
                /app/scripts/update-schema.sh ${DBNAME}
            fi
        else
            echo ${DEFDIR}/${DBNAME}.df not found
        fi

    fi

    # optional .d data load
    if [[ -f /app/data/tables.txt ]]; then
        TABLES=$(cat /app/data/tables.txt)
        echo "loading data"
        echo "tables: ${TABLES}"
        $DLC/ant/bin/ant -f /app/scripts/database-tasks.xml -lib $DLC/pct/PCT.jar -DDBNAME=${DBNAME} -Dtables="${TABLES}" loadData
    fi

    # if no db.pf found, copy default
    if [[ ! -f db.pf ]]; then
        cp /app/scripts/db.pf /app/db/
    fi

    touch /app/tmp/dbports.pf
    if [[ -n "${SERVERPORT}" ]]; then

      if [[ -z "${MINPORT}" ]]; then
        MINPORT=$((SERVERPORT+1))
      fi

      if [[ -z "${MAXPORT}" ]]; then
        MAXPORT=$((SERVERPORT+9))
      fi

      echo "using ports:"
      echo "-S ${SERVERPORT} -minport ${MINPORT} -maxport ${MAXPORT} " > /app/tmp/dbports.pf
        
      cat /app/tmp/dbports.pf
    fi
}

function initLicense() {
    echo "checking for license"
    if [[ -f /app/license/progress.cfg ]]; then
        echo "license found in /app/license, copying to /usr/dlc/progress.cfg"
        cp /app/license/progress.cfg $DLC/progress.cfg
    fi
    if [[ ! -f $DLC/progress.cfg ]]; then
        echo "No license (/usr/dlc/progress.cfg) found, exiting..."
        exit 1
    fi  
    echo "license found, proceeding"
}

function displayInfo() {
    echo "  DBNAME: ${DBNAME}"
    echo "  DEL_LK_FILE: ${DEL_LK_FILE}"
    echo "  DEFDIR: ${DEFDIR}"
    echo "  DLC: ${DLC}"
    echo "  PATH: ${PATH}"
}

HASH=/app/scripts/create-hash.sh
DEFDIR=/app/schema

if [[ ${DBNAME} == "" ]]; then 
    DBNAME=$(getDbname)
fi

displayInfo
initLicense
initDb

trap "stopServer" SIGINT SIGTERM

startServer

pidfile=/app/db/${DBNAME}.lk

sleep 2

# make sure the logs are visible
tail -f /app/db/${DBNAME}.lg &

# Loop while the pidfile and the process exist
# while [ -f $pidfile ] && [ ps -p $PID >/dev/null ] ; do
while [ -f $pidfile ] ; do
    sleep 0.5
done

exit 1