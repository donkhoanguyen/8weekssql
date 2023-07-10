select * from clean_weekly_sales;

-- 1. What day of the week is used for each week_date value?
SELECT DISTINCT(WEEKDAY(week_date)) AS week_day 
FROM clean_weekly_sales;

-- -----
-- 2. What range of week numbers are missing from the dataset?
WITH RECURSIVE cte AS (
  SELECT 1 AS week_indices
  UNION ALL
  SELECT week_indices + 1
  FROM cte
  WHERE week_indices < 52
)

select distinct cte.week_indices
from cte
left join clean_weekly_sales as a on cte.week_indices = a.week_number
where a.week_number is null;


-- -----
-- 3. How many total transactions were there for each year in the dataset?
select sum(transactions) as transactions_by_year,
	calendar_year
from clean_weekly_sales
group by calendar_year;


-- -----
-- 4. What is the total sales for each region for each month?
select region,
	calendar_year,
    month_number,
	sum(sales) as total_sales_by_month_n_regions
from clean_weekly_sales
group by region, calendar_year, month_number;



-- -----
-- 5. What is the total count of transactions for each platform
select platform,
	sum(transactions) as total_transactions_by_platform
from clean_weekly_sales
group by platform;



-- -----
-- 6. What is the percentage of sales for Retail vs Shopify for each month?
select * from clean_weekly_sales;

with transactions_bymonth as (
	select 
		calendar_year,
        month_number, 
		platform, 
		SUM(sales) as monthly_sales
	from clean_weekly_sales
    group by calendar_year, month_number, platform
)

select calendar_year,
	month_number, 
    round(100 * MAX(
		case when platform = 'Retail' then monthly_sales else null end)/SUM(monthly_sales)
		,2) as retail_percentage,
	round(100 * MAX(
		case when platform = 'Shopify' then monthly_sales else null end)/SUM(monthly_sales)
		,2) as shopify_percentage
from transactions_bymonth
group by calendar_year, month_number
order by calendar_year, month_number;



-- -----
-- 7. What is the percentage of sales by demographic for each year in the dataset?
WITH demographic_sales AS (
  SELECT 
    calendar_year, 
    demographic, 
    SUM(sales) AS yearly_sales
  FROM clean_weekly_sales
  GROUP BY calendar_year, demographic
)

SELECT 
  calendar_year, 
  ROUND(100 * MAX(CASE 
      WHEN demographic = 'Couples' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS couples_percentage,
  ROUND(100 * MAX(CASE 
      WHEN demographic = 'Families' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS families_percentage,
  ROUND(100 * MAX(CASE 
      WHEN demographic = 'unknown' THEN yearly_sales ELSE NULL END)
    / SUM(yearly_sales),2) AS unknown_percentage
FROM demographic_sales
GROUP BY calendar_year;



-- -----
-- 8. Which age_band and demographic values contribute the most to Retail sales?
select * from clean_weekly_sales;
select age_band,
	demographic,
    sum(sales),
    round(100 * sum(sales) / sum(sum(sales)) OVER (), 1) AS contribution_percentage
from clean_weekly_sales
group by age_band, demographic
order by contribution_percentage desc;



-- -----
-- 9. Can we use the avg_transaction column to find the average transaction size for each year for Retail vs Shopify? If not - how would you calculate it instead?
select 
	calendar_year, 
    platform, 
    AVG(avg_transaction) as avg_by_row,
    sum(sales)/sum(transactions) as avg_by_group
from clean_weekly_sales
group by calendar_year, platform
order by calendar_year, platform;


        
