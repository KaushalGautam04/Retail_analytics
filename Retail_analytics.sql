-- Assignment-2  Retail_analytics 
select * from customers
select * from employees 
select * from order_items
select * from orders
select * from products 
select * from 

1 . -- List delivered orders placed between 1 October 2024 and 31 March 2025, showing order_id, order_date, customer_id, and payment_method. Sort by order_date descending
select
order_id ,order_date ,customer_id ,payment_method 
from orders 
where order_status = 'Delivered'
And order_date between '2024-10-01' And '2025-03-31'
order by order_date Desc;

2-- Display each delivered order with customer_name, order_id, order_date, employee_name, and order_status. Include only orders with matching customer and employee records.
select 
c.customer_name, o.order_id, o.order_date, e.employee_name, o.order_status
from orders o
join customers c
on o.customer_id = c.customer_id
join employees e
on o.employee_id = e.employee_id
where o.order_status = 'Delivered';

3.--For each product category, calculate total units sold and net revenue from delivered orders. Show only categories with net revenue greater than ₹10,000; sort by net revenue descending.
select
p.category,
sum (oi.quantity) as total_units_sold,
sum (oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) as net_revenue
from orders o
join order_items oi on o.order_id = oi.order_id
join products p on oi.product_id = p.product_id
where o.order_status = 'Delivered'
group by  p.category
having sum (oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) > 10000
order by net_revenue desc;

4.-- Find customers who have placed at least two delivered orders. Show customer_id, customer_name, number of delivered orders, and total net spend.
select 
c.customer_id, c.customer_name,
count(distinct o.order_id) as total_orders,
sum(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) as total_net_spend
from customers c
join orders o on c.customer_id = o.customer_id
join  order_items oi on o.order_id = oi.order_id
where o.order_status = 'Delivered'
group by c.customer_id, c.customer_name
having count(distinct o.order_id) >= 2
order by  total_net_spend desc;

5.-- List all customers and the number of delivered orders each has placed, including customers with zero delivered orders.
select 
c.customer_id, c.customer_name,
count (o.order_id) as total_delivered_orders
from customers c
left join orders o
on c.customer_id = o.customer_id
and o.order_status = 'Delivered'
group by c.customer_id, c.customer_name
order by total_delivered_orders desc ;

6. -- Find products whose unit_price is greater than the average unit_price of all products. Display product name, category, unit price, and the overall average price.
select
product_name, category, unit_price,
(select avg (unit_price)
from products) as average_price
from products
where unit_price > 
(select avg(unit_price) from products);

7. -- Find customers who have never placed a delivered order. Return their customer_id, customer_name, and city.
select
customer_id, customer_name, city 
from  customers
where  not exists 
(select 1 from where order.customer_id = customer . customer_id 
and orders .order_status = 'Delivered' ) ;

8. -- Group delivered orders by year and month, showing the number of orders and net revenue for each month. Sort chronologically.
select
extract ( year from o.order_date) as order_year,
extract(month from o.order_date) as order_month,
count(distinct o.order_id) as total_orders,
sum(oi.quantity * oi.unit_price_at_sale*(1 - oi.discount_rate)) as net_revenue
from orders o
join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'Delivered'
group by extract(year from o.order_date),
extract(month from o.order_date)
order by order_year asc, order_month asc ;

9. -- Classify each product as 'Low Stock' when stock_quantity < 20, 'Moderate Stock' when stock_quantity is between 20 and 40 inclusive, and 'High Stock' when stock_quantity > 40. Display product_name, stock_quantity, and stock label.
select 
product_name, stock_quantity,
case when stock_quantity < 20 Then 'Low Stock'
when  stock_quantity between  20 and  40 then 'Moderate Stock'
when stock_quantity > 40 then 'High Stock'
end as stock_label 
from products;

10. -- For each employee, calculate delivered, returned, and cancelled order counts using conditional aggregation. Include employees with no orders.
SELECT e.employee_id, e.employee_name,
COUNT(o.order_id)
FILTER (WHERE o.order_status = 'Delivered')
AS delivered_orders,
COUNT(o.order_id) 
FILTER (WHERE o.order_status = 'Returned') AS returned_orders,
COUNT(o.order_id)
FILTER (WHERE o.order_status = 'Cancelled') AS cancelled_orders
FROM employees e
LEFT JOIN orders o
ON e.employee_id = o.employee_id
GROUP BY e.employee_id, e.employee_name
ORDER BY e.employee_id;

Q11.-- Rank products within each category by net revenue from delivered orders, highest first. Show category, product_name, net revenue, and rank. Products with no delivered sales should still be eligible to appear with zero revenue.
select p.category, p.product_name,
coalesce(sum (oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)),0)as net_revenue,
rank ()over (partition by p.category 
order by coalesce(sum(oi.quantity * oi.unit_price_at_sale *(1 - oi.discount_rate)),0) desc) as product_rank
from products p
left join order_items oi
on p.product_id = oi.product_id
left join orders o
on oi.order_id = o.order_id
and o.order_status = 'Delivered'
group by p.product_id, p.category, p.product_name 
order by p.category, product_rank;

Q12 -- For each month, calculate delivered-order net revenue and a cumulative running total of revenue across months in chronological order
with monthly_revenue as (
select 
extract( year from o.order_date) as  order_year,
extract(month from o.order_date) as  order_month,
sum (oi.quantity * oi.unit_price_at_sale *(1 - oi.discount_rate))  as net_revenue
from orders o
join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'Delivered'
group by
extract (year from o.order_date),
extract (month from o.order_date))
select order_year, order_month, net_revenue,
sum(net_revenue) over ( order by order_year, order_month) as running_total
from monthly_revenue
order by order_year, order_month;

Q13-- List each returned order with customer name, return date, return reason, and the total pre-discount value of its order items.
select c.customer_name, r.return_date, r.return_reason,
sum(oi.quantity * oi.unit_price_at_sale) as total_order_value
from returns r
join orders o
on r.order_id = o.order_id
join customers c
on o.customer_id = c.customer_id
join order_items oi
on o.order_id = oi.order_id
group by r.order_id, c.customer_name, r.return_date, r.return_reason
order by  r.return_date;

Q.14 -- Using a CTE, calculate net revenue per customer from delivered orders, then return customers whose net revenue is above the average customer net revenue. State whether the average is calculated across all customers or only customers with delivered purchases.
with customer_revenue as (
select c.customer_id,c.customer_name,
sum (oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) as net_revenue
from customers c
join orders o
on c.customer_id = o.customer_id
join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'Delivered'
group by c.customer_id, c.customer_name)
select customer_id, customer_name, net_revenue
from customer_revenue
where net_revenue > (
select avg (net_revenue)
from customer_revenue) 
order by net_revenue desc;

Q15-- Identify the top three customers by delivered net spend. Show customer name, number of delivered orders, net spend, and each customer's percentage contribution to total delivered net revenue
with customer_spending as (
select c.customer_id, c.customer_name,
count (distinct o.order_id) AS total_orders,
sum(oi.quantity * oi.unit_price_at_sale * (1 - oi.discount_rate)) AS net_spend
from  customers c
join orders o
on  c.customer_id = o.customer_id
join order_items oi
on o.order_id = oi.order_id
where o.order_status = 'Delivered'
group by c.customer_id, c.customer_name)
select customer_name, total_orders, net_spend,ROUND
(net_spend * 100.0 / sum(net_spend) over (),2) as contribution_percentage
from customer_spending
order by net_spend desc 
limit 3;