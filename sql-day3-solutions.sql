## GROUPING ##
-- Income
SELECT SUM(amount)
FROM payment;

SELECT customer_id,
       SUM(amount) AS amount
FROM payment
GROUP BY customer_id
ORDER BY amount DESC;

SELECT staff_id,
       SUM(amount) AS amount
FROM payment
GROUP BY staff_id
ORDER BY amount DESC;

SELECT customer_id,
       DATE_FORMAT(payment_date, '%Y-%m-01') AS payment_month,
       SUM(amount)                           AS amount
FROM payment
GROUP BY customer_id, payment_month
ORDER BY customer_id, amount DESC;

SELECT staff_id,
       DATE_FORMAT(payment_date, '%Y-%m-01') AS payment_month,
       SUM(amount)                           AS amount
FROM payment
GROUP BY staff_id, payment_month
ORDER BY staff_id, amount DESC;

-- Payment report
CREATE OR REPLACE VIEW payment_report AS
SELECT c.first_name,
       c.last_name,
       c.email,
       SUM(p.amount)       AS payments_total,
       COUNT(p.amount)     AS payments_amount,
       AVG(p.amount)       AS payments_avarage,
       MAX(p.payment_date) AS max_payment_date
FROM payment AS p
         INNER JOIN
     customer c USING (customer_id)
GROUP BY c.customer_id;

SELECT (SELECT SUM(payments_total) FROM payment_report) = (SELECT SUM(amount) FROM payment);

-- Number of actors in a film
DROP TABLE IF EXISTS tmp_film_actors;
CREATE TEMPORARY TABLE tmp_film_actors AS
SELECT f.film_id,
       f.title,
       COUNT(fa.actor_id) AS actors
FROM film AS f
         INNER JOIN
     film_actor fa ON f.film_id = fa.film_id
GROUP BY actor_id;

WITH cte AS (SELECT film_id,
                    COUNT(actor_id) AS actors
             FROM film_actor AS fa
             GROUP BY 1)
SELECT *
FROM cte AS c
         INNER JOIN
     tmp_film_actors AS t USING (film_id)
WHERE c.actors <> t.actors;

-- Film rentals
DROP TABLE IF EXISTS tmp_film_rentals;
CREATE TEMPORARY TABLE tmp_film_rentals AS
SELECT f.film_id,
       f.title,
       COUNT(r.rental_id) AS rentals
FROM film AS f
         INNER JOIN
     inventory AS i USING (film_id)
         INNER JOIN
     rental AS r USING (inventory_id)
GROUP BY f.film_id;

WITH cte AS (SELECT i.film_id,
                    COUNT(r.rental_id) AS rentals
             FROM inventory AS i
                      INNER JOIN
                  rental r ON i.inventory_id = r.inventory_id
             GROUP BY 1)
SELECT *
FROM cte AS c
         INNER JOIN
     tmp_film_rentals AS t USING (film_id)
WHERE c.rentals <> t.rentals;

-- Income by film
DROP TABLE IF EXISTS tmp_film_payments;
CREATE TEMPORARY TABLE tmp_film_payments AS
SELECT i.film_id,
       SUM(p.amount) AS payments
FROM inventory AS i
         INNER JOIN
     rental AS r USING (inventory_id)
         INNER JOIN
     payment AS p USING (rental_id)
GROUP BY film_id;

SELECT (SELECT SUM(amount) FROM payment WHERE rental_id IS NOT NULL) = (SELECT SUM(payments) FROM tmp_film_payments);

-- Most profitable film
SELECT *
FROM tmp_film_actors AS fa
         INNER JOIN
     tmp_film_rentals AS fr USING (film_id)
         INNER JOIN
     tmp_film_payments AS fp USING (film_id)
ORDER BY payments DESC
LIMIT 10;

## ROLLUP ##
-- Rollup
SELECT s.store_id,
       s2.staff_id,
       SUM(p.amount) AS sales
FROM inventory AS i
         INNER JOIN
     rental AS r USING (inventory_id)
         INNER JOIN
     payment AS p USING (rental_id)
         INNER JOIN
     store AS s USING (store_id)
         INNER JOIN
     staff AS s2 USING (store_id)
GROUP BY s.store_id,
         s2.staff_id
WITH ROLLUP
ORDER BY 1, 2;

-- Rollup and having
SELECT customer_id,
       staff_id,
       SUM(amount)
FROM payment
WHERE customer_id < 4
GROUP BY customer_id, staff_id
WITH ROLLUP
HAVING SUM(amount) > 70;

## WINDOW FUNCTION ##
-- Actors ranking
SELECT *, ROW_NUMBER() OVER (ORDER BY avg_film_rate DESC)
FROM actor_analytics;

-- Cumulative sum
SELECT *
     , ROW_NUMBER() OVER (_order)                AS rn
     , MIN(avg_film_rate) OVER (_order)          AS min_cumm
     , MAX(longest_movie_duration) OVER (_order) AS longest_movie_duration_cumm
     , SUM(actor_payload) OVER (_order)          AS payload_cumm
FROM actor_analytics
WINDOW _order AS (ORDER BY actor_id);

-- Pareto principle
/*
One may disagree with the use of ROW_NUMBER() here. For many reasons a RANK or DENSE_RANK would probably be better, but it's not worth analyzing at this stage what is better to use from a technical point of view - it's not worth fussing over.
Interpretation: in this dataset the data is nicely, almost linearly distributed, however, taking, for example, an actor with id 83 we can say: 6% of actors generate 8.7% of payload.
 */
SELECT *
     , ROW_NUMBER() OVER (payload) / COUNT(1) OVER ()                 AS count_percent
     , SUM(actor_payload) OVER (payload) / SUM(actor_payload) OVER () AS payload_percent
FROM actor_analytics
WINDOW payload AS (ORDER BY actor_payload DESC);

-- Ranking
SELECT *
     , RANK() OVER (rental)       AS _rank
     , DENSE_RANK() OVER (rental) AS _dense_rank
     , ROW_NUMBER() OVER (rental) AS _rn
FROM film_analytics
WINDOW rental AS (ORDER BY rentals DESC)
# WINDOW rental as (PARTITION BY rating ORDER BY rentals DESC)
;

## DATETIME ##
-- Calendar
SELECT DATEDIFF('2030-12-31', '2000-01-01');

WITH cte AS (SELECT ADDDATE('2000-01-01', ROW_NUMBER() OVER ()) AS date
             FROM payment
             LIMIT 11323)
SELECT date,
       EXTRACT(YEAR FROM date)  AS date_year,
       EXTRACT(MONTH FROM date) AS date_month,
       EXTRACT(DAY FROM date)   AS date_day,
       DAYOFWEEK(date)          AS day_of_week,
       WEEKOFYEAR(date)         AS week_of_year,
       NOW()                    AS last_update
FROM cte;

-- Payments
SELECT EXTRACT(YEAR FROM payment_date)  AS payment_year,
       EXTRACT(MONTH FROM payment_date) AS payment_month,
       SUM(amount)                      AS amount
FROM payment
GROUP BY 1, 2
WITH ROLLUP
ORDER BY 1, 2;



