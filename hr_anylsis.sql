create database hr_anylisis;
use hr_anylisis;
select * from project_hr;

#Removing duplicate rows
SELECT COUNT(employee_id) FROM project_hr;
SELECT (COUNT(employee_id) - COUNT(DISTINCT employee_id)) no_of_duplicates FROM project_hr;

#checking the duplicate rows
SELECT employee_id,count(employee_id) FROM project_hr GROUP BY 1 HAVING count(employee_id) > 1;

#filling the missing value in education field
UPDATE project_hr SET education = 'Not Specified' WHERE education='';

#deleting the duplicates
DELETE FROM project_hr
WHERE employee_id IN (
    SELECT employee_id FROM (
        SELECT employee_id, ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY employee_id) AS row_num
        FROM project_hr
    ) AS duplicate_rows
    WHERE row_num > 1
);

#-- Step 1: Create a temporary table with duplicate rows based on row number
CREATE TEMPORARY TABLE duplicate_rows AS
SELECT employee_id
FROM (
    SELECT employee_id, ROW_NUMBER() OVER (PARTITION BY employee_id ORDER BY employee_id) AS row_num
    FROM project_hr
) AS numbered_rows
WHERE row_num > 1;

#-- Step 2: Delete duplicates from the original table using the temporary table
DELETE FROM project_hr
WHERE employee_id IN (SELECT employee_id FROM duplicate_rows);

#-- Step 3: Drop the temporary table
DROP TEMPORARY TABLE duplicate_rows;


#-- Step 2: Removing rows for which numeric columns are having irrelevant data type values
DESC project_hr;

SELECT DISTINCT previous_year_rating
FROM project_hr;


SELECT COUNT(previous_year_rating)
FROM project_hr
WHERE previous_year_rating = 'None';


#-- finding mean, median, mode for previous_year_rating for imputing
SELECT AVG(previous_year_rating) AS MEAN
FROM project_hr
WHERE previous_year_rating != 'None';
#-- mean is approx 3.08


SELECT MAX(previous_year_rating) AS MODE
FROM project_hr
WHERE previous_year_rating = (
							SELECT previous_year_rating
                            FROM project_hr
                            GROUP BY previous_year_rating
                            ORDER BY count(previous_year_rating) DESC
                            LIMIT 1)
                            ;
#-- mode is 3


-- MEDIAN
								
SET @rowindex := 0;
SELECT
   AVG(pp.previous_year_rating) as Median 
FROM
   (SELECT @rowindex:=@rowindex + 1 AS rowindex,
           p.previous_year_rating AS previous_year_rating
    FROM project_hr p
    ORDER BY p.previous_year_rating) AS pp
WHERE
pp.rowindex IN (FLOOR(@rowindex / 2), CEIL(@rowindex / 2));
#-- median = 3
#-- So mean, mode and median values are almost near 3 hence imputing the null values with 3

#data consistency so seting year=3
-- imputing the null values
UPDATE project_hr
SET previous_year_rating = 3
WHERE previous_year_rating = '';

-- rechecking the null values of previous_year_rating
SELECT COUNT(previous_year_rating)
FROM project_hr
WHERE previous_year_rating = 'None';

ALTER TABLE project_hr
MODIFY COLUMN previous_year_rating INT;


SELECT  previous_year_rating FROM project_hr;

#checking the datatype for each column
SELECT column_name, DATA_TYPE 
FROM INFORMATION_SCHEMA.COLUMNS 
WHERE table_schema = 'hr_anylisis' AND table_name = 'project_hr';


 #checking null_values_count for each column
 SELECT COUNT(*) FROM project_hr WHERE employee_id IS NULL;
