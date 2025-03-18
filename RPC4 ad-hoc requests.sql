-- Request - 1 

select distinct market 
from dim_customer 
where customer = "Atliq Exclusive" and region = "APAC";

-- Requesst - 2

with grouped_by_yrs as (
	select fiscal_year,
		count(distinct product_code) as unique_products 
    from fact_gross_price 
    group by fiscal_year  -- 334 - 245
),
pivoted_tbl as (
	select 
		sum(case when fiscal_year = 2021 then unique_products end) as  unique_products_2021,
		sum(case when fiscal_year = 2020 then unique_products end) as  unique_products_2020
	from grouped_by_yrs
)
select * ,
	(unique_products_2021 -unique_products_2020) *100/unique_products_2020 as pct_change 
from pivoted_tbl;

-- Request - 3

with unique_products_by_seg as(
	select segment ,
		count(distinct product_code) as cnt 
	from dim_product 
	group by segment
)
select * 
from unique_products_by_seg 
order by cnt desc;

-- Request - 4 

with grouped_by_yrs as (
	select segment, fiscal_year,
		count(distinct g.product_code) as unique_products 
    from fact_gross_price g join dim_product p 
    on g.product_code = p.product_code
    group by segment, fiscal_year  
),
pivoted_tbl as (
	select segment,
		sum(case when fiscal_year = 2021 then unique_products end) as  unique_products_2021,
		sum(case when fiscal_year = 2020 then unique_products end) as  unique_products_2020
	from grouped_by_yrs 
    group by segment
)
select * ,
	(unique_products_2021 -unique_products_2020) as diff 
from pivoted_tbl 
order by diff desc ;

-- Request - 5 

select m.product_code ,product, m.manufacturing_cost 
from dim_product p join fact_manufacturing_cost m
on p.product_code = m.product_code 
where manufacturing_cost 
in 	((select min(manufacturing_cost) from fact_manufacturing_cost),
	(select max(manufacturing_cost) from fact_manufacturing_cost));
    
-- Request - 6 

select p.customer_code, 
max(customer) as customer ,
round(avg(pre_invoice_discount_pct)*100,2) as avg_discount_pct 
from dim_customer c
join fact_pre_invoice_deductions p 
on c.customer_code = p.customer_code 
where market = "india" and fiscal_year = 2021 
group by customer_code
order by avg_discount_pct desc
limit 5;

-- Request - 7

select concat(monthname(date),'-' ,year(date)) as month ,
s.fiscal_year ,
sum(gross_price* sold_quantity) as gross_sales 
from fact_sales_monthly s 
join fact_gross_price g on s.product_code = g.product_code 
join dim_customer c on c.customer_code = s.customer_code
where customer = "Atliq Exclusive" 
group by month ,s.fiscal_year order by s.fiscal_year ;




SELECT CONCAT(MONTHNAME(FS.date), ' (', YEAR(FS.date), ')') AS 'Month', FS.fiscal_year,
       ROUND(SUM(G.gross_price*FS.sold_quantity), 2) AS Gross_sales_Amount
FROM fact_sales_monthly FS JOIN fact_gross_price G ON FS.product_code = G.product_code
						   JOIN dim_customer C ON FS.customer_code = C.customer_code 
WHERE C.customer = 'Atliq Exclusive'
GROUP BY  Month, FS.fiscal_year 
ORDER BY FS.fiscal_year ;


select monthname(date) as month  ,
sum(gross_price* sold_quantity) as gross_sales 
from fact_sales_monthly s 
join fact_gross_price g
on  s.product_code = g.product_code 
join dim_customer c 
on c.customer_code = s.customer_code
where customer = "Atliq Exclusive" 
and s.fiscal_year = 2020
group by monthname(date);

-- 9092670  -- 
WITH temp_table AS (
    SELECT customer,
    monthname(date) AS months ,
    month(date) AS month_number, 
    year(date) AS year,
    (sold_quantity * gross_price)  AS gross_sales
 FROM fact_sales_monthly s JOIN
 fact_gross_price g ON s.product_code = g.product_code
 JOIN dim_customer c ON s.customer_code=c.customer_code
 WHERE customer="Atliq exclusive"
)
SELECT months,year, concat(round(sum(gross_sales)/1000000,2),"M") AS gross_sales FROM temp_table
GROUP BY year,months,month_number
ORDER BY year,month_number;

-- Request - 8

select 
case when month(adddate(date, interval 4 month)) between 1 and 3 then "Q1" 
	 when month(adddate(date, interval 4 month)) between 4 and 6 then "Q2" 
     when month(adddate(date, interval 4 month)) between 7 and 9 then "Q3" 
     when month(adddate(date, interval 4 month)) between 10 and 12 then "Q4" 
end as quarter ,
sum(sold_quantity) as total_sold_qty
from fact_sales_monthly 
where fiscal_year = 2020 
group by quarter 
order by total_sold_qty desc ;
	
-- Request - 9 

with cte1 as(
	select c.channel ,sum(sold_quantity * gross_price) as gross_sales_mill 
	from fact_sales_monthly s 
	join fact_gross_price g on g.product_code = s.product_code 
	join dim_customer c on c.customer_code = s.customer_code
	where s.fiscal_year = 2021
	group by c.channel
)
select * ,
(gross_sales_mill * 100 )/sum(gross_sales_mill) over() as pct 
from cte1 ;

-- Request - 10

with cte1 as (
	select division ,s.product_code ,product ,sum(sold_quantity) as total_sold_qty  from fact_sales_monthly s 
	join dim_product p
	on p.product_code = s.product_code 
	where fiscal_year = 2021 
	group by division ,s.product_code ,product
),
cte2 as (
	select * ,
	dense_rank() over(partition by division order by total_sold_qty desc) as rnk 
	from cte1 
)
select * from cte2 where rnk <=3;