
/*------------------------------------------------------------------------
    File        : custorders.i
    Purpose     : 

    Syntax      :

    Description : 

    Author(s)   : rdroge
    Created     : Fri Dec 14 14:00:20 CET 2018
    Notes       :
  ----------------------------------------------------------------------*/

/* ***************************  Definitions  ************************** */


/* ********************  Preprocessor Definitions  ******************** */


/* ***************************  Main Block  *************************** */

define temp-table ttCustomer serialize-name "customer" before-table bttCustomer 
field CustNum as integer initial "0" label "Cust Num"
field Country as character initial "USA" label "Country"
field Name as character label "Name"
field Address as character label "Address"
field Address2 as character label "Address2"
field City as character label "City"
field State as character label "State"
field PostalCode as character label "Postal Code"
field Contact as character label "Contact"
field Phone as character label "Phone"
field SalesRep as character label "Sales Rep"
field CreditLimit as decimal initial "1500" label "Credit Limit"
field Balance as decimal initial "0" label "Balance"
field Terms as character initial "Net30" label "Terms"
field Discount as integer initial "0" label "Discount"
field Comments as character label "Comments"
field Fax as character label "Fax"
field EmailAddress as character label "Email"
field id as character
field seq as integer
index Comments  Comments  ascending 
index CountryPost  Country  ascending  PostalCode  ascending 
index CustNum is  primary  unique  CustNum  ascending 
index Name  Name  ascending 
index SalesRep  SalesRep  ascending .

define temp-table ttOrder before-table bttOrder
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
index CustOrder is  unique  CustNum  ascending  Ordernum  ascending 
index OrderDate  OrderDate  ascending 
index OrderNum is  primary  unique  Ordernum  ascending 
index OrderStatus  OrderStatus  ascending 
index SalesRep  SalesRep  ascending . 

define dataset dsCustOrder for ttCustomer, ttOrder
    data-relation Orders for ttCustomer, ttOrder
    relation-fields (custnum,custnum).