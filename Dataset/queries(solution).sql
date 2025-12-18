-- Apple sales project

select * from category;
select * from products;
select * from stores;
select * from sales;
select * from warranty;


-- EDA

select distinct repair_status from warranty;
select count(*) from sales;


-- Improving query performance

-- ET: 230.00ms
-- PT: 0.186ms
-- after index ET: 5-10 ms
explain analyze
select * from sales
where product_id = 'P-44';

-- ET: 246.93ms
-- PT: 0.0.22ms
-- after index ET: 4ms explain analyze

select * from sales
where store_id = 'ST-31';

create index sales_product_id on sales(product_id);
create index sales_store_id on sales(store_id);
create index sales_sale_date on sales(sale_date);



-- Business problems

-- 1. Find the number of stores in each country.
select country, count(store_id) as total_stores
from stores
group by 1
order by 2 desc;


-- 2. Calculate the total number of units sold by each store.
select s.store_id, st.store_name, sum(s.quantity) as total_units_sold
from sales s
join stores st on s.store_id = st.store_id
group by 1,2
order by 3 desc;


-- 3. Identify how many sales occured in DEcember 2023.
select count(sale_id) as total_sales
from sales
where to_char(sale_date, 'MM-YYYY') = '12-2023';


-- 4. Determine how many stores have never had a warranty claim filed.
select count(*) 
from stores
where store_id not in
(
		select distinct store_id
		from sales as s
		right join warranty as w on s.sale_id = w.sale_id
);


-- 5. Calculate the percentage of warranty claims marked as "Warranty void".
select round((count(claim_id)/(select count(*) from warranty)::numeric) * 100,2) as warranty_void_percentage
from warranty
where repair_status = 'Warranty Void';


-- 6. Identify which store had the highest total units sold in the last year.
select s.store_id, st.store_name, sum(s.quantity) as total_units_sold
from sales as s
join stores as st on s.store_id = st.store_id
where sale_date >= (current_date - interval '1 Year')
group by 1, 2
order by 3 desc 
limit 1;


-- 7. Count the number of unique products sold in the last year.
select count(distinct product_id) 
from sales
where sale_date >= (current_date - interval '1 Year');


-- 8. Find the average price of products in each category.
select p.category_id, c.category_name, avg(p.price) as avg_price
from products as p
join category as c on p.category_id = c.category_id
group by 1,2
order by 3 desc;


-- 9. How many warranty claims were filed in 2020.
select count(*) as warranty_claim
from warranty
where extract(year from claim_date) = 2020; 


-- 10. For each store, identify the best-selling day based on highest quantity sold.
select store_id, day_name as best_selling_day, total_units_sold
from
	(
		select store_id, to_char(sale_date, 'day') as day_name, sum(quantity) as total_units_sold, 
		rank() over(partition by store_id order by sum(quantity) desc) as rank
		from sales
		group by 1, 2
	) as t1
where rank = 1;


-- 11. Identify the least selling product in each country based on total units sold.
with cte as
(
	select st.country, p.product_name, sum(s.quantity) as total_qty_sold,
	rank() over(partition by st.country order by sum(s.quantity)) as rank
	from sales s
	join stores st on s.store_id = st.store_id
	join products p on s.product_id = p.product_id
	group by 1, 2
)
select country, product_name, total_qty_sold
from cte
where rank = 1;


-- 12. Calculate how many warranty claims were filed within 180 days of a product sale.
select count(*)
from warranty as w
left join sales as s on s.sale_id = w.sale_id
where w.claim_date - s.sale_date <= 180;


-- 13. Determine how many warranty claims were filed for products launched in the last two years.
select p.product_name, count(w.claim_id) as no_of_claim, count(s.sale_id) as no_of_sales
from warranty w 
right join sales s on w.sale_id = s.sale_id
join products p on p.product_id = s.product_id
where p.launch_date >= current_date - interval '2 years'
group by 1;


-- 14. List the months in the last three years where sales exceeded 5000 units in the USA.
select to_char(sale_date, 'MM-YYYY') as month, sum(s.quantity) as total_units_sold
from sales s 
join stores st on s.store_id = st.store_id
where st.country = 'USA' and s.sale_date >= current_date - interval '3 years'
group by 1
having sum(s.quantity) > 5000;


-- 15. Identify the product category with the most warranty claims filed in the last two years.
select c.category_name, count(w.claim_id) as total_claims
from warranty w
left join sales s on s.sale_id = w.sale_id
join products p on p.product_id = s.product_id
join category c on c.category_id = p.category_id
where w.claim_date >= current_date - interval '2 years'
group by 1
order by 2 desc;


