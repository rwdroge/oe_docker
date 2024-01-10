
 /*------------------------------------------------------------------------
    File        : orders
    Purpose		:
    Syntax      : 
    Description :
    Author(s)   : rdroge
    Created     : Fri Dec 14 13:52:13 CET 2018
    Notes       : 
  ----------------------------------------------------------------------*/
  
  /* ***************************  Definitions  ************************** */
  
  /* ********************  Preprocessor Definitions  ******************** */
  
  /* ***************************  Main Block  *************************** */
  
  /** Dynamically generated schema file **/
   

define temp-table ttOrder serialize-name "orders" before-table bttOrder
field Ordernum as integer initial "0" label "Order Num"
field CustNum as integer initial "0" label "Cust Num"
field OrderDate as date initial "TODAY" label "Ordered"
field ShipDate as date label "Shipped"
field PromiseDate as date label "Promised"
field Carrier as character label "Carrier"
field Instructions as character label "Instructions"
field PO as character label "PO"
field Terms as character initial "Net30" label "Terms"
field SalesRep as character label "Sales Rep"
field BillToID as integer initial "0" label "Bill To ID"
field ShipToID as integer initial "0" label "Ship To ID"
field OrderStatus as character initial "Ordered" label "Order Status"
field WarehouseNum as integer initial "0" label "Warehouse Num"
field Creditcard as character initial "Visa" label "Credit Card"
field id as character
field seq as integer
index CustOrder is  unique  CustNum  ascending  Ordernum  ascending 
index OrderDate  OrderDate  ascending 
index OrderNum is  primary  unique  Ordernum  ascending 
index OrderStatus  OrderStatus  ascending 
index SalesRep  SalesRep  ascending . 


define dataset dsOrder for ttOrder.