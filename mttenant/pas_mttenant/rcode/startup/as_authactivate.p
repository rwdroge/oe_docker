/*------------------------------------------------------------------------
    File        : as_authactivate.p
    Description : Activate procedure
    Notes       :
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

/* ***************************  Main Block  *************************** */
define variable hCP as handle no-undo.
define variable hCPOut as handle no-undo.
  
message "am I here".        
    log-manager:write-message(string(session:current-request-info:ProcedureName ), 'ACTV8').
  
/* Because we are using the same MSAS for SportsRealm authentication
   AND for our business logic, we need to cheat here and tell the 
   activate procedure NOT to try and SET-DB-CLIENT() when running the 
   SportsRealm class methods.
 */
if session:current-request-info:ProcedureName begins "security.OEUserRealm" then return. 

  
assign hCP = session:current-request-info:GetClientPrincipal() no-error.

    log-manager:write-message("User=" + hCP:user-id + " Domain=" + hCP:domain-name + " Type=" + hCP:domain-type,"ACTV8CP").
 /*
    log-manager:write-message("Roles=" + hCP:roles ,"ACTV8CP").
    log-manager:write-message("Session=" + hCP:session-id,"ACTV8CP").
    log-manager:write-message("ClientContextID= " + STRING(session:current-request-info:ClientContextID ), 'ACTV8CP').
*/
/* this is the important bit */
/* we do not want to set this on our security client */
set-db-client(hCP, 'mttenant').

session:current-response-info:SetClientPrincipal(hCPOut).
        
catch oError as Progress.Lang.Error :
    def var i as int.
    do i = 1 to oError:NumMessages:
        log-manager:write-message(oError:GetMessage(i), 'ACTV8ERR').
    end.
    log-manager:write-message(oError:CallStack, 'ACTV8ERR').
    /* blow up */
    return error oError:GetMessage(1).
end catch.
/* EOF */