use hr;
select database();
Show columns from  hr_analytics;
show tables;
-- SECTION 1: DATA EXPLORATION & QUALITY CHECKS
-- to check the table
select* from hr_analytics
limit 5;

-- to analyze the data types used for each columns
describe hr_analytics;

-- to count total rows
select count(*) from hr_analytics;

-- if there is any null values in table
SELECT
SUM(CASE WHEN EmployeeNumber IS NULL THEN 1 ELSE 0 END) AS employee_id_nulls,
sum(CASE WHEN Age IS NULL THEN 1 ELSE 0 END) AS age_nulls,
SUM(CASE WHEN Department IS NULL THEN 1 ELSE 0 END) AS department_nulls,
SUM(CASE WHEN JobRole IS NULL THEN 1 ELSE 0 END) AS jobrole_nulls,
SUM(CASE WHEN MonthlyIncome IS NULL THEN 1 ELSE 0 END) AS income_nulls,
SUM(CASE WHEN Attrition IS NULL THEN 1 ELSE 0 END) AS attrition_nulls
FROM hr_analytics;

-- check for duplicates employeenumber
SELECT EmployeeNumber,
COUNT(*) AS duplicate_count
FROM hr_analytics
GROUP BY EmployeeNumber
HAVING COUNT(*) > 1;

-- outlier checks on numeric fields
SELECT
MIN(Age) AS min_age,
MAX(Age) AS max_age,
MIN(MonthlyIncome) AS min_income,
MAX(MonthlyIncome) AS max_income,
MIN(YearsAtCompany) AS min_tenure,
MAX(YearsAtCompany) AS max_tenure,
SUM(CASE WHEN YearsAtCompany > Age THEN 1 ELSE 0 END) AS impossible_tenure_rows,
SUM(CASE WHEN MonthlyIncome <= 0 THEN 1 ELSE 0 END) AS non_positive_income_rows
FROM hr_analytics;

-- attrition valus check
SELECT DISTINCT Attrition FROM hr_analytics;
select distinct agegroup from hr_analytics;
select distinct tenureband from hr_analytics;

-- SECTION 2: HEADLINE METRICS
-- total employees in dataset 
select count(*) as total_employess from hr_analytics;

-- employees left/stayed
select attrition,count(*) as employee_count from hr_analytics 
group by attrition;

-- overall attrition rate 
select 
round(sum(case when attrition = 'yes' then 1 else 0 end) * 100 /count(*),2) as attrition_rate from hr_analytics;

-- avg age
SELECT AVG(Age) AS avg_age
FROM hr_analytics;

-- avg tenure at comapny 
SELECT ROUND(AVG(YearsAtCompany), 2) AS average_tenure
FROM hr_analytics;

-- SECTION 3: SEGMENTATION
-- total_count from each depatment categorized by gender
select department,gender,count(*) total_count from hr_analytics
group  by department,gender
order by department,gender;

-- Average income by department
select department,round(avg(monthlyincome),2) avg_income from hr_analytics
group by department order by avg_income desc;

-- employee count by job role 
select jobrole, count(*) total_employee from hr_analytics
group by jobrole
order by total_employee asc;  

-- Attrition rate by department
select  department, count(*) as total_employee,
sum(case when attrition='yes' then 1 else 0 end ) as employee_left,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS attrition_rate
from hr_analytics 
group by department 
order by attrition_rate desc;

-- attrition rate by job role and age group 
select jobrole, agegroup, count(*) as total_employee,
sum(case when  attrition='yes' then 1 else 0 end ) as employee_left,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS attrition_rate
from hr_analytics 
group by jobrole,agegroup
order by attrition_rate desc;
 
-- Attrition difference between overtime vs non-overtime
select overtime, department,count(*) as total_employee,
sum(case when  attrition='yes' then 1 else 0 end ) as employee_left,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS attrition_rate
from hr_analytics 
group by overtime,department
order by attrition_rate;

-- Attrition rate by job satisfaction
select jobsatisfaction, count(*) as total_employee,
sum(case when  attrition='yes' then 1 else 0 end ) as employee_left,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS attrition_rate
from hr_analytics 
group by jobsatisfaction 
order by attrition_rate desc;
  
-- Attrition rate by distance-from-home group
select 
case when distancefromhome<= 5 then '0-5'
when distancefromhome  <= 10 then '5-10'
when distancefromhome <= 20 then '10-20'
else '21+'
end as distance_groups ,
count(*) as total_employees,
SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*),2) AS attrition_rate
FROM hr_analytics
GROUP BY distance_groups
ORDER BY attrition_rate DESC;

-- Average salary hike % — stayed vs left
SELECT Attrition,
ROUND(AVG(PercentSalaryHike), 2) AS average_salary_hike
FROM hr_analytics
GROUP BY Attrition;

-- Years since last promotion — stayed vs left
select Attrition,ROUND(AVG(YearsSinceLastPromotion), 2) AS avg_years_since_promotion
FROM hr_analytics
GROUP BY Attrition;

-- attrition by tenure band
SELECT tenureband,COUNT(*) AS total_employees,SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) AS employees_left,
ROUND(SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END) * 100.0/ COUNT(*),2) AS attrition_rate
FROM hr_analytics
GROUP BY tenureband
ORDER BY CASE 
tenureband
WHEN '0-2' THEN 1
WHEN '3-5' THEN 2
WHEN '6-10' THEN 3
ELSE 4
END;

-- SECTION 4: RANKING & ADVANCED ANALYSIS
-- Rank departments according to attrition rate
with department_rate as (
select department, SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*) AS attrition_rate
from hr_analytics 
group by department 
)
select department, attrition_rate,
rank() over(order by attrition_rate desc)as attrition_rank 
from department_rate;

-- Departments with attrition above overall rate
with department_rate as (
select department,SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*) AS attrition_rate
from hr_analytics 
group by department
),
overall_rate as(
select SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*) AS attrition_rate
FROM hr_analytics
)
select d.department, (d.attrition_rate) as department_attrition,(o.attrition_rate) as overall_attrition from department_rate d
cross join overall_rate o
where d.attrition_rate > o.attrition_rate ; 

-- Top 3 job roles by attrition rate
with top_roles as(
select jobrole, SUM(CASE WHEN Attrition = 'Yes' THEN 1 ELSE 0 END)* 100.0 / COUNT(*) AS attrition_rate
from hr_analytics 
group by jobrole
),
ranked_roles as (
select jobrole,attrition_rate,
dense_rank() over(order by attrition_rate desc) as role_rank 
from top_roles
)
select jobrole,attrition_rate ,role_rank from ranked_roles where role_rank <= 3;

-- Employees whose income is above the average income of their own department
with department_income as (
select department, avg(monthlyincome) as avg_income 
from hr_analytics 
group by department
)
select h.employeenumber, h.department,h.jobrole,h.monthlyincome,avg_income from hr_analytics h
join department_income as d 
on h.department= d.department where h.monthlyincome > d.avg_income 
order by h.department,h.monthlyincome  desc;