 
 /*------------------------------------------------------------------------
    File        : OEUserRealm
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : mjacobs
    Created     : Thu Mar 14 15:37:24 EDT 2013
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using security.IOERealm.
using security.OERealmDefs.
using util.Properties.

routine-level on error undo, throw.

class security.OEUserRealm implements IOERealm final : 

    define private variable attributes as character no-undo initial "ATTR_SURNAME,ATTR_GIVENNAME,ATTR_TELEPHONE,ATTR_EMAIL,ATTR_DESCRIPTION,ATTR_ENABLED,ATTR_EXPIRED,ATTR_DOMAIN,ATTR_ROLES". 

    /* Define the default properties for this class instance */
    define private variable  m_propFile         as character initial "OEUserRealm.properties" no-undo. 
    define private variable  m_properties       as class Properties no-undo. 

    define private variable m_debugMsg          as logical no-undo initial true.
    define private variable m_traceMsg          as logical no-undo initial true.
    define private variable m_autoUserNum       as logical initial yes no-undo. 
   /*------------------------------------------------------------------------------
	 Purpose:
	 Notes:
	------------------------------------------------------------------------------*/

	constructor public OEUserRealm (  ):
        super ().

        if ( m_debugMsg ) then
            message "Initializing OEUserRealm...".

        LoadProperties(). 

	end constructor.

	destructor public OEUserRealm ( ):

	end destructor.

    method public character GetAttribute( input theUserId as integer, input attrName as character ):
        
        define variable retVal      as character no-undo.
        define variable fqUserid    as character no-undo. 


        if ( m_debugMsg ) then
            message "Get Attribute " attrName " for user number " theUserId.
        find first _User where _User._User_number = theUserId no-error.
        
        if ( m_debugMsg ) then
		 do: 
		      message  _User._User_number.
		      message theUserId.
		 end.
		      
        if available _User then do:
            if ( _User._Domain-Name = "" ) then
                fqUserid = _User._Userid.
            else
                fqUserid = _User._Userid + "@" + _User._Domain-Name.
				
				if ( m_debugMsg ) then
				    message fqUserid.

            case caps(attrName):
                when OERealmDefs:REALM_ATTR_SURNAME then
                    retVal = _User._Surname.
                when OERealmDefs:REALM_ATTR_GIVENNAME then 
                    retVal = _User._Given_name.
                when OERealmDefs:REALM_ATTR_TELEPHONE then 
                    retVal = _User._Telephone.
                when OERealmDefs:REALM_ATTR_EMAIL then 
                    retVal = _User._Email.
                when OERealmDefs:REALM_ATTR_DESCRIPTION then 
                    retVal = _User._Description.
                when OERealmDefs:REALM_ATTR_USERID then
                    retVal = fqUserid.
                when OERealmDefs:REALM_ATTR_DOMAIN then
                    retVal = _User._Domain-Name.
				when OERealmDefs:REALM_ATTR_EXPIRED then do:
				    if (  _User._Account_expires <  now ) then 
                                /*     if _User._Account_expires > NOW or _User._Account_expires = ? then */
                       undo, throw new Progress.Lang.AppError("User is expired ", 2).
                    else
                      retVal = "0".     /* !Enabled */  
                end.  
				       					
                when OERealmDefs:REALM_ATTR_ENABLED then do:
                    if ( ? = _User._Disabled or _User._Disabled = no ) then
                       retVal = "1".      /* Enabled */
                    else
                /*       retVal = "0".     /* !Enabled */ */
                     undo, throw new Progress.Lang.AppError("User is disabled", 2).
                end.
				
                when OERealmDefs:REALM_ATTR_ROLES then do:
                    define variable roles   as character no-undo. 
                    define variable count   as  integer initial 0 no-undo. 

                    if ( m_debugMsg ) then
                        message "Get user roles for user number " theUserId "(" fqUserid ")".
                    roles = ?.

                    for each _sec-granted-role where _sec-granted-role._grantee = fqUserid :
                        if ( m_traceMsg ) then
                            message "Found role '" + _sec-granted-role._role-name + "' for userid" theUserId.
                        if ( count = 0 ) then
                            roles = "".
                        else
                            roles = roles + ",".
                        roles = roles + _sec-granted-role._Role-name.
                        count = count + 1.
                    end.
                    if ( m_debugMsg ) then
                        message "Found '" roles "' roles for user-id" theUserId "(" fqUserid ")".
						//message "Irfan ... getArrib( ) return " roles.
						
                    retVal = roles.
                end.
                otherwise do:
                    if ( m_debugMsg ) then
                        message "Unknown attribute name in GetAttribute:" attrName.
                    retVal = ?.
                end.
            end.
        end.
        else do:
            if ( m_debugMsg ) then
                message "Unknown user-id found in GetAttribute:" theUserId.
            undo, throw new Progress.Lang.AppError("Invalid User Id", 1).
        end.

        release _User.
        if ( m_traceMsg ) then
            message "Returning " retVal " for attribute value" attrName.
        return retVal.
        
    end method.

    method public character extent GetAttributeNames( input theUserId as integer ):
        
        define variable results     as character extent no-undo.
        define variable attrNames   as character extent 10 no-undo.
        define variable attrVal     as character no-undo.
        define variable numAttrs    as integer no-undo initial 0.
        define variable i           as integer no-undo.
        define variable fqUserid    as character no-undo. 
        
        if ( m_debugMsg ) then
            message "Get account attributes for user number " theUserId.
        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            if ( _User._Domain-Name = "" ) then
                fqUserid = _User._Userid.
            else
                fqUserid = _User._Userid + "@" + _User._Domain-Name.

            /* Check to see what attributes have values */
            attrVal = _User._Surname.
            if attrVal <> ? then do:
                 numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_SURNAME.
            end.
            attrVal = _User._Given_name.
            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_GIVENNAME.
            end.
            attrVal = _User._Telephone.
            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_TELEPHONE.
            end.
            attrVal = _User._Email.
            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_EMAIL.
            end.
            attrVal = _User._Description.
            if attrVal <> ? then do:
                numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_DESCRIPTION.
            end.
            attrVal = _User._Userid.
            if attrVal <> ? then do:
               numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_USERID.
            end.
            attrVal = _User._Domain-Name.
            if attrVal <> ? then do:
               numAttrs = numAttrs + 1.
                 attrNames[numAttrs] = OERealmDefs:REALM_ATTR_DOMAIN.
            end.
            do :
                find first _sec-granted-role where _sec-granted-role._grantee = fqUserid.
                if available _sec-granted-role then do:
                    numAttrs = numAttrs + 1.
                    attrNames[numAttrs] = OERealmDefs:REALM_ATTR_ROLES.
                end.
            end.
            if numAttrs > 0 then do:
                if ( m_traceMsg ) then
                    message "Number of attribute names: " numAttrs.
                extent(results) = numAttrs.
                do i = 1 to numAttrs:
                    results[i] = attrNames[i].
                    if ( m_traceMsg ) then
                        message results[i].
                end.
            end.
        end.
        else   
            undo, throw new Progress.Lang.AppError("User not found", 2).

        release _User.
        return results.
        
    end method.

    method public character extent GetUserNames(  ):
        
        define variable results as character extent no-undo.
        define variable num as integer no-undo initial 0.
        define variable fqUserid    as character no-undo. 
        
        if ( m_debugMsg ) then
            message "Get user account list".

        /* First count the names */
        for each _User:
            num = num + 1.
        end. 
        
        extent(results) = num.
        num = 1.
        for each _User:
            if ( _User._Domain-Name = "" ) then
                fqUserid = _User._Userid.
            else
                fqUserid = _User._Userid + "@" + _User._Domain-Name.
            results[num] = fqUserid.
            num = num + 1.
        end.
        
        release _User.
        return results.

    end method.

    method public character extent GetUserNamesByQuery( input queryString as character ):
        
        define variable results     as character extent no-undo.
        define variable num         as integer no-undo initial 0.
        define variable fqUserid    as character no-undo. 
        
        if ( m_debugMsg ) then
            message "Get users by QueryString = " queryString. 
        /* First count the names */
        for each _User where _User._Userid matches queryString:
            if ( m_traceMsg ) then
                message "Match: " _User._Userid + "@" + _User._Domain-Name.
            num = num + 1.
        end. 
        
        extent(results) = num.
        num = 1.
        for each _User where _User._Userid matches queryString:
            if ( _User._Domain-Name = "" ) then
                fqUserid = _User._Userid.
            else
                fqUserid = _User._Userid + "@" + _User._Domain-Name.
            results[num] = fqUserid.
            num = num + 1.
        end.
        
        release _User.
        if ( m_traceMsg ) then
            message extent(results).
        return results.
        

    end method.

    method public character extent GetUserNamesByQuery( input attrName as character, input attrValue as character ):
        
        define variable results     as character extent no-undo.
        define variable temp        as character extent 100 no-undo.
        define variable num         as integer no-undo initial 0.
        define variable whichAttr   as integer no-undo.
        define variable fqUserid    as character no-undo. 
        
        if ( m_debugMsg ) then
            message "Get user by attribute name: " attrName " Attribute value: " attrValue.
        whichAttr =  lookup(attrName, attributes).
        if whichAttr = 0 then return results.
        
        /* First count the names */
        for each _User:
            if ( _User._Domain-Name = "" ) then
                fqUserid = _User._Userid.
            else
                fqUserid = _User._Userid + "@" + _User._Domain-Name.
            case whichAttr:
                when 1 then
                    if _User._Surname matches attrValue then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
                when 2 then 
                    if _User._Given_name matches attrValue then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
                when 3 then 
                    if _User._Telephone matches attrValue then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
                when 4 then 
                    if _User._Email matches attrValue then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
                when 5 then 
                    if _User._Description matches attrValue then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
                when 6 then do:
                    define variable matchval as logical no-undo. 
                    if ( attrValue = LC("yes") or
                         attrValue = LC("true") or
                         attrValue <> "0" ) then
                        matchval = no.
                    else
                        matchval = yes.
                    if _User._disabled = matchval then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
                end.
                when 6 then
                    if _User._Domain-Name matches attrValue then do:
                        if ( m_traceMsg ) then
                            message "Match: " fqUserid.
                        num = num + 1.
                        temp[num] = fqUserid.
                    end.
            end.
        end. 
        
        extent(results) = num.
        do whichAttr = 1 to num:
            results[whichAttr] = temp[whichAttr].
        end.
        
        release _User.

        if ( m_traceMsg ) then
            message extent(results).

        return results.
        

    end method.


    method public logical RemoveAttribute( input theUserId as integer, input attrName as character ):
        
        define variable retVal as logical no-undo initial true.
        
        if ( m_debugMsg ) then
            message "Remove attribute " attrName " for user number " theUserId.
        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            case attrName:
                when OERealmDefs:REALM_ATTR_SURNAME then
                    _User._Surname = ?.
                when OERealmDefs:REALM_ATTR_GIVENNAME then 
                    _User._Given_name = ?.
                when OERealmDefs:REALM_ATTR_TELEPHONE then 
                    _User._Telephone = ?.
                when OERealmDefs:REALM_ATTR_EMAIL then 
                    _User._Email = ?.
                when OERealmDefs:REALM_ATTR_DESCRIPTION then 
                    _User._Description = ?.
                otherwise do:
                    /* You cannot remove the domain or enabled attributes */
                    retVal = false.
                    release _User.
                end.
            end.
        end.
        else   
            undo, throw new Progress.Lang.AppError("Invalid User Id", 3).

        release _User.
        return retVal.

    end method.

    method public logical SetAttribute( input theUserId as integer, input attrName as character, input attrValue as character ):
        
        define variable retVal as logical no-undo initial true.
        
        if ( m_debugMsg ) then
            message "Set attribute " attrName " for user number " theUserId " with a value of " attrValue.
        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            case attrName:
                when OERealmDefs:REALM_ATTR_SURNAME then
                    _User._Surname = attrValue.
                when OERealmDefs:REALM_ATTR_GIVENNAME then 
                    _User._Given_name = attrValue.
                when OERealmDefs:REALM_ATTR_TELEPHONE then 
                    _User._Telephone = attrValue.
                when OERealmDefs:REALM_ATTR_EMAIL then 
                    _User._Email = attrValue.
                when OERealmDefs:REALM_ATTR_DESCRIPTION then 
                    _User._Description = attrValue.
                when OERealmDefs:REALM_ATTR_EXPIRED then do:
				_User._Account_expires = now.
                  /*  DEFINE VARIABLE matchval1 AS LOGICAL NO-UNDO. 
                    IF ( attrValue = LC("yes") OR
                         attrValue = LC("true") OR
                         attrValue <> "0" ) THEN
                        matchval1 = NO.
                    ELSE
                        matchval1 = YES. */
                   /* _User._Account_expires = matchval1. */
                end.
				when OERealmDefs:REALM_ATTR_ENABLED then do:
                    define variable matchval as logical no-undo. 
                    if ( attrValue = LC("yes") or
                         attrValue = LC("true") or
                         attrValue <> "0" ) then
                        matchval = no.
                    else
                        matchval = yes.
                    _User._Disabled = matchval. 
                end.
                otherwise do:
                    /* Cannot change the user's domain or user-id values */
                    retVal = false.
                    release _User.
                end.
            end.
        end.
        else   
            undo, throw new Progress.Lang.AppError("Invalid User Id", 4).

        release _User.
        return retVal.

    end method.

    method public logical ValidatePassword( input theUserId as integer, input password as character ):
        
        define variable retVal as logical no-undo initial false.
        
        
        if ( m_debugMsg ) then
            message "Validate password using basic " password.
        /* MESSAGE "Password: " password. */

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            if ( m_debugMsg ) then
                message "** Pwd check for user:" _User._userid .

            if _User._Password = ENCODE(password) then 
                retVal = true.
            else
                retVal = false.
        end.
        else do:  
            if ( m_debugMsg ) then
                message "Invalid user lookup for id number: " theUserId.
            undo, throw new Progress.Lang.AppError("Invalid User Id", 5).
        end.

        release _User.

        if ( m_debugMsg ) then do:
            if ( retVal ) then
                message "Validate basic password success".
            else 
                message "Validate basic password failure".
        end.
           if ( m_debugMsg ) then
                message "Returning from validatePwd " retVal.
                
        return retVal.
        
    end method.

    method public logical ValidatePassword( input theUserId as integer, input digest as character, input nonce as character, input timestamp as character ):
        
        define variable retVal as logical no-undo initial false.
        define variable password as character no-undo.
        define variable myDigest as character no-undo.
        define variable df as character no-undo. 
        define variable remoteTS as datetime-tz no-undo.
        define variable dif as int64 no-undo.
        define variable hash as raw no-undo.
        
        if ( m_debugMsg ) then
            message "Validate password using digest".

        find first _User where _User._User_number = theUserId no-error.
        if available _User then do:
            password = _User._Password.
        end.
        else 
          undo, throw new Progress.Lang.AppError("User not found", 6).

        release _User.
        
        if ( m_debugMsg ) then
            message "Validate password using digest".
        if ( m_traceMsg ) then do:
            message "Digest: " digest.
            message "Nonce: " nonce.
            message "Timestamp: " timestamp.
        end.

        df = session:date-format.
        session:date-format = "ymd".
        remoteTS = datetime-tz(timestamp).
        session:date-format = df.
        
        dif = absolute(interval(now, remoteTS, "seconds")).
        
        if dif > 1 then
          undo, throw new Progress.Lang.AppError("Old timestamp sent", 7).

        myDigest = password + nonce + timestamp.
        hash = sha1-digest(myDigest).
        myDigest = base64-encode(hash).
        if ( m_traceMsg ) then
            message "Computed digest: " myDigest.
        if myDigest = digest then 
            retVal = true.
        else
            retVal = false.

        if ( m_debugMsg ) then do:
            if ( retVal ) then
                message "Validate digest password success".
            else
                message "Validate digest password failure".
        end.

        return retVal.
        
    end method.

    method public integer ValidateUser( input userName as character ):
        
        define variable userNum as integer no-undo.
        define variable usernm  as character initial "" no-undo. 
        define variable domain  as character initial "" no-undo. 


        usernm = entry(1,userName,"@").
        domain = entry(2,userName,"@") no-error. 

        if ( m_debugMsg ) then
            message "Lookup ABL user account for:" userName.

        find first _User where _User._Userid = usernm and 
                               _User._Domain-Name = domain and 
                               _User._sql-only-user = no no-error.
        if available _User then do:
            userNum = _User._User_number.

            if ( m_traceMsg ) then
                message "ValidateUser found user:" _user._userid + "@" + _user._domain-name.

            if ( ? = userNum and m_autoUserNum ) then do:
                define variable newUserNum      as integer  no-undo. 
              //  newUserNum = next-value( Next-User-Num ).
                if ( m_debugMsg ) then
                    message "Lookup user account issued user" userName "ID number" newUserNum.
                assign _User._User_number = newUserNum.
                userNum = _User._User_number.
            end.

            release _User.

            if ( m_debugMsg ) then
                message "Lookup user account for:" userName "returned id:" userNum.
            return userNum.
        end.
        else   
          undo, throw new Progress.Lang.AppError("User not found", 8).

    end method.

    method private void LoadProperties() :
        m_properties = new Properties().
        m_properties:Load(m_propFile).

//        m_debugMsg = Yes. /*m_properties:GetLogicalProperty("debug", NO).*/
//        m_traceMsg = Yes. /*m_properties:GetLogicalProperty("trace", NO).*/
        m_debugMsg = m_properties:GetLogicalProperty("debugMsg", no).
        m_traceMsg = m_debugMsg. 

        //MESSAGE "Debug property value:" m_debugMsg.
        //MESSAGE "Trace property value:" m_traceMsg.

    end method.


end class.
