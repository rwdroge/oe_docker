
/*------------------------------------------------------------------------
    File        : FilterParams
    Author(s)   : rdroge
    Created     : Jan 10, 2019 8:45:21 AM 2019
    Notes       : Input parameters for filtering 
  ----------------------------------------------------------------------*/

block-level on error undo, throw.

using OpenEdge.Net.URI.*.

class generics.FilterParams:
    define public property entityName   as character    no-undo get. set.
    define public property entityName2  as character    no-undo get. set.
    define public property TopRecs      as integer      initial 0 no-undo get. set.
    define public property SkipRecs     as integer      initial 0 no-undo get. set.
    define public property Where        as character    no-undo get. set.
    define public property SortBy       as character    no-undo get. set.
    define public property FieldList    as character    no-undo get. set.
    define public property id1          as character    no-undo get. set.
    define public property id2          as character    no-undo get. set.
    define public property rowid        as character    no-undo get. set.
    define public property filtered     as logical      initial false no-undo get. set.


    /*------------------------------------------------------------------------------
     Purpose:
     Notes:
    ------------------------------------------------------------------------------*/
        
    constructor public FilterParams (   input pcentity as character,
                                        input pcentity2 as character,
                                        input pcquerystring as character,
                                        input pcid1 as character,
                                        input pcid2 as character
                                           ):
        
        super ().
        
            if pcid1 > "" then
                this-object:id1 = pcid1.
            if pcid2 > "" then
                this-object:id2 = pcid2.
            if pcentity > "" then
                this-object:entityName2 = pcentity.  
            if pcentity2 > "" then
                this-object:entityName2 = pcentity2.  
            if pcqueryString > "" then 
            do:
                this-object:filtered = true.
                this-object:BuildQueryString(pcquerystring).
                
            end.
    
    end constructor.

    method public void BuildQueryString(input pcquerystring as character):
        define variable cParam as character no-undo.
        define variable i      as integer   no-undo.
        define variable cName  as character no-undo.
        define variable cWhere as character no-undo.
        define variable cValue as character no-undo.
        define variable idx    as integer   no-undo.
        
        do i = 1 to num-entries(pcqueryString, "&"):
            cParam = entry(i, pcqueryString, "&").
            idx = index(cParam, "=").
            if idx > 0 then 
            do:
                cName = substring(cParam, 1, idx - 1, "CHARACTER").
                cValue = OpenEdge.Net.URI:Decode(substring(cParam, idx + 1,-1,"CHARACTER")).
                case cName:
                    when "sort_by" then 
                        this-object:SortBy = entry(2,cParam,"=").
                    when "limit" then
                        this-object:TopRecs = integer(entry(2,cParam,"=")).
                    when "offset" then
                        this-object:SkipRecs = integer(entry(2,cParam,"=")).
                    when "id" then
                        this-object:rowid = entry(2,cParam,"=").
                    otherwise do:
                        this-object:FieldList = left-trim(this-object:FieldList + "," + cName, ",").
                    
                    if cWhere > "" then 
                        cWhere = cWhere + " AND " + cName + "=" + QUOTER(OpenEdge.Net.URI:Decode(cValue)).
                    else 
                        cWhere = cName + "=" + QUOTER(OpenEdge.Net.URI:Decode(cValue)).
                    end.    
                end case.        
                this-object:where = cWhere.
            end.
        end.
        
    end method.
    
    
end class.