/*------------------------------------------------------------------------
   File        : GenericService
   Purpose     : 
   Syntax      : 
   Description : 
   Author(s)   : rdroge
   Created     : Jan 10, 2019 8:45:21 AM 2019
   Notes       : 
 ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using generics.FilterParams.*.
using Progress.Lang.*.
using OpenEdge.Net.*.
using OpenEdge.Net.HTTP.*.
using OpenEdge.Web.*.
using interfaces.CRUD.*.
using interfaces.RO.*.
using generics.GenericEntity.*.

block-level on error undo, throw.

class mttenantHandler inherits WebHandler: 

    method override protected integer HandleGet(input poRequest as OpenEdge.Web.IWebRequest):
        define variable response    as WebResponse       no-undo.
        define variable writer      as WebResponseWriter no-undo.
        
        define variable body        as longchar          no-undo.
        define variable lcModel     as longchar          no-undo.   
        
        define variable entityName  as character         no-undo.
        define variable entityName2 as character         no-undo.
        define variable id1         as character         no-undo.
        define variable id2         as character         no-undo.
        define variable queryString as character         no-undo.        
        define variable oFieldlist  as character         no-undo.
        define variable apiType     as character         no-undo.   
        
        define variable lOk         as logical           no-undo initial true.   
        
        define variable filter      as generics.FilterParams      no-undo.
        define variable entity      as generics.GenericEntity     no-undo.
        define variable dynClass    as interfaces.CRUD   no-undo.
        define variable dynClass2   as interfaces.RO     no-undo.
        
        define variable hDataSet    as handle            no-undo.
        define variable hTempTable  as handle            no-undo.
        define variable hCP         as handle            no-undo.
       
        define variable jsonObject  as JsonObject        no-undo.       
        define variable jsonArray   as JsonArray         no-undo.
        
        response    = new WebResponse().        
        writer      = new WebResponseWriter(response).
        entityName  = poRequest:GetPathParameter("entityname").
        entityName2 = poRequest:GetPathParameter("entityname2").
        id1         = poRequest:GetPathParameter("id1").
        id2         = poRequest:GetPathParameter("id2").
        apiType     = poRequest:GetPathParameter("apitype").
        queryString = poRequest:GetContextValue("QUERY_STRING").
        
        
        if apiType = "data" then
        do:
            filter = new generics.FilterParams(entityName, entityName2, querystring, id1, id2).
            entityName = "entities." + entityName.
            entity = new generics.GenericEntity(entityName).
            dynClass = dynamic-new string(entityName) () no-error.
            
            if entityName2 > "" then
                dynClass2 = dynamic-new string(entityName + entityName2) () no-error.                
            
            if dynClass = ? or ( entityName2 > "" and dynClass2 = ?) then 
            do:
                lOk = false.
                response:StatusCode = 400.
                jsonObject = new JsonObject().
                jsonObject:Add("Error", "Following entities or combination of these entities do not exist for this api").
                jsonObject:Add("Entity", right-trim(left-trim(entityName + "," + entityName2, ","), ",")).
                body = jsonObject:GetJsonText().
            end.
            else if filter:where > "" then
            do:
                if dynClass2 <> ? then 
                do:
                    dynClass2:CheckFieldList(filter:FieldList, output oFieldList, output lOk).
                    if not lOk then 
                    do:
                        response:StatusCode = 400.
                        jsonObject = new JsonObject().
                        jsonObject:Add("Error", "Following field(s) in query do not exist for this entity").
                        jsonObject:Add("Fields", oFieldList).
                        body = jsonObject:GetJsonText().
                    end.
                end.
                else 
                do:
                    dynClass:CheckFieldList(filter:FieldList, output oFieldList, output lOk).
                    if not lOk then
                    do:
                        response:StatusCode = 400.
                        jsonObject = new JsonObject().
                        jsonObject:Add("Error", "Following field(s) in query do not exist for this entity").
                        jsonObject:Add("Fields", oFieldList).
                        body = jsonObject:GetJsonText().
                    end.    
                end.
            end.
            
            if lOk and dynClass2 <> ? then
            do:
                response:StatusCode = 200.
                define variable ii as integer no-undo.
                dynClass2:Read(filter, output dataset-handle hDataSet).
               
                hTempTable = hDataSet:get-buffer-handle(1):table-handle.
                jsonObject = new JsonObject().
                jsonObject:Read(hTempTable).
                
                do ii=2 to hDataSet:num-buffers:
                    hTempTable = hDataSet:get-buffer-handle(ii):table-handle.
                    jsonArray = new JsonArray().
                    jsonArray:read(hTempTable).
                    jsonObject:add(entityName2, jsonArray ).
                                           
                end.
                body = jsonObject:GetJsonText(). 
            end.
            else if lOk then
            /* what if no customers are found and it returns an empty array (json-object is still 'customers' in that case but with an empty array instead of ttcustomer records) */
            
            do:
                
                response:StatusCode = 200.
                dynClass:Read(filter, output dataset-handle hDataSet).
                //hDataSet:write-json("file", "c:\temp\hDataset.json").
                hTempTable = hDataSet:get-buffer-handle(1):table-handle.
                
                hTempTable:write-json('file', '/app/pas/prodpas/temp/hTempTable.json').
                jsonObject = new JsonObject().
                jsonObject:read(hTempTable, true).
                
                body = jsonObject:GetJsonText().
            end.
        end.
        else if apiType = "meta" then
        do:
            
            dynClass = dynamic-new string("entities." + entityName) () no-error.
            dynClass:CreateEntityModel(output lcModel).
            body = lcModel.
        end.    
                
        response:ContentType = "application/json".
        writer:write(body).
        writer:flush().
        writer:close().        
        finally:  
            delete object JsonArray     no-error.
            delete object JsonObject    no-error.
            delete object dynClass      no-error.
            delete object dynClass2     no-error.
            delete object hDataSet      no-error.
            delete object hTempTable    no-error.
            delete object filter        no-error.  
            delete object response      no-error.
            delete object writer        no-error.
        end.
        
    end method.
    
    method override protected integer HandlePost(input poRequest as OpenEdge.Web.IWebRequest):
    
        define variable response    as WebResponse       no-undo.
        define variable writer      as WebResponseWriter no-undo.
        define variable body        as jsonObject        no-undo.
        
        define variable entityName  as character         no-undo.
        define variable entityName2 as character         no-undo.
        define variable id1         as character         no-undo.
        define variable id2         as character         no-undo.
        define variable queryString as character         no-undo.        
        define variable oFieldlist  as character         no-undo.
        define variable lcModel     as longchar          no-undo.   
        define variable apiType     as character         no-undo.   
        define variable responseBody as longchar         no-undo.
        
        define variable filter      as generics.FilterParams      no-undo.
        define variable lOk         as logical           no-undo initial true.   
        
        define variable entity      as generics.GenericEntity     no-undo.
        define variable dynClass    as interfaces.CRUD   no-undo.
        define variable dynClass2   as interfaces.CRUD   no-undo.
        
        define variable hDataSet    as handle            no-undo.
        define variable hTempTable  as handle            no-undo.
        define variable hCP         as handle            no-undo.
       
        define variable jsonObject  as JsonObject        no-undo.       
        define variable jsonArray   as JsonArray         no-undo.
        
        response    = new WebResponse().        
        writer      = new WebResponseWriter(response).
        entityName  = poRequest:GetPathParameter("entityname").
        apiType     = poRequest:GetPathParameter("apitype").
        
        body        = cast(poRequest:Entity, JsonObject).
        
        dynClass = dynamic-new string("entities." + entityName) () no-error.
        
        if dynClass = ? then
        do:
                response:StatusCode = 400.
                jsonObject = new JsonObject().
                jsonObject:Add("Error", "Following entities or combination of these entities do not exist for this api").
                jsonObject:Add("Entity", right-trim(left-trim(entityName + "," + entityName2, ","), ",")).
                
                responseBody = jsonObject:GetJsonText().
        end.
        else do:
            dynClass:Create(body, output dataset-handle hDataSet).
            hDataSet:write-json('longchar', responseBody, true, ?, true, true ).
        end.
        
        response:ContentType = "application/json".
        writer:write(responseBody).
        writer:flush().
        writer:close().
        
    end method.
    
    method override protected integer HandlePut(input poRequest as OpenEdge.Web.IWebRequest):
    
        define variable response    as WebResponse       no-undo.
        define variable writer      as WebResponseWriter no-undo.
        define variable body        as jsonObject        no-undo.
        define variable blaat as character.
        define variable entityName  as character         no-undo.
        define variable entityName2 as character         no-undo.
        define variable id1         as character         no-undo.
        define variable id2         as character         no-undo.
        define variable queryString as character         no-undo.        
        define variable oFieldlist  as character         no-undo.
        define variable lcModel     as longchar          no-undo.   
        define variable apiType     as character         no-undo.   
        define variable responseBody as longchar         no-undo.
        
        define variable filter      as generics.FilterParams      no-undo.
        define variable lOk         as logical           no-undo initial true.   
        
        define variable entity      as generics.GenericEntity     no-undo.
        define variable dynClass    as interfaces.CRUD   no-undo.
        define variable dynClass2   as interfaces.CRUD   no-undo.
        
        define variable hDataSet    as handle            no-undo.
        define variable hTempTable  as handle            no-undo.
        define variable hCP         as handle            no-undo.
       
        define variable jsonObject  as JsonObject        no-undo.       
        define variable jsonArray   as JsonArray         no-undo.
        
        response    = new WebResponse().        
        writer      = new WebResponseWriter(response).
        entityName  = poRequest:GetPathParameter("entityname").
        apiType     = poRequest:GetPathParameter("apitype").
        id1         = poRequest:GetPathParameter("id1").
        
        body        = cast(poRequest:Entity, JsonObject).
        
        filter = new generics.FilterParams(entityName, "", "", id1, "").
        
        dynClass = dynamic-new string("entities." + entityName) () no-error.
        
        if dynClass = ? then
        do:
                response:StatusCode = 400.
                jsonObject = new JsonObject().
                jsonObject:Add("Error", "Following entities or combination of these entities do not exist for this api").
                jsonObject:Add("Entity", right-trim(left-trim(entityName + "," + entityName2, ","), ",")).
                
                responseBody = jsonObject:GetJsonText().
        end.
        else do:
            dynClass:Update(filter, body, output dataset-handle hDataSet).
            hDataSet:write-json('longchar', responseBody ).
        end.
        
        response:ContentType = "application/json".
        writer:write(responseBody).
        writer:flush().
        writer:close().
        
    end method.
    
    method override protected integer HandleDelete(input poRequest as OpenEdge.Web.IWebRequest):
    
        define variable response    as WebResponse       no-undo.
        define variable writer      as WebResponseWriter no-undo.
        define variable body        as jsonObject        no-undo.
        
        define variable entityName  as character         no-undo.
        define variable entityName2 as character         no-undo.
        define variable id1         as character         no-undo.
        define variable id2         as character         no-undo.
        define variable queryString as character         no-undo.        
        define variable oFieldlist  as character         no-undo.
        define variable lcModel     as longchar          no-undo.   
        define variable apiType     as character         no-undo.   
        define variable responseBody as longchar         no-undo.
        
        define variable filter      as generics.FilterParams      no-undo.
        define variable lOk         as logical           no-undo initial true.   
        
        define variable entity      as generics.GenericEntity     no-undo.
        define variable dynClass    as interfaces.CRUD   no-undo.
        define variable dynClass2   as interfaces.CRUD   no-undo.
        
        define variable hDataSet    as handle            no-undo.
        define variable hTempTable  as handle            no-undo.
        define variable hCP         as handle            no-undo.
       
        define variable jsonObject  as JsonObject        no-undo.       
        define variable jsonArray   as JsonArray         no-undo.
        
        response    = new WebResponse().        
        writer      = new WebResponseWriter(response).
        entityName  = poRequest:GetPathParameter("entityname").
        apiType     = poRequest:GetPathParameter("apitype").
        id1         = poRequest:GetPathParameter("id1").
        
        body        = cast(poRequest:Entity, JsonObject).
        
        filter = new generics.FilterParams(entityName, "", "", id1, "").
        
        dynClass = dynamic-new string("entities." + entityName) () no-error.
        
        if dynClass = ? then
        do:
                response:StatusCode = 400.
                jsonObject = new JsonObject().
                jsonObject:Add("Error", "Following entities or combination of these entities do not exist for this api").
                jsonObject:Add("Entity", right-trim(left-trim(entityName + "," + entityName2, ","), ",")).
                
                responseBody = jsonObject:GetJsonText().
        end.
        else do:
            dynClass:Delete(filter, output dataset-handle hDataSet).
            hDataSet:write-json('longchar', responseBody ).
        end.
        
        response:ContentType = "application/json".
        writer:write(responseBody).
        writer:flush().
        writer:close().
        
    end method.
    
    method override protected integer HandleNotAllowedMethod( input poRequest as OpenEdge.Web.IWebRequest ):
        
        undo, throw new Progress.Lang.AppError("This method is not allowed").
    end method.

    method override protected integer HandleNotImplemented( input poRequest as OpenEdge.Web.IWebRequest ):
        
        undo, throw new Progress.Lang.AppError("This method is not implemented").
    end method.
    
end class.