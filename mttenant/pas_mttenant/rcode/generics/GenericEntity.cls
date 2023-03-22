/*------------------------------------------------------------------------
    File        : GenericEntity
    Purpose     : 
    Syntax      : 
    Description : 
    Author(s)   : egarcia
    Created     : Mon Aug 31 11:21:00 EST 2015
    Notes       : 
  ----------------------------------------------------------------------*/

using Progress.Json.ObjectModel.*.
using Progress.Lang.*.


block-level on error undo, throw.

class generics.GenericEntity: 

    define variable GenericServiceName    as character no-undo initial "mttenantservice".
    define variable entityName            as character no-undo.
	
    constructor public GenericEntity(input entityName as character):
        this-object:entityName = entityName.
    end.
   
	
end class.