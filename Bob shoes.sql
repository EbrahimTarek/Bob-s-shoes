use master
Go
create database Bobshoes
Go
--show the entry for bobshoes in the system tables ;
	select * from sys.databases where name = 'Bobshoes'
--show the layout of the files for the database
	sp_helpfile
--create schema for bob orders 
	create schema orders
--Create new file group for data and logs
	alter database Bobshoes
	add FILEGROUP Bobsdata

	alter database bobshoes
	add file ( name = bobsdata , filename = 'D:\Case Study\BobsData.mdf' )	
	To filegroup BobsData

	alter database Bobshoes
	add log file ( name = bobslogs , filename = 'D:\Case Study\BobsData.ldf' )	
--create order tracking table
	Use Bobshoes
	create table Orders.Ordertracking(
	orderid int identity(1,1),
	orderdate datetime2(0) not null ,
	Requestedate datetime2(0)not null,
	Deliverydate datetime2(0) NULL,
	CustName nvarchar(200) not null,
	CustAddress nvarchar(200) not null,
	shoeStyle varchar(200) not null,
	shoeSize varchar(10) not null,
	Sku char(8) not null ,
	UnitPrice int not null,
	Quantity smallint not null,
	Discount numeric(4,2) not null,
	IsExpedited bit not null ,
	TotalPrice as ( Quantity * unitprice * (1 - Discount )) , --persisted
	)
	on bobsData --filegroup
	With (Data_compression = page ); 	--page level compression and Row level expression is also available
	Go
	select * from orders.Ordertracking
--Using Collation
 --show the collation configured on the instance
 select SERVERPROPERTY ('collation') as default_instance_collation_name
 --show the collation configured on the database
  select DatabasePROPERTY (DB_NAME(),'collation') as DAtabase_collation_name
 --show the collation for all columns in the ordertracking table 
 select name as columnname , collation_name as columncollation from sys.columns 
 where object_id = object_id(N'orders.Ordertracking')
 --show the description for the collation
 select name , description 
 from sys.fn_helpcollations()
 where name = N'Arabic_CI_AS'
 --show sql collations not containing 'latinl'
 select name , description 
 from sys.fn_helpcollations()
 where name like N'Sql%' and name not like N'Sql_latin%'
 --change the customer column to a Scandinavian collation
 alter table orders.ordertracking
	alter column custname nvarchar(200)
		collate SQl_Scandinavian_cp850_CI_AS
		Not Null
--Database Normalization
  --1st normal form 
  drop table orders.ordertracking
  select * from orders.ordertracking
create table orders.Customers
	 (CustID int identity(1,1) not null primary key 
	, CustName varchar(100) not null
	, Custstreet varchar(100) not null
	, CustCity varchar(100) not null
	, CustCountry varchar(100) not null 
	, Custpostalcode varchar(10) not null)

create table orders.Stock
	(STockSku char(8) not null,
	 StockSize varchar(10) not null,
	 StockName varchar(100) not null,
	 StockPrice decimal(5,2) not null,
	 constraint sp_sK primary key (STockSku,StockSize))

create table Orders.Orders
	(Order_id int identity(1,1) not null primary key,
	 orderdate date not null ,
	 Requesteddate date not null,
	 Deliverydate datetime2(0) not null,
	 CustID int not null,
	 OrderIsExpedited bit not null )

Create table Orders.OrderItems
	( OrderItemID int identity(1,1) not null primary key,
	  OrderId int not null ,
	  StockSku char(8) not null ,
	  StockSize varchar(10) not null ,
	  Quantity smallint not null,
	  Discount decimal(4,2) not null )
select * from orders.Customers
select * from orders.Stock
insert into orders.Stock ( STockSku , StockName , StockSize , StockPrice ) values
('Oxford01','Oxford','10_D',50),
('BABYSHD1','BabySneakers','3',20),
('HeelS001','Killer Heels','7',75)
select * from orders.Orders
insert into orders.Orders (orderdate , Requesteddate , CustID , OrderIsExpedited ) values
('20190301','20190401',1,0),
('20190301','20190401',2,0)
insert into orders.OrderItems (OrderId ,stockid, Quantity , Discount ) values
(1,1,1,0),
(2,3,1,0)
--2nd normal form
drop table if exists  orders.Customers,orders.Stock , orders.OrderItems , orders.Orders
	create table orders.Customers
	 (CustID int identity(1,1) not null primary key 
	, CustName varchar(100) not null
	, Custstreet varchar(100) not null
	, CustCity varchar(100) not null
	, CustCountry varchar(100) not null 
	, Custpostalcode varchar(10) not null
	, salutationID int not null)

create table orders.Stock
	(Stockid int not null identity(1,1) primary key --Surrogate Key
	 ,STockSku char(8) not null,
	 StockSize varchar(10) not null,
	 StockName varchar(100) not null,
	 StockPrice decimal(5,2) not null)

create table Orders.Orders
	(Order_id int identity(1,1) not null primary key,
	 orderdate date not null ,
	 Requesteddate date not null,
	 Deliverydate datetime2(0) not null,
	 CustID int not null,
	 OrderIsExpedited bit not null )

