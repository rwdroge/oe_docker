/*DEFINE VARIABLE hCP     AS HANDLE NO-UNDO.
DEFINE VARIABLE cCCID   AS CHARACTER NO-UNDO.
DEFINE VARIABLE cReqName AS CHARACTER NO-UNDO.
hCP = SESSION:CURRENT-REQUEST-INFO:GetClientPrincipal().
cCCID = SESSION:CURRENT-REQUEST-INFO:clientContextID.
cReqName = SESSION:CURRENT-REQUEST-INFO:procedureName.
run dumpCP.p (hCP, cReqName).

/*IF (? = cReqName) THEN cReqName = "".                     */
/*                                                          */
/*IF ( NOT VALID-HANDLE(hCP) ) THEN                         */
/*    MESSAGE cReqName "Client-Principal: <invalid-handle>".*/
*/

message "yes".
