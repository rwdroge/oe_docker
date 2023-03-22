 
 /*------------------------------------------------------------------------
    File        : CheckMetaData
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : rdroge
    Created     : Fri Jan 04 15:55:52 CET 2019
    Notes       : 
  ----------------------------------------------------------------------*/

 method public void CheckFieldList (input fieldlist as character, output oFieldList as character, output lOk as logical):
        define variable cFieldList  as character no-undo.
        define variable ii          as integer no-undo.
        define variable cNotListed  as character no-undo.
        
        lOk = true.
        
        create tt{&entity}.
        
        do ii = 1 to buffer tt{&entity}:num-fields:
            cFieldList = right-trim(buffer tt{&entity}:buffer-field(ii):name + "," + cFieldList, ",").
        end.
        
        
        ii = 0.
        
        do ii = 1 to num-entries(fieldlist, ","):
            if lookup(entry(ii,fieldlist),cFieldList) = 0 then do:
                cNotListed = left-trim(cNotListed + "," + entry(ii, fieldlist), ",").
                
            end.
            if cNotListed > "" then
            lOk = false.
        end.
        
        oFieldList = cNotListed.
        delete tt{&entity}.
        
    end method.
    
    method public void CreateEntityModel (output lcModel as longchar ):
        define variable ii as integer no-undo.
        define variable joModel as JsonObject no-undo.
        
        joModel = new JsonObject().
        create tt{&entity}.       
    
        do ii = 1 to buffer tt{&entity}:num-fields:
            define variable cdataType as character no-undo.
            
            case  buffer tt{&entity}:buffer-field(ii):data-type:
                when "character"    then cdataType = "string".
                when "decimal"      then cdataType = "number".
                when "logical"      then cdataType = "boolean".
                otherwise
                    cdataType = buffer tt{&entity}:buffer-field(ii):data-type.
            end case.
                     
            if (buffer tt{&entity}:buffer-field(ii):name <> "seq" and buffer tt{&entity}:buffer-field(ii):name <> "id") then
            joModel:add(buffer tt{&entity}:buffer-field(ii):name, cdataType).
        end.
        
        lcModel = joModel:GetJsonText().
        delete tt{&entity}.
        delete object joModel.
        
    end method.   