SELECT COUNT(*) FROM project_hr WHERE department NULL;
SELECT COUNT(*) FROM project_hr WHERE region IS NULL;
SELECT COUNT(*) FROM project_hr WHERE education IS NULL;
SELECT COUNT(*) FROM project_hr WHERE Gender IS NULL;
SELECT COUNT(*) FROM project_hr WHERE recruitment_channel IS NULL;
SELECT COUNT(*) FROM project_hr WHERE no_of_trainings IS NULL;
SELECT COUNT(*) FROM project_hr WHERE age IS NULL;
SELECT COUNT(*) FROM project_hr WHERE previous_year_rating IS NULL;
SELECT COUNT(*) FROM project_hr WHERE length_of_service IS NULL;
SELECT COUNT(*) FROM project_hr WHERE KPIs_met_more_than_80 IS NULL;
SELECT COUNT(*) FROM project_hr WHERE awards_won IS NULL;
SELECT COUNT(*) FROM project_hr WHERE avg_training_score IS NULL;


SELECT 
    SUM(CASE WHEN age IS NULL THEN 1 ELSE 0 END) AS age_null_count,
    SUM(CASE WHEN avg_training_score IS NULL THEN 1 ELSE 0 END) AS avg_training_null_count,
    SUM(CASE WHEN awards_won IS NULL THEN 1 ELSE 0 END) AS awards_won_null_count,
    SUM(CASE WHEN department IS NULL THEN 1 ELSE 0 END) AS deapt_null_count,
    SUM(CASE WHEN education IS NULL THEN 1 ELSE 0 END) AS education_null_count,
    SUM(CASE WHEN employee_id IS NULL THEN 1 ELSE 0 END) AS employeeid_null_count,
    SUM(CASE WHEN gender IS NULL THEN 1 ELSE 0 END) AS gender_null_count,
    SUM(CASE WHEN KPIs_met_more_than_80 IS NULL THEN 1 ELSE 0 END) AS KPIs_null_count,
    SUM(CASE WHEN length_of_service IS NULL THEN 1 ELSE 0 END) AS length_of_service_null_count,
    SUM(CASE WHEN no_of_trainings IS NULL THEN 1 ELSE 0 END) AS no_of_trainings_null_count,
    SUM(CASE WHEN previous_year_rating IS NULL THEN 1 ELSE 0 END) AS prev_yr_rating_null_count,
    SUM(CASE WHEN recruitment_channel IS NULL THEN 1 ELSE 0 END) AS recruitment_c_null_count,
    SUM(CASE WHEN region IS NULL THEN 1 ELSE 0 END) AS region_null_count
FROM
	project_hr;

#no null values



#ANALYSIS
SELECT * FROM project_hr;

#. Gender Distribution- Understand the gender distribution within the organization.
SELECT gender, COUNT(*) AS gender_count FROM  project_hr GROUP BY gender;
#[m	12311
#f	5101]

#What is the average age of employees within each department?
SELECT department, AVG(age) AS average_age FROM project_hr GROUP BY department;

#Analyze the age distribution
SELECT age, COUNT(*) AS age_count FROM project_hr GROUP BY age ORDER BY age;

#departmenrt and region gets the count of employees in both region and departmnet
SELECT department, region, COUNT(employee_id) AS employee_count FROM project_hr GROUP BY department, region order by region desc;


#Find the average age of employees in each region, grouped by gender.
SELECT region, gender, ROUND(AVG(age), 2) Avg_age
FROM project_hr
GROUP BY region, gender;

#List the departments with the highest number of employees under 30 years of age.
SELECT department, COUNT(employee_id) AS num_under_30 ,region FROM project_hr WHERE age < 30
GROUP BY department,region ORDER BY num_under_30 DESC;

#Training and Development Insights!!!!!!!
#2.training programs with the highest average scores across all departments
select department, max(avg_training_score) from project_hr group by department ;

#educational background affects average training scores.
SELECT education, AVG(avg_training_score) AS avg_training_score FROM project_hr GROUP BY education ORDER BY avg_training_score DESC;

# training effectiveness across different regions.
SELECT region, AVG(avg_training_score) AS avg_training_score FROM project_hr
GROUP BY region ORDER BY avg_training_score DESC;


