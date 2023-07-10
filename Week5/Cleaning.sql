use data_mart;
DROP TABLE IF EXISTS clean_weekly_sales;
CREATE temporary TABLE clean_weekly_sales AS (
SELECT
  STR_TO_DATE(week_date, '%d/%m/%y') AS week_date,
  WEEK(STR_TO_DATE(week_date, '%d/%m/%y')) AS week_number,
  MONTH(STR_TO_DATE(week_date, '%d/%m/%y')) AS month_number,
  YEAR(STR_TO_DATE(week_date, '%d/%m/%y')) AS calendar_year,
  region, 
  platform, 
  segment,
  CASE 
    WHEN RIGHT(segment,1) = '1' THEN 'Young Adults'
    WHEN RIGHT(segment,1) = '2' THEN 'Middle Aged'
    WHEN RIGHT(segment,1) in ('3','4') THEN 'Retirees'
    ELSE 'unknown' END AS age_band,
  CASE 
    WHEN LEFT(segment,1) = 'C' THEN 'Couples'
    WHEN LEFT(segment,1) = 'F' THEN 'Families'
    ELSE 'unknown' END AS demographic,
  transactions,
  ROUND((CAST(sales AS DECIMAL) / transactions), 2) AS avg_transaction,
  sales
FROM data_mart.weekly_sales
);
