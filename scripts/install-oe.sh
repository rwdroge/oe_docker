#!/bin/bash

#ls -l /install/patch/
echo "******** install base **************************************************************************************"
/install/openedge/proinst -b /install/openedge/response.ini -l /install/install_oe.log -n

if [ -f /install/patch/proinst ]; then 
  echo "Installing patch"
  echo -e "\n[Update]\nProgressInstallDir=/usr/dlc\n" >> /install/openedge/response.ini  
  /install/patch/proinst -b /install/openedge/response.ini -l /install/install_patch.log -n
else
  echo "No patch to install"
fi

cat /usr/dlc/version

echo "******** done **************************************************************************************"