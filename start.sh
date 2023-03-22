#!/bin/bash
logfile=/app/pas/prodpas.agent.log
touch $logfile
tail -f $logfile
