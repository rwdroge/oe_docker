#!/bin/bash

#ls -l /install/patch/
echo "******** install base **************************************************************************************"
/install/openedge/proinst -b /install/openedge/response.ini -l /install/install_oe.log -n

if [ -f /install/patch/proinst ]; then 
  echo "Installing patch"
  
  # Use response_update.ini if it exists, otherwise use response.ini with Update section
  if [ -f /install/openedge/response_update.ini ]; then
    echo "Using response_update.ini for patch installation"
    /install/patch/proinst -b /install/openedge/response_update.ini -l /install/install_patch.log -n
  else
    echo "Using response.ini with Update section for patch installation"
    echo -e "\n[Update]\nProgressInstallDir=/usr/dlc\n" >> /install/openedge/response.ini  
    /install/patch/proinst -b /install/openedge/response.ini -l /install/install_patch.log -n
  fi
else
  echo "No patch to install"
fi

cat /usr/dlc/version

echo "******** done **************************************************************************************"