/*------------------------------------------------------------------------
    File        : as_authstartup.p
    Description : AppServer Agent startup procedure 
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

define input  parameter pStartupInfo as character no-undo.
 
/* ***************************  Main Block  *************************** */
log-manager:write-message("Startup loading domains","OEREALM").
define variable lOk as logical no-undo.

lOk = security-policy:load-domains("mttenant").

message lOk.

