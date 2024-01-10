 
 /*------------------------------------------------------------------------
    File        : SportsRealm
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : Administrator
    Created     : Mon Apr 27 22:56:36 EDT 2015
    Notes       : 
  ----------------------------------------------------------------------*/
block-level on error undo, throw.

using Progress.Security.Realm.IHybridRealm.
using Progress.Json.ObjectModel.*.

class security.mttenantRealm implements IHybridRealm:
    define private query qryUsers for mttenant._User.
   //define private query qryRoles for securitydb.GrantedRole.
    
	method public character GetAttribute( input p0 as integer, input p1 as character ):
	    define variable cAttribute as character no-undo.
	    define variable joAttribute as jsonobject.
		//log-manager:write-message ("GetAttribute UID=" + STRING(p0) + " Attribute=" + p1, "OEREALM").
		message "p1" p1.
		
		case p1:
		    when "ATTR_ROLES" then
		    do:
		        /*
		        find securitydb.ApplicationUser where
		             securitydb.ApplicationUser.Id eq p0
		             no-lock no-error. 
		        for each GrantedRole where
		                 securitydb.GrantedRole.Grantee eq securitydb.ApplicationUser.LoginName
		                 no-lock:
		          cAttribute = cAttribute + ',' + securitydb.GrantedRole.RoleName.              
                end.
                cAttribute = left-trim(cAttribute, ',').
	        end.
            when "ATTR_PROPERTIES" then
              log-manager:write-message ("GetAttribute Attr Val=" + cAttribute, "OEREALM").  
                */
                cAttribute = "PSCUser".
                end.
	    end case.
	    
	   // log-manager:write-message ("GetAttribute Attr Val=" + cAttribute, "OEREALM").
	    
	    return cAttribute.
	end method.

	method public character extent GetAttributeNames( input p0 as integer ):
		define variable cNames as character extent 1 no-undo.
		
        //log-manager:write-message ("GetAttributeNames UID=" + STRING(p0),"OEREALM").
        
        /* we only support getting roles */
        cNames[1] = "ATTR_ROLES".
        
        return cNames.
	end method.

	method public character extent GetUserNames(  ):
	    define variable cNames as character extent no-undo.
	    open query qryUsers preselect each mttenant._User no-lock.
	    //log-manager:write-message ("GetUserNames").
	    
        extent(cNames) = query qryUsers:num-results.
        get first qryUsers.
        do while not query-off-end('qryUsers'):
            cNames[query qryUsers:current-result-row] = mttenant._User._user-name.
            get next qryUsers.
        end. 
        
        return cNames.
        finally:
            close query qryUsers.
        end finally.		
	end method.

	method public character extent GetUserNamesByQuery( input p0 as character ):
        define variable cNames as character extent no-undo.
        
        query qryUsers:query-prepare('PRESELECT EACH _User NO-LOCK where ' + p0).
        query qryUsers:query-open().
            
        extent(cNames) = query qryUsers:num-results.
        get first qryUsers.
        do while not query-off-end('qryUsers'):
            cNames[query qryUsers:current-result-row] = mttenant._User._user-name.
            get next qryUsers.
        end.
        
        return cNames.
        finally:
            close query qryUsers.
        end finally.        
	end method.

	method public logical RemoveAttribute( input p0 as integer, input p1 as character ):
		return false.
	end method.

	method public logical SetAttribute( input p0 as integer, input p1 as character, input p2 as character ):
		
		undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

	end method.

	method public logical ValidatePassword( input p0 as integer, input p1 as character ):
	    define variable cHashedPw as character no-undo.
	    
	    //log-manager:write-message ("ValidatePassword UID=" + STRING(p0) ,"OEREALM").
	    
	    find mttenant._User where
	         mttenant._User._User_number eq p0
	         no-lock no-error.
        if not available mttenant._User then
            return false.
        
        /* cHashedPw = base64-encode(generate-pbe-key(p1, 
                                  /* use a per-user salt */
                                  message-digest('sha-512', 
                                                 substitute('&1@&2', lc(securitydb.ApplicationUser.LoginName), lc(securitydb.ApplicationUser.LoginDomain))))). 
        */
        cHashedPw = encode(p1).
        //log-manager:write-message ("ValidatePassword passed? " + STRING((securitydb.ApplicationUser.Password eq cHashedPw)) ,"OEREALM").
        message mttenant._User._Password eq cHashedPw.
        return (mttenant._User._Password eq cHashedPw).
	end method.

	method public logical ValidatePassword( input p0 as integer, input p1 as character, input p2 as character, input p3 as character ):
		
		undo, throw new Progress.Lang.AppError("METHOD NOT IMPLEMENTED").

	end method.

	method public integer ValidateUser( input p0 as character ):
		define variable cName as character no-undo.
		define variable cDomain as character no-undo.
		
        //log-manager:write-message ("ValidateUser Name=" + p0 ,"OEREALM"). 
        
		cName = entry(1, p0, '@').
		if num-entries(p0, '@') ge 2 then
		  cDomain = entry(2, p0, '@').
		
        find mttenant._User where
             mttenant._User._User-Name = cName and 
             mttenant._User._Domain-Name = cDomain
             no-lock no-error.
       
        if available mttenant._User then do:
          return mttenant._User._User_number.	
		  	end.
        
        return ?.
	end method.

end class.
