#!/bin/bash

# Initialize CDC (Change Data Capture) for a database table
# This script enables CDC and creates a policy for the specified table

DBNAME=$1
TABLE=$2
LEVEL=${3:-3}  # Default to Level 3 (field-level tracking)

if [[ -z "$DBNAME" ]] || [[ -z "$TABLE" ]]; then
    echo "Usage: init-cdc.sh <dbname> <table> [level]"
    echo "  level: 0 (basic), 1 (field bitmap), 3 (field-level tracking) - default: 3"
    exit 1
fi

echo "Enabling CDC for table: ${TABLE} in database: ${DBNAME}"
echo "CDC Level: ${LEVEL}"

# Create ABL program to enable CDC
cat > /tmp/enable-cdc.p << 'EOFABL'
USING OpenEdge.DataAdmin.*.
USING OpenEdge.DataAdmin.Binding.*.

DEFINE VARIABLE oService AS IDataAdminService NO-UNDO.
DEFINE VARIABLE oTable AS ITable NO-UNDO.
DEFINE VARIABLE oPolicy AS ICdcTablePolicy NO-UNDO.
DEFINE VARIABLE cDbName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cTableName AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLevel AS INTEGER NO-UNDO.

/* Get parameters from session */
cDbName = SESSION:PARAMETER.
ASSIGN
    cTableName = ENTRY(1, cDbName, ",")
    iLevel = INTEGER(ENTRY(2, cDbName, ","))
    cDbName = ENTRY(3, cDbName, ",").

MESSAGE "Connecting to database:" cDbName.
MESSAGE "Enabling CDC for table:" cTableName.
MESSAGE "CDC Level:" iLevel.

/* Connect to database admin service */
oService = NEW DataAdminService(cDbName).

/* Get the table */
oTable = oService:GetTable(cTableName) NO-ERROR.
IF NOT VALID-OBJECT(oTable) THEN DO:
    MESSAGE "ERROR: Table" cTableName "not found in database" cDbName.
    RETURN ERROR.
END.

MESSAGE "Table found:" oTable:Name.

/* Check if CDC policy already exists */
IF VALID-OBJECT(oTable:CdcTablePolicy) THEN DO:
    MESSAGE "CDC policy already exists for table" cTableName.
    MESSAGE "Current level:" oTable:CdcTablePolicy:Level.
    
    /* Update if level is different */
    IF oTable:CdcTablePolicy:Level <> iLevel THEN DO:
        MESSAGE "Updating CDC level from" oTable:CdcTablePolicy:Level "to" iLevel.
        oTable:CdcTablePolicy:Level = iLevel.
        oService:UpdateCdcTablePolicy(oTable:CdcTablePolicy).
        MESSAGE "CDC policy updated successfully!".
    END.
    ELSE DO:
        MESSAGE "CDC policy already at desired level, no changes needed.".
    END.
END.
ELSE DO:
    /* Create new CDC policy */
    MESSAGE "Creating new CDC policy...".
    
    oPolicy = oTable:CreateCdcTablePolicy().
    oPolicy:Level = iLevel.
    oPolicy:TrackDeletes = TRUE.
    
    /* Enable for all areas */
    MESSAGE "Enabling CDC for all areas...".
    
    /* Save the policy */
    oService:UpdateCdcTablePolicy(oPolicy).
    
    MESSAGE "CDC policy created successfully!".
    MESSAGE "  Level:" oPolicy:Level.
    MESSAGE "  Track Deletes:" oPolicy:TrackDeletes.
END.

MESSAGE "CDC initialization complete for" cTableName.

CATCH e AS Progress.Lang.Error:
    MESSAGE "ERROR enabling CDC:" e:GetMessage(1).
    RETURN ERROR e:GetMessage(1).
END CATCH.
EOFABL

# Run the ABL program with parameters
cd /app/db
${DLC}/bin/_progres -b -p /tmp/enable-cdc.p -param "${TABLE},${LEVEL},${DBNAME}" -db ${DBNAME} 2>&1

if [ $? -eq 0 ]; then
    echo "CDC enabled successfully for ${TABLE}"
    
    # Verify CDC tables exist
    echo "Verifying CDC tables..."
    ${DLC}/bin/_progres -b -p - -db ${DBNAME} << 'EOFVERIFY'
DEFINE BUFFER bTracking FOR _CdcChangeTracking.
DEFINE BUFFER bPolicy FOR _CdcTablePolicy.

MESSAGE "Checking CDC system tables...".

FIND FIRST bPolicy NO-LOCK NO-ERROR.
IF AVAILABLE bPolicy THEN
    MESSAGE "  _CdcTablePolicy table exists - CDC is enabled".
ELSE
    MESSAGE "  WARNING: _CdcTablePolicy table not found".

MESSAGE "CDC verification complete.".
EOFVERIFY
    
else
    echo "ERROR: Failed to enable CDC for ${TABLE}"
    exit 1
fi

# Clean up
rm -f /tmp/enable-cdc.p

echo "CDC initialization script completed"
