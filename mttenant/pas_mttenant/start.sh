#!/bin/bash
logfile=/usr/wrk/oepas1/logs/oepas1.agent.log
touch $logfile
/usr/wrk/oepas1/bin/tcman.sh start -v
tail -f $logfile
