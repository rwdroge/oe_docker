#!/bin/bash
logfile=/install/pro2/Pro2Web/logs/Pro2Web.agent.log
touch $logfile
/install/pro2/Pro2Web/bin/tcman.sh start -v
tail -f $logfile
