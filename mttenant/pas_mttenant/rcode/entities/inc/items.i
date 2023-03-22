
 /*------------------------------------------------------------------------
    File        : Items
    Purpose		:
    Syntax      : 
    Description :
    Author(s)   : rdroge
    Created     : Thu Dec 13 10:02:57 CET 2018
    Notes       : 
  ----------------------------------------------------------------------*/
  
  /* ***************************  Definitions  ************************** */
  
  /* ********************  Preprocessor Definitions  ******************** */
  
  /* ***************************  Main Block  *************************** */
  
  /** Dynamically generated schema file **/
   

define temp-table ttItem serialize-name "items" before-table bttItem 
field Itemnum as integer initial "0" label "Item Num"
field ItemName as character label "Item Name"
field Price as decimal initial "0" label "Price"
field Onhand as integer initial "0" label "On Hand"
field Allocated as integer initial "0" label "Allocated"
field ReOrder as integer initial "0" label "Re Order"
field OnOrder as integer initial "0" label "On Order"
field CatPage as integer initial "0" label "Cat Page"
field CatDescription as character label "Cat-Description"
field Category1 as character label "Category1"
field Category2 as character label "Category2"
field Special as character label "Special"
field Weight as decimal initial "0" label "Weight"
field Minqty as integer initial "0" label "Min Qty"
field id     as character
field seq    as integer  
index CatDescription  CatDescription  ascending 
index Category2ItemName  Category2  ascending  ItemName  ascending 
index CategoryItemName  Category1  ascending  ItemName  ascending 
index ItemName  ItemName  ascending 
index ItemNum is  primary  unique  Itemnum  ascending . 


define dataset dsItem for ttItem.