# which departments are most active in training programs.
SELECT department, COUNT(no_of_trainings) AS total_trainings,AVG(no_of_trainings) AS avg_trainings_per_employee
FROM project_hr GROUP BY department ORDER BY total_trainings DESC;

# higher number of trainings correlates with meeting KPIs over 80%
SELECT no_of_trainings,
       AVG(KPIs_met_more_than_80) * 100 AS pct_meeting_kpis
FROM project_hr GROUP BY no_of_trainings ORDER BY no_of_trainings DESC;

#relationship between training, performance, and length of service.
SELECT no_of_trainings, 
       AVG(length_of_service) AS avg_tenure,AVG(previous_year_rating) AS avg_performance
FROM project_hr GROUP BY no_of_trainings ORDER BY no_of_trainings DESC;

# effective recruitment channels for employees with high ratings and training scores.[avg 4 ayide assume akune]
SELECT recruitment_channel,
       AVG(previous_year_rating) AS avg_performance,
       AVG(avg_training_score) AS avg_training_score
FROM project_hr WHERE previous_year_rating >= 4  GROUP BY recruitment_channel ORDER BY avg_performance DESC;

#training participation has any correlation with receiving awards.
SELECT no_of_trainings, 
       AVG(awards_won) * 100 AS pct_awards_won
FROM project_hr
GROUP BY no_of_trainings
ORDER BY no_of_trainings DESC;

#Calculate the average length of service for employees per education level and gender, considering only those employees 
#who have completed more than 2 trainings and have an average training score greater than 75.answer= {master&above}
SELECT education, gender, ROUND(AVG(length_of_service),2) avg_len_of_service
FROM project_hr
WHERE no_of_trainings > 2 AND avg_training_score > 75
GROUP BY 1,2;


# age distribution among employees who meet KPIs above 80% and win awards.[31]
SELECT age, COUNT(employee_id) AS high_achievers
FROM project_hr WHERE KPIs_met_more_than_80 = 1 AND awards_won = 1 GROUP BY age ORDER BY high_achievers DESC;
 
#performance  by gender
SELECT gender, AVG(previous_year_rating) AS avg_rating FROM project_hr GROUP BY gender ORDER BY avg_rating DESC;



# 5)Awards and Recognition Patterns
#5.1  How are awards distributed across departments
SELECT department, COUNT(awards_won) AS awards_count FROM project_hr WHERE awards_won > 0 GROUP BY department;

#5.2  average length of service for employees who have won awards?[4.7420]
SELECT AVG(length_of_service) AS avg_service_years FROM project_hr WHERE awards_won = 1;

#5.3 Is there a trend in awards won relative to previous year rating?
SELECT previous_year_rating, COUNT(awards_won) AS awards_count FROM project_hr WHERE awards_won = 1 GROUP BY previous_year_rating;

#. Find the percentage of female employees who have won awards, per department. 
#Also show the number of female employees who won awards and total female employees. 
SELECT department, 
	ROUND((COUNT(CASE WHEN gender = 'f' AND awards_won > 0 THEN 1 END))/(COUNT(CASE WHEN gender = 'f' THEN 1 END))*100,2) total_F_awards_percent,
	COUNT( CASE WHEN gender = 'f' AND awards_won >0 THEN 1 END) total_F_awards,
    COUNT( CASE WHEN gender = 'f' THEN 1 END) total_F_employees
FROM project_hr
GROUP BY 1;

#find the top 3 regions with the highest number of employees who have met more than 80% of their KPIs 
#and received at least one award, grouped by department and region.
SELECT department, region, COUNT(employee_id) no_of_employees
FROM project_hr
WHERE KPIs_met_more_than_80 > 0 AND awards_won > 0
GROUP BY 1,2
ORDER BY no_of_employees DESC
LIMIT 3;

#age group with avrage training score and kpi achivemnet rate
SELECT 
    CASE 
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 41 AND 50 THEN '41-50'
        ELSE 'Over 50'
    END AS age_group, 
    AVG(avg_training_score) AS avg_training_score, 
    AVG(KPIs_met_more_than_80) AS kpi_achievement_rate
