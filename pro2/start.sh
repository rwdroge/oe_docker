#!/bin/bash
logfile=/install/pro2/Pro2Web/logs/Pro2Web.agent.log
touch $logfile
/install/pro2/Pro2Web/bin/tcman.sh start -v
/install/pro2/bprepl/Scripts/jobrunner.sh
tail -f $logfile

