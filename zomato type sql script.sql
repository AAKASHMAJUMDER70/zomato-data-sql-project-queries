ZOMATOcreate database zomato
use zomato

CREATE TABLE goldusers_signup(userid integer,gold_signup_date date); 

INSERT INTO goldusers_signup(userid,gold_signup_date) 
 VALUES (1,'2017-09-22'),
(3,'2017-04-21');

CREATE TABLE users(userid integer,signup_date date); 

INSERT INTO users(userid,signup_date) 
 VALUES (1,'2014-02-09')
 INSERT INTO users(userid,signup_date) values
(2,to_date('01-15-2015','mm-dd-yyyy'))
insert into users (userid,signup_date) values
(3,to_date('04-11-2014','dd-mm-yyyy'));

CREATE or replace TABLE sales(userid integer,created_date date,product_id integer); 

INSERT INTO sales(userid,created_date,product_id) 
 VALUES (1,'2017-04-19',2),
(3,'2019-12-18',1),
(2,'2020-07-20',3),
(1,'2019-10-23',2),
(1,'2018-03-19',3),
(3,'2016-12-20',2),
(1,'2016-11-09',1),
(1,'2016-05-20',3),
(2,'2017-09-24',1),
(1,'2017-03-11',2),
(1,'2016-03-11',1),
(3,'2016-11-10',1),
(3,'2017-12-07',2),
(3,'2016-12-15',2),
(2,'2017-11-08',2),
(2,'2018-09-10',3);


CREATE TABLE product(product_id integer,product_name text,price integer); 

INSERT INTO product(product_id,product_name,price) 
 VALUES
(1,'p1',980),
(2,'p2',870),
(3,'p3',330);



select * from sales;
select * from product;
select * from goldusers_signup;
select * from users;



--what is the total amount spent by each customer on zomato?
with cte as (
select s.userid as user_id,s.product_id as product_id, p.price as money_spent,1 as units_of_product from sales as s
left join product as p on s.product_id=p.product_id  
order by userid
)
select user_id, sum(money_spent*units_of_product) as amount_spent from cte 
group by user_id



--  how many days has each customer visited zomato?

select userid,count(distinct(created_date)) as num_of_days_of_visiting_zomato
from sales
group by userid
order by userid


--what was the first product purchased by each customer?
with cte as(
select userid,created_date,
rank() over(partition by userid order by created_date) as ranking
from sales 
order by userid)
select userid,created_date from cte 
where ranking=1

with cte as(
select userid,created_date,
dense_rank() over(partition by userid order by created_date) as ranking
from sales 
order by userid)
select userid,created_date from cte 
where ranking=1


--what is the most purchased item on the product list and how many time swas it purchased by all customers?


select product_id,count(product_id) as number_of_times_purchased
from sales
group by product_id
order by count(product_id) desc
limit 1

select top 2 product_id,count(product_id) as number_of_times_purchased
from sales
group by product_id
order by count(product_id) desc

select top 3 product_id,count(product_id) as number_of_times_purchased
from sales
group by product_id
order by count(product_id) desc

select top 1 product_id,count(product_id) as number_of_times_purchased
from sales
group by product_id
order by count(product_id) desc

select userid,count(created_date) from sales where product_id = ( select top 1 product_id
from sales
group by product_id
order by count(product_id) desc
)
group by userid
order by userid

select userid,count(created_date) from sales where product_id = ( select top 1 product_id
from sales
group by product_id
order by count(product_id) desc
)
group by userid
order by count(created_date)



--whuch is the most popular product for each customer?

with cte as (
select userid , product_id , count(product_id) as c,
dense_rank() over(partition by userid order by count(product_id) desc) as ranking
from sales
group by userid,product_id
order by userid
)
select userid,product_id,c as times_purchased
from cte
where ranking =1


--which item was purchased first by the customer after they signed up for gold membership on the platform?

with cte as
(
select sales.userid,sales.product_id,sales.created_date, 
dense_rank() over(partition by sales.userid order by sales.created_date) as ranking
from sales
inner join goldusers_signup on sales.userid = goldusers_signup.userid
where sales.created_date>=goldusers_signup.gold_signup_date
group by sales.userid,sales.product_id,sales.created_date
order by 1
)
select * from cte where ranking =1


select sales.userid,sales.product_id,sales.created_date, 
dense_rank() over(partition by sales.userid order by sales.created_date) as ranking
from sales
inner join goldusers_signup on sales.userid = goldusers_signup.userid
where sales.created_date>=goldusers_signup.gold_signup_date 
group by sales.userid,sales.product_id,sales.created_date
qualify ranking =1
order by 1


--which product was purchased by the gold customers just before becoming the gold members?



select s.userid,s.created_date,g.gold_signup_date ,
rank() over(partition by s.userid order by s.created_date desc) as ranking 
from sales as s  
inner join goldusers_signup as g on s.userid = g.userid
where s.created_date<g.gold_signup_date
qualify ranking=1
order by s.userid desc



--what is the total orders and amount spent for each member after they became a member?

select s.userid,count(s.created_date) as total_orders,sum(p.price) as amount_spent 
from sales as s 
inner join goldusers_signup as g on g.userid=s.userid
inner join product as p on s.product_id=p.product_id
where s.created_date>=g.gold_signup_date
group by s.userid
order by s.userid



select * from sales
select * from product
select * from goldusers_signup



select s.userid,p.product_id from sales as s
inner join product as p on s.product_id=p.product_id
inner join goldusers_signup as g on g.userid=s.userid
where s.created_date>=g.gold_signup_date
group by s.userid,p.product_id
order by s.userid



--what is the total orders and amount spent for each member after they became a member?


select s.userid,count(s.created_date) as total_orders,sum(p.price) as amount_spent 
from sales as s 
inner join goldusers_signup as g on g.userid=s.userid
inner join product as p on s.product_id=p.product_id
where s.created_date<g.gold_signup_date
group by s.userid
order by s.userid

--if buying each product generates points eg 5rs=2pts and each product has different points for example p1 has 5rs=1pt , for p2 10rs = 5 pts and for p3 5rs = 1points
--calculate points collected by each customers and for which product most points have been given till now
--case when 5rs=2pts
with cte as (
select s.userid as t1, sum(1*p.price) as total_spent from sales as s
inner join product as p on s.product_id=p.product_id
group by s.userid
order by s.userid
)
select *,(total_spent/5)*2 as total_points_collectedfrom cte

--case when p1 has 5rs=1pt , for p2 10rs = 5 pts and for p3 5rs = 1points