FROM project_hr 
GROUP BY age_group;



# Find the percentage of employees who have won awards in each region. (Round percentages up to two decimal places if needed)

SELECT region, ROUND((SUM(awards_won)/COUNT(region))*100,2) awards_percentage
FROM project_hr
GROUP BY 1
HAVING SUM(awards_won)/COUNT(region) > 0
ORDER BY awards_percentage desc;

#Show the number of employees who have met more than 80% of KPIs for each recruitment channel and education level.*/
SELECT recruitment_channel, education, COUNT(employee_id) no_of_employees_having_KPIs_80plus
FROM project_hr WHERE KPIs_met_more_than_80 >0 GROUP BY 1,2;

#5. Find the average length of service for employees in each department, considering only employees with previous year ratings greater than or equal to 4. 
SELECT department, ROUND(AVG(length_of_service),2) as Avg_len_of_service
FROM project_hr
WHERE previous_year_rating >= 4
GROUP BY 1;


# List the top 5 regions with the highest average previous year ratings. 
SELECT region, ROUND(AVG(previous_year_rating),2) Avg_prev_yr_rating FROM project_hr GROUP BY 1
ORDER BY Avg_prev_yr_rating DESC LIMIT 5;

#List the top 5 regions with the highest average previous year ratings. 
SELECT region, ROUND(AVG(previous_year_rating),2) Avg_prev_yr_rating
FROM project_hr
GROUP BY 1
ORDER BY Avg_prev_yr_rating DESC
LIMIT 5;


#List the departments with more than 100 employees having a length of service greater than 5 years.
SELECT department, COUNT(employee_id) as no_of_employee
FROM project_hr
WHERE length_of_service > 5
GROUP BY 1
HAVING COUNT(employee_id) > 100;

# Calculate the percentage of employees per department who have a length of service between 5 and 10 years. 
SELECT department, ROUND(COUNT(CASE WHEN length_of_service BETWEEN 5 AND 10 THEN 1 END)/(COUNT(*))*100,2) PERCENT_of_emp
FROM project_hr
GROUP BY 1;

#Education Level and Performance
SELECT education, AVG(previous_year_rating) AS avg_rating FROM  project_hr group by education ORDER BY avg_rating DESC;

#What is the KPI achievement rate across different education levels[kpi achievement rate]
SELECT education, SUM(CASE WHEN KPIs_met_more_than_80 = 1 THEN 1 ELSE 0 END) * 100.0 / COUNT(employee_id) AS kpi_achievement_rate FROM project_hr GROUP BY education;

#average training score by education level
SELECT education, AVG(avg_training_score) AS avg_score FROM project_hr GROUP BY education;

#education level distributed across employees.which  education level is most common
SELECT education, COUNT(*) AS count FROM project_hr GROUP BY education ORDER BY count DESC;

 #average training score for each education level
 SELECT education, AVG(avg_training_score) AS avg_training_score FROM project_hr GROUP BY education ORDER BY avg_training_score DESC;
 
 #education level that has higest chance of winning awards
 SELECT education, COUNT(CASE WHEN awards_won > 0 THEN 1 END) * 100.0 / COUNT(*) AS award_winning_rate
FROM project_hr GROUP BY education ORDER BY award_winning_rate DESC;



SELECT department, gender, ROUND(AVG(length_of_service),2) Avg_len_of_service
FROM project_hr
WHERE no_of_trainings > 3
GROUP BY 1,2;

#Recruitment Channel and Hiring Insigh
#recruitment channels have the highest retention rates 
SELECT recruitment_channel, AVG(length_of_service) AS avg_service_years FROM project_hr GROUP BY recruitment_channel ORDER BY avg_service_years DESC;

# average previous year rating for employees hired through different recruitment channels
SELECT recruitment_channel, AVG(previous_year_rating) AS avg_rating FROM project_hr GROUP BY recruitment_channel;

