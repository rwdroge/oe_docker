
/*------------------------------------------------------------------------
    File        : RO
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : rdroge
    Created     : Jan 10, 2019 8:44:03 AM 2019  
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Lang.*.
using generics.FilterParams.*.
using Progress.Json.ObjectModel.*.

interface interfaces.RO:  
   
    method public void Read(filter as generics.FilterParams, output dataset-handle hDataSet). 
    method public void CheckFieldList(fieldlist as character, output oFieldList as character, output lOk as logical). 
    method public void CreateEntityModel (output lcModel as longchar).

end interface.