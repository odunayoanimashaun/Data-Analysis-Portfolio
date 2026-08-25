--Display All Records From The Table
select* 
from customers

select* from orders

-- Display customer name,city,orderdate and amount
select customer_name,city,order_date,amount
from customers c
join orders o
on c.customer_id= o.customer_id 

--Customers who never placed an order
select c.customer_id,c.customer_name
from customers c
left join orders o
on c.customer_id = o.customer_id
where o.order_id is null


--Number of orders by each customer

select c.customer_name,count(o.customer_id) as total_sales
from customers c
left join orders o
on c.customer_id = o.customer_id
group by c.customer_name

--Total Amount spent by each customer

select c.customer_name, sum(o.amount) as totalamount
from customers c
join orders o
on c. customer_id = o.customer_id
group by c.customer_name;

--Average order amountby city
select c.city,AVG(o.amount) as avg_order
from customers c
join orders o
on c.customer_id=o.customer_id
group by c.city

--Top 3 by cities

SELECT TOP 3 c.city, SUM(o.amount) AS Total_Sales
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.city
ORDER BY Total_Sales desc

--Classify orders
SELECT order_id, amount,
CASE WHEN amount < 50000 THEN 'Small'
WHEN amount BETWEEN 50000 AND 100000 THEN 'Medium' 
ELSE 'Large' END AS Order_Size 
FROM orders

--classify customers total amount spent
SELECT c.customer_name, SUM(o.amount) AS Total_Spent,
CASE 
WHEN SUM(o.amount) > 500000 THEN 'High Value'
WHEN SUM(o.amount) BETWEEN 200000 AND 500000 THEN 'Medium Value'
ELSE 'Low Value' 
END AS Customer_Category
FROM customers c
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name;

--using cte customers spending above average
WITH CustomerSpend AS
(
SELECT customer_id, SUM(amount) AS Total_Spent
FROM orders 
GROUP BY customer_id
)
SELECT * FROM CustomerSpend
WHERE Total_Spent >
(
SELECT AVG(Total_Spent) 
FROM CustomerSpend
)

--using cte customers spending above average

with customerspend as
(select customer_id,sum(o.amount) as totalspent
from orders o
group by customer_id)
SELECT * FROM CustomerSpend
WHERE totalspent >
(select avg(totalspent)
from customerspend)

--Highest single order

SELECT TOP 1 c.customer_name, o.amount
FROM customers  c
JOIN orders o ON c.customer_id = o.customer_id
ORDER BY o.amount DESC

--cte for customers above 300,00
with customersales as
(
select customer_id,sum(o.amount) as totalsales
from orders o
group by customer_id
)
select *
from customersales
where totalsales >300000
 
--Rank cities by revenue(using common table expressions)
with citysales as
(
   SELECT c.city,sum(o.amount) as Revenue
   from customers c
   join orders o
   on c.customer_id=o.customer_id
   group by c.city
)
   select rank() over(order by Revenue DESC) as Ranking
   from citysales
          
-- Rank citysales---without cte 
SELECT city,SUM(o.amount) as Revenue,
  rank()over(order by sum(o.amount)desc) as ranking
  from customers c
  join orders o on c.customer_id=o.customer_id
  group by city

  --RANK CUSTOMERS,
  SELECT c.customer_name,SUM(o.amount) as totalspent,
  rank()over(order by sum(o.amount)desc) as ranking
  from customers c
  join orders o on c.customer_id=o.customer_id
  group by customer_name

  --Top 5 customers
  select top 5 c.customer_name,sum(o.amount) as customerrank,
  rank()over(order by sum(o.amount) desc) as ranking
  from customers c
  join orders o
  on c.customer_id=o.customer_id
  group by c.customer_name;
   
   
   --OR
  WITH CustomerRank AS 
  (
SELECT c.customer_name, SUM(o.amount) AS Total_Spent,
RANK() OVER(ORDER BY SUM(o.amount) DESC) AS Ranking
FROM customers c 
JOIN orders o
ON c.customer_id = o.customer_id
GROUP BY c.customer_name
  )
SELECT *
FROM CustomerRank WHERE Ranking <= 5

  --row number by order date
select order_id,order_date,
ROW_NUMBER() over(order by order_date) as row_num
from orders;

  --most recent order per  customer
  with recentorders as
  (
  select*,
  ROW_NUMBER ()over (partition by customer_id order by order_date DESC) as rn
  from orders
  )
  select*
  from recentorders
  where rn =1;

  
  --running total of sales
  select order_date,amount,
  SUM(amount) over (order by order_date) as running_total
  from orders

  --percentage contribution
  select customer_id,sum(amount) as totalsales,
  round(sum (amount)*100.0/sum(sum(amount))over(),2)as percentage
  from orders
  group by customer_id

  --previous order amount
  select customer_id,order_date,amount,
  LAG(amount)over (partition by customer_id order by order_date) as previous_order
  from orders

  --create a view
  create view 
  vw_customer_sales as 
  select c.customer_id,c.customer_name,c.city,SUM(o.amount) as totalspent
  from customers c
  join orders o
  on o.customer_id=c.customer_id
  group by c.customer_id,customer_name,c.city;

   
  --top 10 customers
  select top 10*
  from vw_customer_sales
  order by totalspent DESC
  --stored procedure by city
  create procedure Getcustomerbycity
  @city varchar(50)
  as
  BEGIN
  select*
  from customers
  where city=@city;
  end;
  --run it
  exec Getcustomerbycity 'lagos'

  --sales between dates
  CREATE PROCEDURE GetSales
@StartDate DATE,
@EndDate DATE
AS
BEGIN
SELECT SUM(amount) AS Total_Sales
FROM orders
WHERE order_date BETWEEN @StartDate AND @EndDate;
END;
--run it
exec GetSales '2025-01-01','2025-06-30';

  --dashboard metrics
SELECT
(SELECT COUNT(*) FROM customers) AS Total_Customers,
(SELECT COUNT(*) FROM orders) AS Total_Orders,
(SELECT SUM(amount) FROM orders) AS Total_Revenue,
(SELECT AVG(amount) FROM orders) AS Avg_Order_Value,
(SELECT MAX(amount) FROM orders) AS Highest_Order
