#!/bin/bash
# A hook script that will be executed just after database gets created

set -e
cd ${WRKDIR}/${DB_NAME}

# Database will be created in directory "${WRKDIR}/${DB_NAME}" inside container. 
# You can use the same variables in this script for enabling database features like mutitenancy

echo "Executing hook-script.sh"

# uncomment below code and modify if needed to enable multi-tenancy
# proutil ${DB_NAME} -C enablemultitenancy

# uncomment below code and modify if needed to enable table partitioning
# proutil ${DB_NAME} -C enabletablepartitioning

# uncomment below code and modify if needed to enable Change Data Capture (CDC)
# proutil ${DB_NAME} -C enablecdc area <table-areaname> indexarea <index-areaname>

# uncomment below code and modify if needed to enable transparent data encryption
# echo -e "<admin-passphrase>\n<admin-passphrase>\n<optional-user-passphrase>\n<optional-user-passphrase>" > PASS
# proutil sports -C enableencryption < PASS
