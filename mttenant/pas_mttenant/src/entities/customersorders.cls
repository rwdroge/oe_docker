 
 /*------------------------------------------------------------------------
    File        : customerorders
    Syntax      : 
    Author(s)   : rdroge
    Created     : Wed Jan 02 10:08:45 CET 2019
    Notes       : 
  ----------------------------------------------------------------------*/


using Progress.Lang.*.
using OpenEdge.BusinessLogic.BusinessEntity.
using generics.FilterParams.*.
using Progress.Json.ObjectModel.*.

block-level on error undo, throw.

class entities.customersorders inherits BusinessEntity implements interfaces.RO:
    /*------------------------------------------------------------------------------
            Purpose:                                                                      
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    
    {"entities/inc/custorders.i"}
    
    /* TODO Fill in appropriate datasource tables */ 
    define public property ttName as character no-undo initial "ttcustomer,ttorder" get. set. 
    define public property piName as character no-undo initial "custnum" get. set.
    define public property dbName as character no-undo initial "customer" get. set.
    define query qOrder for order.
    define data-source srcttCustomer for customer. 
    define data-source srcttOrder for query qOrder order keys (OrderNum).
    
    /*------------------------------------------------------------------------------
            Purpose:                                                                      
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    constructor public customersorders():
        
        super (dataset dsCustOrder:HANDLE).
    end constructor.
    
    method public void Read(input filter as generics.FilterParams, output dataset-handle hDataset):
        
        this-object:ReadCustomersOrders(filter, output dataset-handle hDataSet).
    
    end method.
        
    /*------------------------------------------------------------------------------
            Purpose:  Get one or more records, based on a filter string                                                                     
            Notes:                                                                        
    ------------------------------------------------------------------------------*/
    method public void ReadCustomersOrders(
            input filter as generics.FilterParams, 
            output DATASET dsCustOrder):
                
            define variable iCustNum as integer no-undo.
            define variable cWhere as character no-undo.
            
            iCustNum = integer(filter:id1).
            cWhere = filter:where. 
            
            if cWhere > "" then
            do:
                query qOrder:query-prepare("FOR EACH Order WHERE order.custnum=" + string(iCustNum) + " AND " + cWhere).
            end.
            else
            do:
                query qOrder:query-prepare("FOR EACH Order WHERE order.custnum=" + string(iCustNum) ).
            end.    
            
            buffer ttCustomer:attach-data-source(data-source srcttCustomer:HANDLE ).
            buffer ttOrder:attach-data-source(data-source srcttOrder:HANDLE ).
            data-source srcttCustomer:fill-where-string = "WHERE custnum=" + string(iCustNum).                
            dataset dsCustOrder:fill().
              
    end method.
    
    {entities/inc/metadata.i &entity=customer}
    
end class.