Create table Orders.OrderItems
	( OrderItemID int identity(1,1) not null primary key,
	  OrderId int not null ,
	  Stockid int not null ,
	  Quantity smallint not null,
	  Discount decimal(4,2) not null )

--3rd normal from
	drop table if exists orders.salutations , orders.Customers
	create table orders.salutations(
	salutationID int not null identity(1,1) primary key,
	Salutation varchar(5) not null )

	create table orders.Customers
	(CustID int identity(1,1) not null primary key 
	 ,CustName varchar(100) not null
	 ,salutationID int not null constraint sp_fk references orders.salutations(salutationID),
	 addressid int not null constraint ad_fk references orders.Customeraddress(addressid))
		
		create table  orders.Customeraddress
		(addressid int identity(1,1) not null primary key 
	    , Custstreet varchar(100) not null
	   , CustCity varchar(100) not null
	   , CustCountry varchar(100) not null 
	   , Custpostalcode varchar(10) not null)
	
--Ensuring Data Integrity with constraints
 --add default constraint for the order date 
	alter table orders.orders
	add constraint df_date default getdate() for orderdate

--add default constraint for the expedited flag
	alter table orders.orders
	add constraint df_exped default 0 for orderisexpedited

--primary key and unique constraints
	create table orders.salutations(
	salutationID int not null identity(1,1) Unique Clustered,
	Salutation varchar(5) not null 
	constraint UQ_Sa primary key nonclustered)

	create table orders.Stock
	(Stockid int not null identity(1,1) primary key --Surrogate Key
	 ,STockSku char(8) not null,
	 StockSize varchar(10) not null,
	 StockName varchar(100) not null,
	 StockPrice decimal(5,2) not null,
	 constraint uq_susk unique nonclustered (STockSku,StockSize)
	 )

-- Cascading referential integrity constraint 
	Create table Orders.OrderItems
	( OrderItemID int identity(1,1) not null primary key,
	  OrderId int not null ,
	  Stockid int not null ,
	  Quantity smallint not null,
	  Discount decimal(4,2) not null,
	  constraint fK_Sd foreign key references Orders.stock (StockId) 
	  on delete cascade)

--Define check constraint on the salutaion column 
	alter table orders.salutations
	add constraint Ck_salutations_must_not_be_empty check (salutation <> '')

--add constraint restricting customer's country
	alter table orders.customer
	add constraint CK_country check (CustCountry in ( 'US','Uk','CA'))

--create a view to return a list of customers with their salutations name , addresses 
	create or alter view orders.customerlist
	with schemabinding
	As
		select custid, CustName ,Salutation, Custstreet , CustCity , CustCountry , Custpostalcode
		from orders.Customers C , orders.Customeraddress Ad , orders.salutations S
		where C.addressid = Ad.addressid
		and C.salutationID = S.salutationID

	select * from orders.customerlist
--update the customer table through the view
	update orders.customerlist
	set name = 'Trillian Dent'
	where name = 'Trillian Astra'


--crate a unique clustered index on the view 
create unique clustered index UQ_customer
on orders.customerlist(custid)

--Query the view
	select CustID , CustName , Salutation , CustCity
	from orders.customerlist
	where CustID = 1

-- create a non clustered index on the view
	drop index if exists IX_postalcode on orders.customerlist
	create nonclustered index IX_postalcode_Name on orders.customerlist(custname,custpostalcode)
	select * 
	from orders.customerlist
	option (expand views)
	
-- create a view
	create or alter view orders.ordersummary
	with schemabinding
	as
		select o.Order_id , orderdate ,o.OrderIsExpedited --iif (o.OrderIsExpedited = 1 , 'Yes' ,'No' ) as expedited 
		,CustName , sum(I.Quantity) totalquantity , COUNT_BIG(*) as Cb
		from orders.Orders O , orders.Customers C , orders.OrderItems I 
		where O.CustID = C.CustID
		and O.Order_id = I.OrderId
		group by o.Order_id , orderdate , o.OrderIsExpedited  , CustName

--create the first index 
	create unique clustered index IX_orderid
	on orders.ordersummary(Order_id)

--creating partitioned views
	--drop any existing orders table and views
drop table if exists orders.orders2018 , orders.Orders , orders.OrderItems
drop view if exists	orders.ordersummary , orders.customerlist , orders.partitionedorders

create table orders.orders
	(orderid int not null identity(1,1) --was a primary key
	,orderyear smallint not null        --new partitioning column 
	constraint CK_orders_current 
		check (orderyear between '2019' and '2020')
	,orderdate date not null
	,orderrequesteddate date not null
	,orderDeliveryDate datetime2(0) not null
	,custiD int not null 
		constraint fk_customer 
		foreign key references orders.customers(CustID)
	,OrderIsexpedited bit not null
		constraint Fk_CS default(0)
		,constraint CK_orderIS 
			check(orderrequesteddate >= orderdate )
		,constraint CK_deliverydate
			check (orderDeliveryDate >= orderdate)
		,constraint PK_orders	
			primary key(orderyear,orderid)










