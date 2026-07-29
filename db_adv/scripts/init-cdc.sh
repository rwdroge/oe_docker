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

# Create ABL program to enable CDC using DataAdmin API
cat > /tmp/enable-cdc.p << 'EOFABL'
USING OpenEdge.DataAdmin.* FROM PROPATH.

DEFINE VARIABLE cTableName AS CHARACTER NO-UNDO.
DEFINE VARIABLE iLevel AS INTEGER NO-UNDO.
DEFINE VARIABLE cDbName AS CHARACTER NO-UNDO.
DEFINE VARIABLE cPolicyName AS CHARACTER NO-UNDO.
DEFINE VARIABLE oService AS DataAdminService NO-UNDO.
DEFINE VARIABLE oTable AS ITable NO-UNDO.
DEFINE VARIABLE oPolicy AS ICdcTablePolicy NO-UNDO.
DEFINE VARIABLE oArea AS IArea NO-UNDO.
DEFINE VARIABLE oField AS IField NO-UNDO.
DEFINE VARIABLE oFieldPolicy AS ICdcFieldPolicy NO-UNDO.
DEFINE VARIABLE cFieldName AS CHARACTER NO-UNDO.
DEFINE VARIABLE iPkeyOrder AS INTEGER NO-UNDO.
DEFINE VARIABLE iFieldCount AS INTEGER NO-UNDO.
DEFINE VARIABLE rFileRecid AS RECID NO-UNDO.
DEFINE VARIABLE rPkeyRecid AS RECID NO-UNDO.
DEFINE VARIABLE iPkeyFieldNum AS INTEGER NO-UNDO.
DEFINE VARIABLE oIndexField AS IIndexField NO-UNDO.
DEFINE VARIABLE oIndex AS IIndex NO-UNDO.
DEFINE VARIABLE oPrimaryIndex AS IIndex NO-UNDO.
DEFINE VARIABLE iIndexNum AS INTEGER NO-UNDO.
DEFINE VARIABLE oIterator AS OpenEdge.DataAdmin.Lang.Collections.IIterator NO-UNDO.
DEFINE VARIABLE oIndexFieldIterator AS OpenEdge.DataAdmin.Lang.Collections.IIterator NO-UNDO.
DEFINE VARIABLE cPkeyFields AS CHARACTER NO-UNDO.
DEFINE VARIABLE iPkeyFieldCount AS INTEGER NO-UNDO.

/* Get parameters from session parameter */
cDbName = SESSION:PARAMETER.
ASSIGN
    cTableName = ENTRY(1, cDbName, ",")
    iLevel = INTEGER(ENTRY(2, cDbName, ","))
    cDbName = ENTRY(3, cDbName, ",")
    cPolicyName = cTableName + "-CDC-Policy".

MESSAGE "Enabling CDC for table:" cTableName.
MESSAGE "CDC Level:" iLevel.
MESSAGE "Database:" cDbName.
MESSAGE "Policy name:" cPolicyName.

/* Connect to DataAdmin service */
oService = NEW DataAdminService(cDbName).

/* Get the table */
oTable = oService:GetTable(cTableName, "PUB") NO-ERROR.
IF NOT VALID-OBJECT(oTable) THEN DO:
    MESSAGE "ERROR: Table" cTableName "not found in database".
    DELETE OBJECT oService NO-ERROR.
    RETURN ERROR "Table not found".
END.

MESSAGE "Table found:" oTable:Name.

/* Get the CDC area */
oArea = oService:GetArea("Change Data Area") NO-ERROR.
IF NOT VALID-OBJECT(oArea) THEN DO:
    MESSAGE "ERROR: Change Data Area not found".
    DELETE OBJECT oService NO-ERROR.
    RETURN ERROR "CDC area not found".
END.

/* Check if CDC policy already exists */
oPolicy = oService:GetCdcTablePolicy(cPolicyName) NO-ERROR.

IF VALID-OBJECT(oPolicy) THEN DO:
    MESSAGE "CDC policy already exists:" cPolicyName.
    MESSAGE "Current level:" oPolicy:Level:ToString().
    MESSAGE "Policy already configured, skipping.".
