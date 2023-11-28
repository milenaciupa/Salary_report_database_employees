-- Salary report part 1
-- Query that compares the earnings of women and men.

SELECT
    e.gender
,   AVG(s.salary) as avg_salary
,   COUNT(1) as amount
FROM
        salaries as s
    INNER JOIN
        employees e on e.emp_no = s.emp_no
WHERE NOW() BETWEEN s.from_date AND s.to_date
GROUP BY e.gender
ORDER By 2 DESC;

-- Salary report part 2 
-- Query to check earnings differences occur in the the group:
-- by gender,
-- department,
-- without differentiation.

SELECT
    e.gender
,   d.dept_name
,   avg(s.salary) as avg_salary
,   count(1) as amount
FROM
        salaries as s
    INNER JOIN
        employees e on e.emp_no = s.emp_no
    INNER JOIN
        dept_emp as de on
            de.emp_no = e.emp_no
            AND NOW() BETWEEN de.from_date and de.to_date
            -- w dept_emp też musimy zwrócić uwagę na ważność rekordu
    INNER JOIN
        departments as d on d.dept_no = de.dept_no
WHERE NOW() BETWEEN s.from_date AND s.to_date
GROUP BY e.gender, d.dept_name WITH ROLLUP
ORDER By 2, 1 DESC;

-- Salary report part 3 
-- Query to determined the percentage difference between earnings in individual groups.

WITH cte as (
    SELECT
        e.gender
    ,   d.dept_name
    ,   avg(s.salary) as avg_salary
    ,   count(1) as amount
    FROM salaries as s
             INNER JOIN
         employees e on e.emp_no = s.emp_no
             INNER JOIN
         dept_emp as de on de.emp_no = e.emp_no
                 AND NOW() BETWEEN de.from_date and de.to_date
             INNER JOIN
         departments as d on d.dept_no = de.dept_no
    WHERE NOW() BETWEEN s.from_date AND s.to_date
    GROUP BY e.gender, d.dept_name
    WITH ROLLUP
    ORDER By 2, 1 DESC
)
SELECT
    *
    , LEAD(avg_salary, 1) OVER (PARTITION BY dept_name ORDER BY gender) / avg_salary as diff
FROM cte
WHERE True
    AND gender IS NOT NULL
    AND dept_name IS NOT NULL;
    
-- Salary report part 4
-- Create generate_payment_report procedure, which will take as a parametr the date for which the report is to be generated and then save the results to the employees.payment_report table. 
DELIMITER $$
CREATE PROCEDURE employees.generate_payment_report(p_date DATE)
BEGIN

    SET p_date = LAST_DAY(p_date);

    DROP TABLE IF EXISTS tmp_report;
    CREATE TEMPORARY  TABLE tmp_report AS
    WITH cte as (
        SELECT e.gender,
               d.dept_name,
               avg(s.salary) as avg_salary,
               count(1)      as amount
        FROM salaries as s
                 INNER JOIN
             employees e on e.emp_no = s.emp_no
                 INNER JOIN
             dept_emp as de on de.emp_no = e.emp_no AND p_date BETWEEN de.from_date and de.to_date
                 INNER JOIN
             departments as d on d.dept_no = de.dept_no
        WHERE p_date BETWEEN s.from_date AND s.to_date
        GROUP BY e.gender, d.dept_name
        WITH ROLLUP
        ORDER By 2, 1 DESC
    )
    SELECT
        *
        , LEAD(avg_salary, 1) OVER (PARTITION BY dept_name ORDER BY gender) / avg_salary as diff
    FROM cte
    WHERE True
        AND gender IS NOT NULL
        AND dept_name IS NOT NULL;

    DELETE FROM employees.payment_report
    WHERE generation_date = p_date;

    INSERT INTO employees.payment_report
    SELECT
        *,
        p_date,
        now()
    FROM tmp_report;
END;
DELIMITER $$

CALL employees.generate_payment_report(NOW());
CALL employees.generate_payment_report('2021-01-31');