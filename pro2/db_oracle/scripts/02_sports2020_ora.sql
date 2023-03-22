CONNECT pro2/pro2password@//localhost:1521/ORCLPDB1;

CREATE SEQUENCE Pro2SQL_SEQ START WITH 1 INCREMENT BY 1;
CREATE TABLE Pro2SQL (
  pname varchar2(20) not null,
  pversion varchar2(10) null,
  PROGRESS_RECID number null
);
CREATE UNIQUE INDEX Pro2SQL##mainkey ON Pro2SQL (pname ASC);

CREATE UNIQUE INDEX Pro2SQL##recid ON Pro2SQL (PROGRESS_RECID ASC);

INSERT INTO Pro2SQL (pname, pversion, PROGRESS_RECID)
  VALUES ('Pro2SQL','v6.4.0', 1);

CREATE SEQUENCE p2smismatch_SEQ START WITH 1 INCREMENT BY 1;
CREATE TABLE p2smismatch (
  verdate date null,
  vertime varchar2(8) null,
  tblname varchar2(32) null,
  record varchar2(32) null,
  fieldlist varchar2(4000) null,
  srcvalues varchar2(4000) null,
  tgtvalues varchar2(4000) null,
  PROGRESS_RECID number null
);
CREATE INDEX p2smismatch##vertime ON p2smismatch ( verdate ASC, vertime ASC);
CREATE INDEX p2smismatch##vertable ON p2smismatch (tblname ASC,record ASC,verdate ASC,vertime ASC);

CREATE UNIQUE INDEX p2smismatch##recid ON p2smismatch (PROGRESS_RECID ASC);

