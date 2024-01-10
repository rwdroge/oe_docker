#!/bin/bash
logfile=/app/pas/prodpas/logs/prodpas.agent.log
touch $logfile
/app/pas/prodpas/bin/tcman.sh start -v &
/usr/oecc_agent/oeccagent start    
tail -f $logfile
