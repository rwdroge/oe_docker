

using Progress.Lang.*.

interface security.IOERealm: 

    method public character GetAttribute( input theUserId as integer, input attrName as character ).
    method public character extent GetAttributeNames( input theUserId as integer ).
    method public character extent GetUserNames(  ).
    method public character extent GetUserNamesByQuery( input queryString as character ).
    method public character extent GetUserNamesByQuery( input attrName as character, input attrValue as character ).
    method public logical RemoveAttribute( input theUserId as integer, input attrName as character ).
    method public logical SetAttribute( input theUserId as integer, input attrName as character, input attrValue as character ).
    method public logical ValidatePassword( input theUserId as integer, input password as character ).
    method public logical ValidatePassword( input theUserId as integer, input digest as character, input nonce as character, input timestamp as character ).
    method public integer ValidateUser( input userName as character ).
        
end interface.
