#!/bin/bash


rm -rf /app/tmp/srcdb*

if [[ -f /app/db/${DBNAME}.lk ]]; then
    singleuser=false
    online=true
else
    singleuser=true
    online=false
fi

$DLC/ant/bin/ant -f /app/scripts/database-tasks.xml -lib $DLC/pct/PCT.jar -DDBNAME=${DBNAME} -Dsingleuser=${singleuser} -Donline=${online} createdelta  

if [[ -f /app/schema/${DBNAME}.delta.df ]]; then
    cat /app/schema/${DBNAME}.delta.df

    if [[ "${DISPLAYONLY}" != "true" ]]; then
        $DLC/ant/bin/ant -f /app/scripts/database-tasks.xml -lib $DLC/pct/PCT.jar -DDBNAME=${DBNAME} -Dsingleuser=${singleuser} -Donline=${online} applydelta
        /app/scripts/create-hash.sh /app/schema/${DBNAME}.df > ${DBNAME}.schema.hash
    fi
else
    echo /app/schema/${DBNAME}.delta.df not found.
fi