#recruitment channel for high-performing employees(awards)
SELECT recruitment_channel, COUNT(employee_id) AS award_winners FROM project_hr WHERE awards_won = 1 GROUP BY recruitment_channel ORDER BY award_winners DESC;

#recruitment channel brought in the most employees
SELECT recruitment_channel, COUNT(*) AS total_hires FROM project_hr GROUP BY recruitment_channel ORDER BY total_hires DESC;

#average length of service for employees from each recruitment channel
SELECT recruitment_channel, AVG(length_of_service) AS avg_length_of_service
FROM project_hr GROUP BY recruitment_channel ORDER BY avg_length_of_service DESC;

#percentage of employees hired through each channel achieved KPIs over 80%    {referred}
SELECT recruitment_channel, 
       COUNT(CASE WHEN KPIs_met_more_than_80 = 1 THEN 1 END) * 100.0 / COUNT(*) AS kpi_achievement_rate
FROM project_hr GROUP BY recruitment_channel ORDER BY kpi_achievement_rate DESC;

# average training score for employees from each recruitment channel
SELECT recruitment_channel, AVG(avg_training_score) AS avg_training_score
FROM project_hr
GROUP BY recruitment_channel
ORDER BY avg_training_score DESC;


#average age of employees hired through each recruitment channel
SELECT recruitment_channel, AVG(age) AS avg_age
FROM project_hr
GROUP BY recruitment_channel
ORDER BY avg_age DESC;


#training sessions, on average, have employees attended from each recruitment channel
SELECT recruitment_channel, AVG(no_of_trainings) AS avg_trainings
FROM project_hr GROUP BY recruitment_channel ORDER BY avg_trainings DESC;



#Performance and Growth Patterns
#trend in KPI achievement over time for employees with different length of service categories (e.g., 0-3 years, 3-5 years, 5+ years)
SELECT 
    CASE 
        WHEN length_of_service <= 3 THEN '0-3 years'
        WHEN length_of_service <= 5 THEN '3-5 years'
        ELSE '5+ years'
    END AS service_category, 
AVG(KPIs_met_more_than_80) AS avg_kpi_achievement FROM project_hr  GROUP BY service_category;


#employees with high previous year ratings (>=4) by age group
SELECT 
    CASE 
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 41 AND 50 THEN '41-50'
        ELSE 'Over 50'
    END AS age_group, 
    COUNT(CASE WHEN previous_year_rating >= 4 THEN 1 END) * 100.0 / COUNT(employee_id) AS high_rating_percentage
FROM project_hr 
GROUP BY age_group;

#average training scores based on the number of training sessions attended
SELECT no_of_trainings, AVG(avg_training_score) AS avg_training_score FROM project_hr GROUP BY no_of_trainings;

SELECT REGION ,COUNT(AWARDS_WON) FROM  

select count(*),length_of_service from project_hr where length_of_service <3 group by length_of_service;#[5841]

select count(*),length_of_service from project_hr where length_of_service >3 group by length_of_service;

SELECT AVG(length_of_service) AS average_length_of_service FROM project_hr;
SELECT avg_training_score, COUNT(*) AS score_count FROM project_hr GROUP BY avg_training_score ORDER BY avg_training_score;


SELECT COUNT(*) AS no_awards_count FROM project_hr WHERE awards_won = 0;

SELECT COUNT(EMPLOYEE_ID) FROM PROJECT_HR;

SELECT previous_year_rating, COUNT(*) AS frequency
FROM project_hr
GROUP BY previous_year_rating
ORDER BY frequency DESC
LIMIT 1;