END.
ELSE DO:
    /* Create new CDC policy */
    MESSAGE "Creating new CDC policy:" cPolicyName "...".
    
    oPolicy = oService:NewCdcTablePolicy(cPolicyName).
    ASSIGN 
        oPolicy:Table = oTable
        oPolicy:Level = CdcTablePolicyLevelEnum:GetEnum(iLevel)
        oPolicy:State = CdcTablePolicyStateEnum:Active
        oPolicy:IdentifyingField = YES
        oPolicy:EncryptPolicy = NO
        oPolicy:ChangeTable = cTableName + "CDC"
        oPolicy:ChangeTableOwner = "PUB"
        oPolicy:DataArea = oArea
        oPolicy:IndexArea = oArea
        oPolicy:Description = "Captures all " + cTableName + " changes for CQRS".
    
    /* Add field policies for all fields in the table */
    MESSAGE "Adding field policies for all fields...".
    
    /* Get _File RECID for the table - use actual table name from DataAdmin */
    FIND FIRST _File NO-LOCK WHERE _File._File-name = oTable:Name NO-ERROR.
    IF NOT AVAILABLE _File THEN DO:
        MESSAGE "ERROR: Cannot find _File record for table" oTable:Name.
        DELETE OBJECT oService NO-ERROR.
        RETURN ERROR "Table not found in _File".
    END.
    ASSIGN rFileRecid = RECID(_File).
    MESSAGE "Found _File record for:" _File._File-name.
    
    /* Get primary index from DataAdmin API - find it in Indexes collection */
    /* Find the primary index using iterator */
    oIterator = oTable:Indexes:Iterator().
    DO WHILE oIterator:HasNext():
        oIndex = CAST(oIterator:Next(), IIndex).
        IF VALID-OBJECT(oIndex) AND oIndex:IsPrimary THEN DO:
            ASSIGN oPrimaryIndex = oIndex.
            MESSAGE "Primary index found:" oPrimaryIndex:Name.
            MESSAGE "Primary index has" oPrimaryIndex:IndexFields:Count "fields".
            
            /* Build comma-separated list of primary key field names using iterator */
            ASSIGN cPkeyFields = "".
            oIndexFieldIterator = oPrimaryIndex:IndexFields:Iterator().
            DO WHILE oIndexFieldIterator:HasNext():
                oIndexField = CAST(oIndexFieldIterator:Next(), IIndexField).
                IF VALID-OBJECT(oIndexField) AND VALID-OBJECT(oIndexField:Field) THEN DO:
                    IF cPkeyFields = "" THEN
                        ASSIGN cPkeyFields = oIndexField:Field:Name.
                    ELSE
                        ASSIGN cPkeyFields = cPkeyFields + "," + oIndexField:Field:Name.
                END.
            END.
            MESSAGE "Primary key fields:" cPkeyFields.
            LEAVE.
        END.
    END.
    
    IF NOT VALID-OBJECT(oPrimaryIndex) THEN
        MESSAGE "WARNING: No primary index found for table" oTable:Name.
    
    /* Iterate through _Field system table to get all fields */
    FOR EACH _Field NO-LOCK WHERE _Field._File-recid = rFileRecid:
        cFieldName = _Field._Field-name.
        
        /* Get the field from DataAdmin API */
        oField = oTable:Fields:Find(cFieldName) NO-ERROR.
        IF NOT VALID-OBJECT(oField) THEN NEXT.
        
        /* Create field policy */
        oFieldPolicy = oService:NewCdcFieldPolicy().
        oFieldPolicy:Field = oField.
        
        /* Check if this field is part of primary key */
        ASSIGN iPkeyOrder = 0.
        IF cPkeyFields <> "" THEN DO:
            ASSIGN iPkeyOrder = LOOKUP(cFieldName, cPkeyFields).
        END.
        
        IF iPkeyOrder > 0 THEN DO:
            oFieldPolicy:IdentifyingField = iPkeyOrder.
            MESSAGE "  - " cFieldName "(identifying field" iPkeyOrder ")".
        END.
        ELSE
            MESSAGE "  - " cFieldName.
        
        oPolicy:FieldPolicies:Add(oFieldPolicy).
        ASSIGN iFieldCount = iFieldCount + 1.
    END.
    
    MESSAGE "Total fields added:" iFieldCount.
    
    oService:CreateCdcTablePolicy(oPolicy).
    
    MESSAGE "CDC policy created successfully!".
    MESSAGE "  Policy:" cPolicyName.
    MESSAGE "  Table:" cTableName.
    MESSAGE "  Level:" iLevel.
END.

MESSAGE "CDC initialization complete for" cTableName.

DELETE OBJECT oService NO-ERROR.

CATCH e AS Progress.Lang.Error:
    MESSAGE "ERROR enabling CDC:" e:GetMessage(1).
    DELETE OBJECT oService NO-ERROR.
    RETURN ERROR e:GetMessage(1).
END CATCH.
EOFABL

# Run the ABL program with parameters
cd /app/db
${DLC}/bin/_progres -b -p /tmp/enable-cdc.p -param "${TABLE},${LEVEL},${DBNAME}" -db ${DBNAME} 2>&1

if [ $? -eq 0 ]; then
    echo "CDC enabled successfully for ${TABLE}"
else
    echo "ERROR: Failed to enable CDC for ${TABLE}"
    exit 1
fi

# Clean up
rm -f /tmp/enable-cdc.p

echo "CDC initialization script completed"