CREATE SEQUENCE benefits_SEQ START WITH 1 increment BY 1;
CREATE TABLE benefits (
  prrowid varchar2(36) not null,
  empnum number null,
  healthcare varchar2(16) null,
  lifeinsurance number null,
  pension401k number null,
  stockpurchase number null,
  medicalspending number null,
  dependentcare number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX benefits##prrowid ON benefits (prrowid);
CREATE UNIQUE INDEX benefits##recid ON benefits (PROGRESS_RECID);

CREATE SEQUENCE billto_SEQ START WITH 1 increment BY 1;
CREATE TABLE billto (
  prrowid varchar2(36) not null,
  custnum number null,
  billtoid number null,
  name varchar2(60) null,
  address varchar2(70) null,
  address2 varchar2(70) null,
  city varchar2(50) null,
  state varchar2(40) null,
  postalcode varchar2(20) null,
  contact varchar2(60) null,
  phone varchar2(40) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX billto##prrowid ON billto (prrowid);
CREATE UNIQUE INDEX billto##recid ON billto (PROGRESS_RECID);

CREATE SEQUENCE bin_SEQ START WITH 1 increment BY 1;
CREATE TABLE bin (
  prrowid varchar2(36) not null,
  warehousenum number null,
  itemnum number null,
  qty number null,
  binnum number null,
  binname varchar2(60) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX bin##prrowid ON bin (prrowid);
CREATE UNIQUE INDEX bin##recid ON bin (PROGRESS_RECID);

CREATE SEQUENCE customer_SEQ START WITH 1 increment BY 1;
CREATE TABLE customer (
  prrowid varchar2(36) not null,
  custnum number null,
  country varchar2(40) null,
  name varchar2(60) null,
  address varchar2(70) null,
  address2 varchar2(70) null,
  city varchar2(50) null,
  state varchar2(40) null,
  postalcode varchar2(20) null,
  contact varchar2(60) null,
  phone varchar2(40) null,
  salesrep varchar2(8) null,
  creditlimit number null,
  balance number null,
  terms varchar2(40) null,
  discount number null,
  comments varchar2(160) null,
  fax varchar2(40) null,
  emailaddress varchar2(100) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX customer##prrowid ON customer (prrowid);
CREATE UNIQUE INDEX customer##recid ON customer (PROGRESS_RECID);

CREATE SEQUENCE department_SEQ START WITH 1 increment BY 1;
CREATE TABLE department (
  prrowid varchar2(36) not null,
  deptcode varchar2(6) null,
  deptname varchar2(30) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX department##prrowid ON department (prrowid);
CREATE UNIQUE INDEX department##recid ON department (PROGRESS_RECID);

CREATE SEQUENCE employee_SEQ START WITH 1 increment BY 1;
CREATE TABLE employee (
  prrowid varchar2(36) not null,
  empnum number null,
  lastname varchar2(50) null,
  firstname varchar2(30) null,
  address varchar2(70) null,
  address2 varchar2(70) null,
  city varchar2(50) null,
  state varchar2(40) null,
  postalcode varchar2(20) null,
  homephone varchar2(40) null,
  workphone varchar2(40) null,
  deptcode varchar2(6) null,
  position varchar2(40) null,
  birthdate date null,
  startdate date null,
  vacationdaysleft number null,
  sickdaysleft number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX employee##prrowid ON employee (prrowid);
CREATE UNIQUE INDEX employee##recid ON employee (PROGRESS_RECID);

CREATE SEQUENCE family_SEQ START WITH 1 increment BY 1;
CREATE TABLE family (
  prrowid varchar2(36) not null,
  empnum number null,
  relativename varchar2(30) null,
  relation varchar2(30) null,
  birthdate date null,
  coveredonbenefits number null,
  benefitdate date null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX family##prrowid ON family (prrowid);
CREATE UNIQUE INDEX family##recid ON family (PROGRESS_RECID);

CREATE SEQUENCE feedback_SEQ START WITH 1 increment BY 1;
CREATE TABLE feedback (
  prrowid varchar2(36) not null,
  contact varchar2(60) null,
  company varchar2(40) null,
  emailaddress varchar2(100) null,
  phone varchar2(40) null,
  fax varchar2(40) null,
  comments varchar2(160) null,
  department varchar2(30) null,
  rating number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX feedback##prrowid ON feedback (prrowid);
CREATE UNIQUE INDEX feedback##recid ON feedback (PROGRESS_RECID);

CREATE SEQUENCE inventorytrans_SEQ START WITH 1 increment BY 1;
CREATE TABLE inventorytrans (
  prrowid varchar2(36) not null,
  invtransnum number null,
  warehousenum number null,
  binnum number null,
  qty number null,
  itemnum number null,
  transdate date null,
  invtype varchar2(24) null,
  ponum number null,
  ordernum number null,
  transtime varchar2(10) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX inventorytrans##prrowid ON inventorytrans (prrowid);
CREATE UNIQUE INDEX inventorytrans##recid ON inventorytrans (PROGRESS_RECID);

CREATE SEQUENCE invoice_SEQ START WITH 1 increment BY 1;
CREATE TABLE invoice (
  prrowid varchar2(36) not null,
  invoicenum number null,
  custnum number null,
  invoicedate date null,
  amount number null,
  totalpaid number null,
  adjustment number null,
  ordernum number null,
  shipcharge number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX invoice##prrowid ON invoice (prrowid);
CREATE UNIQUE INDEX invoice##recid ON invoice (PROGRESS_RECID);

CREATE SEQUENCE item_SEQ START WITH 1 increment BY 1;
CREATE TABLE item (
  prrowid varchar2(36) not null,
  itemnum number null,
  itemname varchar2(50) null,
  price number null,
  onhand number null,
  allocated number null,
  reorder number null,
  onorder number null,
  catpage number null,
  catdescription varchar2(4000) null,
  category1 varchar2(60) null,
  category2 varchar2(60) null,
  special varchar2(16) null,
  weight number null,
  minqty number null,
  itemimage BLOB null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX item##prrowid ON item (prrowid);
CREATE UNIQUE INDEX item##recid ON item (PROGRESS_RECID);

CREATE SEQUENCE localdefault_SEQ START WITH 1 increment BY 1;
CREATE TABLE localdefault (
  prrowid varchar2(36) not null,
  country varchar2(40) null,
  region1label varchar2(30) null,
  region2label varchar2(30) null,
  postallabel varchar2(30) null,
  postalformat varchar2(30) null,
  telformat varchar2(30) null,
  currencysymbol varchar2(12) null,
  dateformat varchar2(16) null,
  localdefnum number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX localdefault##prrowid ON localdefault (prrowid);
CREATE UNIQUE INDEX localdefault##recid ON localdefault (PROGRESS_RECID);

CREATE SEQUENCE order__SEQ START WITH 1 increment BY 1;
CREATE TABLE order_ (
  prrowid varchar2(36) not null,
  ordernum number null,
  custnum number null,
  orderdate date null,
  shipdate date null,
  promisedate date null,
  carrier varchar2(50) null,
  instructions varchar2(100) null,
  po varchar2(40) null,
  terms varchar2(40) null,
  salesrep varchar2(8) null,
  billtoid number null,
  shiptoid number null,
  orderstatus varchar2(40) null,
  warehousenum number null,
  creditcard varchar2(40) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX order_##prrowid ON order_ (prrowid);
CREATE UNIQUE INDEX order_##recid ON order_ (PROGRESS_RECID);

CREATE SEQUENCE orderline_SEQ START WITH 1 increment BY 1;
CREATE TABLE orderline (
  prrowid varchar2(36) not null,
  ordernum number null,
  linenum number null,
  itemnum number null,
  price number null,
  qty number null,
  discount number null,
  extendedprice number null,
  orderlinestatus varchar2(40) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX orderline##prrowid ON orderline (prrowid);
CREATE UNIQUE INDEX orderline##recid ON orderline (PROGRESS_RECID);

CREATE SEQUENCE poline_SEQ START WITH 1 increment BY 1;
CREATE TABLE poline (
  prrowid varchar2(36) not null,
  linenum number null,
  itemnum number null,
  price number null,
  qty number null,
  discount number null,
  extendedprice number null,
  ponum number null,
  polinestatus varchar2(40) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX poline##prrowid ON poline (prrowid);
CREATE UNIQUE INDEX poline##recid ON poline (PROGRESS_RECID);

CREATE SEQUENCE purchaseorder_SEQ START WITH 1 increment BY 1;
CREATE TABLE purchaseorder (
  prrowid varchar2(36) not null,
  ponum number null,
  dateentered date null,
  supplieridnum number null,
  receivedate date null,
  postatus varchar2(40) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX purchaseorder##prrowid ON purchaseorder (prrowid);
CREATE UNIQUE INDEX purchaseorder##recid ON purchaseorder (PROGRESS_RECID);

CREATE SEQUENCE refcall_SEQ START WITH 1 increment BY 1;
CREATE TABLE refcall (
  prrowid varchar2(36) not null,
  callnum varchar2(12) null,
  custnum number null,
  calldate date null,
  salesrep varchar2(8) null,
  parent varchar2(12) null,
  txt varchar2(4000) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX refcall##prrowid ON refcall (prrowid);
CREATE UNIQUE INDEX refcall##recid ON refcall (PROGRESS_RECID);

CREATE SEQUENCE salesrep_SEQ START WITH 1 increment BY 1;
CREATE TABLE salesrep (
  prrowid varchar2(36) not null,
  salesrep varchar2(8) null,
  repname varchar2(60) null,
  region varchar2(16) null,
  monthquota##1 number null,
  monthquota##2 number null,
  monthquota##3 number null,
  monthquota##4 number null,
  monthquota##5 number null,
  monthquota##6 number null,
  monthquota##7 number null,
  monthquota##8 number null,
  monthquota##9 number null,
  monthquota##10 number null,
  monthquota##11 number null,
  monthquota##12 number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX salesrep##prrowid ON salesrep (prrowid);
CREATE UNIQUE INDEX salesrep##recid ON salesrep (PROGRESS_RECID);

CREATE SEQUENCE shipto_SEQ START WITH 1 increment BY 1;
CREATE TABLE shipto (
  prrowid varchar2(36) not null,
  custnum number null,
  shiptoid number null,
  contact varchar2(60) null,
  address varchar2(70) null,
  address2 varchar2(70) null,
  city varchar2(50) null,
  state varchar2(40) null,
  postalcode varchar2(20) null,
  phone varchar2(40) null,
  comments varchar2(160) null,
  name varchar2(60) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX shipto##prrowid ON shipto (prrowid);
CREATE UNIQUE INDEX shipto##recid ON shipto (PROGRESS_RECID);

CREATE SEQUENCE state_SEQ START WITH 1 increment BY 1;
CREATE TABLE state (
  prrowid varchar2(36) not null,
  state varchar2(40) null,
  statename varchar2(40) null,
  region varchar2(16) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX state##prrowid ON state (prrowid);
CREATE UNIQUE INDEX state##recid ON state (PROGRESS_RECID);

CREATE SEQUENCE supplier_SEQ START WITH 1 increment BY 1;
CREATE TABLE supplier (
  prrowid varchar2(36) not null,
  supplieridnum number null,
  name varchar2(60) null,
  address varchar2(70) null,
  address2 varchar2(70) null,
  city varchar2(50) null,
  state varchar2(40) null,
  postalcode varchar2(20) null,
  country varchar2(40) null,
  phone varchar2(40) null,
  comments varchar2(160) null,
  password varchar2(16) null,
  logindate date null,
  shipamount number null,
  discount number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX supplier##prrowid ON supplier (prrowid);
CREATE UNIQUE INDEX supplier##recid ON supplier (PROGRESS_RECID);

CREATE SEQUENCE supplieritemxref_SEQ START WITH 1 increment BY 1;
CREATE TABLE supplieritemxref (
  prrowid varchar2(36) not null,
  supplieridnum number null,
  itemnum number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX supplieritemxref##prrowid ON supplieritemxref (prrowid);
CREATE UNIQUE INDEX supplieritemxref##recid ON supplieritemxref (PROGRESS_RECID);

CREATE SEQUENCE timesheet_SEQ START WITH 1 increment BY 1;
CREATE TABLE timesheet (
  prrowid varchar2(36) not null,
  empnum number null,
  dayrecorded date null,
  typerecorded varchar2(16) null,
  amtimein varchar2(10) null,
  amtimeout varchar2(10) null,
  pmtimein varchar2(10) null,
  pmtimeout varchar2(10) null,
  regularhours number null,
  overtimehours number null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX timesheet##prrowid ON timesheet (prrowid);
CREATE UNIQUE INDEX timesheet##recid ON timesheet (PROGRESS_RECID);

CREATE SEQUENCE vacation_SEQ START WITH 1 increment BY 1;
CREATE TABLE vacation (
  prrowid varchar2(36) not null,
  empnum number null,
  startdate date null,
  enddate date null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX vacation##prrowid ON vacation (prrowid);
CREATE UNIQUE INDEX vacation##recid ON vacation (PROGRESS_RECID);

CREATE SEQUENCE warehouse_SEQ START WITH 1 increment BY 1;
CREATE TABLE warehouse (
  prrowid varchar2(36) not null,
  warehousenum number null,
  warehousename varchar2(60) null,
  country varchar2(40) null,
  address varchar2(70) null,
  address2 varchar2(70) null,
  city varchar2(50) null,
  state varchar2(40) null,
  postalcode varchar2(20) null,
  phone varchar2(40) null,
  Pro2SrcPDB varchar2(12) null,
  pro2created date null,
  pro2modified date null,
  PROGRESS_RECID number null
);

CREATE UNIQUE INDEX warehouse##prrowid ON warehouse (prrowid);
CREATE UNIQUE INDEX warehouse##recid ON warehouse (PROGRESS_RECID);

commit;