SELECT department, gender, COUNT(employee_id) AS employee_count  FROM project_hr     GROUP BY department, gender;
SELECT department, AVG(age) AS avg_age  FROM project_hr  GROUP BY department;
SELECT education, AVG(KPIs_met_more_than_80) * 100 AS kpi_achievement_rate
FROM project_hr   GROUP BY education;
SELECT recruitment_channel, AVG(length_of_service) AS avg_service_years
FROM project_hr GROUP BY recruitment_channel;
SELECT recruitment_channel, AVG(previous_year_rating) AS avg_rating
FROM project_hr GROUP BY recruitment_channel;
SELECT education, AVG(avg_training_score) AS avg_training_score
FROM project_hr  GROUP BY education;
SELECT education,
   	COUNT(CASE WHEN awards_won > 0 THEN 1 END) * 100.0 / COUNT(*) AS award_winning_rate FROM project_hr  GROUP BY education;

SELECT
	CASE
    	WHEN age < 30 THEN 'Under 30'
    	WHEN age BETWEEN 30 AND 40 THEN '30-40'
    	WHEN age BETWEEN 41 AND 50 THEN '41-50'
    	ELSE 'Over 50'
	END AS age_group,
    AVG(no_of_trainings) AS avg_trainings,
	AVG(awards_won) * 100 AS award_winning_rate
FROM project_hr  GROUP BY age_group;
 SELECT recruitment_channel, AVG(length_of_service) AS avg_length_of_service
FROM project_hr  GROUP BY recruitment_channel;
SELECT region, AVG(KPIs_met_more_than_80) * 100 AS kpi_achievement_rate 
FROM project_hr  GROUP BY region;
SELECT recruitment_channel, AVG(avg_training_score) AS avg_training_score 
FROM project_hr GROUP BY recruitment_channel;
SELECT no_of_trainings, AVG(avg_training_score) AS avg_training_score 
FROM project_hr GROUP BY no_of_trainings;




SELECT region, gender, ROUND(AVG(age), 2) AS avg_age FROM project_hr  GROUP BY region, gender;
SELECT department, region, COUNT(employee_id) AS employee_count
FROM project_hr  GROUP BY department, region  ORDER BY region DESC;
SELECT department, COUNT(employee_id) AS num_under_30, region 
FROM project_hr  WHERE age < 30  GROUP BY department, region ORDER BY num_under_30 DESC;
SELECT education, gender, ROUND(AVG(length_of_service), 2) AS avg_len_of_service
FROM project_hr  WHERE no_of_trainings > 2 AND avg_training_score > 75
GROUP BY education, gender;
SELECT department, region, COUNT(employee_id) AS no_of_employees
FROM project_hr  WHERE KPIs_met_more_than_80 > 0 AND awards_won > 0
GROUP BY department, region  ORDER BY no_of_employees DESC  LIMIT 3;

SELECT 
    CASE 
        WHEN age < 30 THEN 'Under 30'
        WHEN age BETWEEN 30 AND 40 THEN '30-40'
        WHEN age BETWEEN 41 AND 50 THEN '41-50'
        ELSE 'Over 50'
    END AS age_group, 
    AVG(avg_training_score) AS avg_training_score, 
    AVG(KPIs_met_more_than_80) AS kpi_achievement_rate
FROM project_hr 
GROUP BY age_group;
SELECT no_of_trainings,   AVG(length_of_service) AS avg_tenure, AVG(previous_year_rating) AS avg_performance FROM project_hr  GROUP BY no_of_trainings  ORDER BY no_of_trainings DESC;



SELECT department, 
       ROUND((COUNT(CASE WHEN gender = 'f' AND awards_won > 0 THEN 1 END))/(COUNT(CASE WHEN gender = 'f' THEN 1 END)) * 100, 2) AS total_F_awards_percent,
       COUNT(CASE WHEN gender = 'f' AND awards_won > 0 THEN 1 END) AS total_F_awards,
       COUNT(CASE WHEN gender = 'f' THEN 1 END) AS total_F_employees
FROM project_hr GROUP BY department;
SELECT recruitment_channel, education, COUNT(employee_id) AS no_of_employees_having_KPIs_80plus
FROM project_hr  WHERE KPIs_met_more_than_80 > 0  GROUP BY recruitment_channel, education;



