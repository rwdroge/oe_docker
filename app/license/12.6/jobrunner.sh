#!/bin/bash

#  Get the environment
source ./Pro2_env.sh
PATH=$PATH:$DLC:$DLC/bin:$PRO2SQL:$PRO2SQL/$CODEDIR; export PATH

cd $PRO2SQL
$DLC/bin/_progres -b -pf $REPLPF -p $CODEDIR/jobrunner.p -n 50

