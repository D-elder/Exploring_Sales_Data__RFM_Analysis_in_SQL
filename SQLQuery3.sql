---inspecting the data
select * from [dbo].[sales_data_sample]

--Checking unique values
select distinct Status from dbo.sales_data_sample
select distinct YEAR_ID from dbo.sales_data_sample
select distinct PRODUCTLINE from dbo.sales_data_sample
select distinct COUNTRY from dbo.sales_data_sample
select distinct DEALSIZE from dbo.sales_data_sample
select distinct TERRITORY from dbo.sales_data_sample


--Analysis
--Grouping Sales by productLine
select productline, sum(sales) revenue
from [dbo].[sales_data_sample]
Group by PRODUCTLINE
order by 2 desc ---Query shows that Classsic cars have the highest sales


--Checking the Year with most sales
select YEAR_ID, sum(sales) revenue
from [dbo].[sales_data_sample]
Group by YEAR_ID
order by 2 desc---2004

select DEALSIZE, sum(sales) revenue
from [dbo].[sales_data_sample]
Group by DEALSIZE
order by 2 desc---medium


--What was the best month for sale in a specific year? And how much was made that month?

Select month_id, sum(sales) Revenue, count(ordernumber) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2003 --specific year(I can change the year to see the rest)
group by MONTH_ID
order by 2 desc

--November seems to be the month the make more sales

Select month_id, productline, sum(sales) Revenue, count(ordernumber) Frequency
from [dbo].[sales_data_sample]
where YEAR_ID = 2003 and  month_id = 11 --specific year(I can change the year to see the rest)
group by MONTH_ID, productline
order by 3 desc



---who is our best customer? This can be best answered using RFM analysis

DROP TABLE IF EXISTS #rfm
;with rfm as 
(  
    select
		CUSTOMERNAME,
		SUM(SALES) MONETARYVALUE,
		AVG(SALES) AVGMONETARYVALUE,
		COUNT(ORDERNUMBER) FREQUENCY,
		MAX(ORDERDATE) LAST_ORDER_DATE,
		(SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample]) AS max_order_date,
		DATEDIFF(DD, max(orderdate), (SELECT MAX(ORDERDATE) FROM [dbo].[sales_data_sample])) Recency
	from [dbo].[sales_data_sample]
	group by CUSTOMERNAME
),
rfm_calc as 
(
	select r. *,
		--grouping into 4 buckets using the NTILE FUNCTION
		NTILE(4) OVER (ORDER BY Recency desc) rfm_recency,
		NTILE(4) OVER (ORDER BY Frequency) rfm_frequency,
		NTILE(4) OVER (ORDER BY MONETARYVALUE) rfm_monetary -- with 1 being the lowest and 4 the highest for Recency, Frequency and Monetary Value.
from rfm r
)
Select 
	c.*, rfm_recency+ rfm_frequency+ rfm_monetary as rfm_cell,
	cast(rfm_recency as varchar) + cast(rfm_frequency as varchar) + cast(rfm_monetary as varchar)rfm_string
into #rfm
from rfm_calc c



--Segmenting the customers into classes


Select 
	CUSTOMERNAME, rfm_recency, rfm_frequency,  rfm_monetary,
	CASE
		when rfm_string in (111, 112, 121, 122, 123, 132, 211, 212, 141, 114) then 'Lost Customers'
		when rfm_string in (133, 134, 143, 244, 334, 343, 344, 233, 234, 144) then 'Slipping Away, Cannot lose'
		when rfm_string in (311, 411, 331, 412) then 'New Customers'
		when rfm_string in (222, 223, 322, 221, 232) then 'potential churners'
		when rfm_string in (323, 333, 321, 422 , 332, 432, 421) then 'Active'
		when rfm_string in (433, 434, 443, 444, 423) then 'Loyal'
	end rfm_segment

from #rfm