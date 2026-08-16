CREATE SCHEMA IF NOT EXISTS safari_connect;

set search_path to safari_connect;

CREATE TABLE IF NOT EXISTS bookings_staging (
    booking_id       TEXT,
    passenger_name    TEXT, 
    passenger_phone  TEXT,
    passenger_gender TEXT, 
    passenger_city    TEXT, 
    route_code       TEXT,
    route_from       TEXT, 
    route_to          TEXT, 
    vehicle_plate    TEXT,
    vehicle_type     TEXT, 
    driver_name       TEXT, 
    driver_rating    TEXT,
    departure_date   TEXT, 
    departure_time    TEXT, 
    seat_class       TEXT,
    seats_booked     TEXT, 
    fare_per_seat     TEXT, 
    total_fare       TEXT,
    payment_method   TEXT, 
    booking_status    TEXT, 
    trip_rating      TEXT
);

select * from bookings_staging; 

SELECT COUNT(*) FROM bookings_staging;
SELECT DISTINCT passenger_name FROM bookings_staging ORDER BY passenger_name LIMIT 30;

select distinct count (booking_id) from bookings_staging; 

SELECT DISTINCT passenger_name FROM bookings_staging ORDER BY passenger_name LIMIT 30;

-- Identifying passenger name casing problem
SELECT booking_id, passenger_name FROM bookings_staging
WHERE passenger_name != INITCAP(TRIM(passenger_name));

-- Updating passenger names to the right format. 
UPDATE bookings_staging
SET passenger_name = INITCAP(TRIM(passenger_name))
WHERE passenger_name != INITCAP(TRIM(passenger_name));

SELECT booking_id, passenger_phone FROM bookings_staging
WHERE passenger_phone LIKE '+254%' OR passenger_phone LIKE '%-%';

-- Remove dashes
UPDATE bookings_staging
SET passenger_phone = REGEXP_REPLACE(passenger_phone,'[^0-9]','','g')
WHERE passenger_phone LIKE '%-%';

-- Fix +254 prefix
UPDATE bookings_staging
SET passenger_phone = '0' || SUBSTRING(REGEXP_REPLACE(passenger_phone,'[^0-9]','','g'),4)
WHERE passenger_phone LIKE '+254%';

-- Set empty to NULL
UPDATE bookings_staging SET passenger_phone = NULL
WHERE TRIM(passenger_phone) = '';

-- 2. Gender variants - should be only Male/Female
SELECT DISTINCT passenger_gender, COUNT(*) FROM bookings_staging GROUP BY passenger_gender;

UPDATE bookings_staging
SET passenger_gender = CASE
    WHEN UPPER(TRIM(passenger_gender)) IN ('MALE','M') THEN 'Male'
    WHEN UPPER(TRIM(passenger_gender)) IN ('FEMALE','F') THEN 'Female'
    ELSE passenger_gender
END;

select passenger_city from bookings_staging;

UPDATE bookings_staging
SET passenger_city = INITCAP(TRIM(passenger_city))
WHERE passenger_city != INITCAP(TRIM(passenger_city));

UPDATE bookings_staging SET passenger_city = 'Unknown'
WHERE TRIM(passenger_city) = '' OR passenger_city IS NULL;

-- 6. Date format problems
SELECT booking_id, departure_date FROM bookings_staging
WHERE departure_date NOT SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}';

-- Fix DD/MM/YYYY
UPDATE bookings_staging
SET departure_date = TO_DATE(departure_date,'DD/MM/YYYY')::TEXT
WHERE departure_date LIKE '%/%';

-- Fix DD-MM-YY (length = 8)
UPDATE bookings_staging
SET departure_date = TO_DATE(departure_date,'DD-MM-YY')::TEXT
WHERE departure_date LIKE '%-%' AND LENGTH(departure_date) = 8;

-- Fix MM-DD-YYYY (length=10, day part > 12 confirms it's MM-DD not DD-MM)
UPDATE bookings_staging
SET departure_date = TO_DATE(departure_date,'MM-DD-YYYY')::TEXT
WHERE departure_date LIKE '%-%'
  AND LENGTH(departure_date) = 10
  AND SPLIT_PART(departure_date,'-',2)::INTEGER > 12;

-- seat_class variants
SELECT DISTINCT seat_class, COUNT(*) FROM bookings_staging GROUP BY seat_class;

UPDATE bookings_staging
SET seat_class = CASE
    WHEN UPPER(TRIM(seat_class)) IN ('ECONOMY','ECO','ECONOMY CLASS') THEN 'Economy'
    WHEN UPPER(TRIM(seat_class)) IN ('BUSINESS','BUS','BUSINESS CLASS') THEN 'Business'
    ELSE seat_class
END;

-- 4. payment_method variants
SELECT DISTINCT payment_method FROM bookings_staging;

UPDATE bookings_staging
SET payment_method = CASE
    WHEN UPPER(TRIM(payment_method)) IN ('MPESA','M-PESA','M PESA') THEN 'M-Pesa'
    WHEN UPPER(TRIM(payment_method)) = 'CASH'                              THEN 'Cash'
    WHEN UPPER(TRIM(payment_method)) = 'CARD'                              THEN 'Card'
    ELSE payment_method
END;

UPDATE bookings_staging
SET booking_status = CASE
    WHEN UPPER(TRIM(booking_status)) = 'COMPLETED'  THEN 'Completed'
    WHEN UPPER(TRIM(booking_status)) = 'CANCELLED'  THEN 'Cancelled'
    WHEN UPPER(TRIM(booking_status)) = 'NO SHOW'     THEN 'No Show'
    ELSE booking_status
END;

-- 8. Fares stored as text
SELECT booking_id, total_fare, fare_per_seat FROM bookings_staging
WHERE total_fare LIKE 'KES%' OR fare_per_seat LIKE 'KES%';

UPDATE bookings_staging
SET total_fare = REGEXP_REPLACE(total_fare,'[^0-9.]','','g')
WHERE total_fare SIMILAR TO '%[^0-9.]%';

UPDATE bookings_staging
SET fare_per_seat = REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g')
WHERE fare_per_seat SIMILAR TO '%[^0-9.]%';

-- Driver Name Casing
SELECT driver_name FROM bookings_staging
WHERE driver_name != INITCAP(TRIM(driver_name));

UPDATE bookings_staging
SET driver_name = INITCAP(TRIM(driver_name))
WHERE driver_name != INITCAP(TRIM(driver_name));

-- Vehicle type casing 
SELECT  vehicle_type FROM bookings_staging
WHERE vehicle_type != INITCAP(TRIM(vehicle_type));

UPDATE bookings_staging
SET vehicle_type = INITCAP(TRIM(vehicle_type))
WHERE vehicle_type != INITCAP(TRIM(vehicle_type));

-- 9. Invalid trip ratings
SELECT booking_id, trip_rating FROM bookings_staging
WHERE trip_rating NOT IN ('1','2','3','4','5','');

UPDATE bookings_staging
SET trip_rating = NULL
WHERE TRIM(trip_rating) NOT IN ('1','2','3','4','5','');

-- 11. Negative seats_booked
SELECT booking_id, seats_booked FROM bookings_staging
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1;

-- Delete rows with negative seats
DELETE FROM bookings_staging
WHERE NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9-]','','g'),'')::INTEGER < 1;


SELECT ctid FROM bookings_staging; 
-- Remove exact duplicates (keep first ctid)
DELETE FROM bookings_staging
WHERE ctid NOT IN 
    (SELECT MIN(ctid) FROM bookings_staging GROUP BY booking_id);

SELECT * FROM bookings_staging; 

CREATE TABLE IF NOT EXISTS bookings (
    booking_id        VARCHAR(10) PRIMARY KEY,
    passenger_name    VARCHAR(100),  passenger_phone  VARCHAR(15),
    passenger_gender  VARCHAR(10),   passenger_city   VARCHAR(60),
    route_code        VARCHAR(10),   route_from       VARCHAR(60),
    route_to          VARCHAR(60),   vehicle_plate    VARCHAR(15),
    vehicle_type      VARCHAR(20),   driver_name      VARCHAR(100),
    driver_rating     NUMERIC(3,1),  departure_date   DATE,
    departure_time    VARCHAR(10),   seat_class       VARCHAR(20),
    seats_booked      INTEGER,       fare_per_seat    NUMERIC(10,2),
    total_fare        NUMERIC(12,2), payment_method   VARCHAR(20),
    booking_status    VARCHAR(20),   trip_rating      INTEGER
);

INSERT INTO bookings
SELECT
    booking_id, TRIM(passenger_name),
    NULLIF(TRIM(passenger_phone),''),
    passenger_gender, COALESCE(NULLIF(TRIM(passenger_city),''),'Unknown'),
    route_code, route_from, route_to, vehicle_plate, INITCAP(TRIM(vehicle_type)),
    TRIM(driver_name),
    NULLIF(REGEXP_REPLACE(driver_rating,'[^0-9.]','','g'),'')::NUMERIC,
    departure_date::DATE,  departure_time, seat_class,
    NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER,
    NULLIF(REGEXP_REPLACE(fare_per_seat,'[^0-9.]','','g'),'')::NUMERIC,
    NULLIF(REGEXP_REPLACE(total_fare,'[^0-9.]','','g'),'')::NUMERIC,
    payment_method, booking_status,
    NULLIF(trip_rating,'')::INTEGER
FROM bookings_staging
WHERE departure_date SIMILAR TO '[0-9]{4}-[0-9]{2}-[0-9]{2}'
  AND NULLIF(REGEXP_REPLACE(seats_booked,'[^0-9]','','g'),'')::INTEGER > 0;

-- Verify
SELECT COUNT(*) FROM bookings;
SELECT DISTINCT booking_status FROM bookings; 
SELECT DISTINCT seat_class FROM bookings; 

CREATE OR REPLACE VIEW v_clean_trips AS
SELECT *,
    TO_CHAR(departure_date, 'YYYY-MM')    AS travel_month,
    TO_CHAR(departure_date, 'Month YYYY') AS month_label,
    TO_CHAR(departure_date, 'Day')        AS day_name,
    EXTRACT(MONTH FROM departure_date)    AS month_num,
    EXTRACT(DOW FROM departure_date)      AS day_of_week,
    (fare_per_seat * seats_booked)           AS calculated_fare,
    CASE
        WHEN trip_rating BETWEEN 4 AND 5 THEN 'Satisfied'
        WHEN trip_rating = 3 THEN 'Neutral'
        WHEN trip_rating BETWEEN 1 AND 2 THEN 'Unsatisfied'
        ELSE 'No Rating'
    END AS satisfaction
FROM bookings
WHERE booking_status = 'Completed';

SELECT count(*) FROM v_clean_trips;

SELECT * FROM v_clean_trips;

-- Route Analysis Which routes earn the most? 

SELECT
    route_code,
    route_from || ' → ' || route_to  AS route,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(fare_per_seat), 2)AS avg_fare,
    ROUND(AVG(trip_rating), 2) AS avg_rating
FROM v_clean_trips
GROUP BY route_code, route_from, route_to
ORDER BY total_revenue DESC;	


-- Which is most efficient per seat sold?
SELECT seat_class, sum (total_fare) AS total_revenue
FROM v_clean_trips
GROUP BY seat_class
ORDER BY total_revenue desc;

WITH route_rev AS (
    SELECT route_code, route_from || ' → ' || route_to AS route,
           SUM(total_fare) AS revenue
    FROM v_clean_trips GROUP BY route_code, route_from, route_to
)
SELECT
    route, revenue,
    RANK() OVER (ORDER BY revenue DESC) AS revenue_rank,
    ROUND(revenue * 100.0 / SUM(revenue) OVER (), 1) AS pct_of_total
FROM route_rev ORDER BY revenue_rank;

-- 1D - Vehicle type performance.
--- Compare Bus vs Matatu vs Minibus -
-- total bookings, revenue, avg rating. 
--Which vehicle type is most profitable?

SELECT vehicle_type, 
count (booking_id) AS total_bookings,
sum (total_fare) AS total_revenue,
avg(trip_rating) AS avg_rating
FROM v_clean_trips
GROUP BY vehicle_type 
ORDER BY total_revenue DESC;

-- Driver Performance 
---Show: driver_name, total_trips, total_seats_carried, total_revenue, 
--avg_trip_rating, driver_rating. Order by total_revenue descending.
SELECT * FROM v_clean_trips; 
SELECT driver_name,
count (route_code) AS total_trips,
sum (seats_booked) AS total_seats_carried, 
sum(total_fare) AS total_revenue,
round (avg(trip_rating), 1) AS avg_trip_rating,
avg(driver_rating) AS avg_driver_rating
FROM v_clean_trips
GROUP BY driver_name 
ORDER BY total_revenue DESC; 

-- Using a CTE for driver totals, rank drivers overall by revenue 
-- AND within their vehicle type using PARTITION BY vehicle_type.
WITH driver_totals AS (
    SELECT
        driver_name,
        vehicle_type,
        COUNT(*)AS total_trips,
        SUM(total_fare) AS total_revenue,
        round(avg(driver_rating),2) AS driver_rating,
        ROUND(AVG(trip_rating),2) AS avg_passenger_rating
    FROM v_clean_trips
    GROUP BY driver_name, vehicle_type
)
SELECT
    driver_name, vehicle_type, total_trips, total_revenue, avg_passenger_rating,
    RANK() OVER (ORDER BY total_revenue DESC) AS overall_rank,
    RANK() OVER (PARTITION BY vehicle_type ORDER BY total_revenue DESC) AS vehicle_rank
FROM driver_totals
ORDER BY overall_rank;

-- Group drivers into high-rated (≥ 4.5) and standard (< 4.5). 
-- Compare average passenger trip_rating for each group. 
-- Does a higher driver rating lead to happier passengers? - NO

SELECT
CASE
WHEN driver_rating >= 4.5 THEN 'High-Rated'
ELSE 'Standard'
END AS driver_group,
COUNT(trip_rating) AS rated_trips,
ROUND(AVG(trip_rating), 2) AS avg_passenger_satisfaction
FROM v_clean_trips
WHERE trip_rating IS NOT NULL
GROUP BY
CASE
WHEN driver_rating >= 4.5 THEN 'High-Rated'
ELSE 'Standard'
END
ORDER BY avg_passenger_satisfaction DESC;

-- Monthly revenue with month-over-month change (CTE + LAG)
WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        COUNT(*) AS bookings,
        SUM(total_fare)AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month, bookings, revenue,
    LAG(revenue) OVER (ORDER BY month)AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month)AS change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month),0) * 100, 1)AS change_pct
FROM monthly ORDER BY month;

-- Running total of revenue
WITH monthly AS (
SELECT
TO_CHAR(departure_date, 'YYYY-MM') AS month,
SUM(total_fare) AS revenue
FROM v_clean_trips
GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
month,
revenue,
SUM(revenue) OVER (ORDER BY month) AS cumulative_revenue
FROM monthly
ORDER BY month;

-- Using a CTE for monthly revenue, show the top 3 months 
-- and the bottom 3 months by revenue. Use RANK().
WITH monthly AS (
SELECT
TO_CHAR(departure_date, 'YYYY-MM') AS month,
SUM(total_fare) AS revenue
FROM v_clean_trips
GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
MONTH, revenue,
RANK () OVER (ORDER BY revenue desc) AS rnk
FROM monthly; 
WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
),
ranked AS (
    SELECT
        month,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS top_rank,
        RANK() OVER (ORDER BY revenue ASC) AS bottom_rank,
        RANK() OVER (ORDER BY revenue desc) AS rnk
    FROM monthly
)
SELECT
    month,
    rnk,
    revenue,
    CASE
        WHEN top_rank <= 3 THEN 'Top 3'
        WHEN bottom_rank <= 3 THEN 'Bottom 3'
    END AS revenue_category
FROM ranked
WHERE top_rank <= 3
   OR bottom_rank <= 3
ORDER BY revenue DESC;

-- 3D - Revenue by route per month (pivot)
-- Show one row per month with separate columns for the top 3 routes
-- (RT001, RT002, RT003) using CASE WHEN + SUM.

SELECT route_code, sum(total_fare) AS total_revenue
FROM v_clean_trips
GROUP BY route_code
ORDER BY total_revenue desc;

SELECT
TO_CHAR(departure_date, 'YYYY-MM') AS month,
SUM(CASE WHEN route_code = 'RT001' THEN total_fare ELSE 0 END) AS rt001_revenue,
SUM(CASE WHEN route_code = 'RT004' THEN total_fare ELSE 0 END) AS rt002_revenue,
SUM(CASE WHEN route_code = 'RT002' THEN total_fare ELSE 0 END) AS rt003_revenue
FROM v_clean_trips
GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
ORDER BY month DESC;

--- 4A - Top passenger cities
--- Show: passenger_city, total_bookings, total_seats, total_revenue, avg_fare. 
--- Order by total_bookings descending. Only include cities with 3+ bookings.
SELECT * FROM v_clean_trips;
SELECT passenger_city,
		count(booking_id) AS total_bookings, 
		sum(seats_booked) AS total_seats,
		sum(total_fare) AS total_revenue,
		round(avg(fare_per_seat), 2) AS avg_fare
		FROM v_clean_trips
		GROUP BY passenger_city
		having count(booking_id) > 3
		ORDER BY total_bookings desc;

--- 4B - Gender split and seat class preference
--- Show bookings and revenue broken down by passenger_gender and seat_class. 
-- Use a CASE WHEN pivot to show Economy and Business as separate columns

SELECT 
passenger_gender,
SUM(CASE WHEN seat_class = 'Economy' THEN 1 ELSE 0 END) AS economy_bookings,
SUM(CASE WHEN seat_class = 'Business' THEN 1 ELSE 0 END) AS business_bookings,
SUM(CASE WHEN seat_class = 'Economy' THEN total_fare ELSE 0 END) AS economy_revenue,
SUM(CASE WHEN seat_class = 'Business' THEN total_fare ELSE 0 END) AS business_revenue
FROM v_clean_trips
GROUP BY passenger_gender;

-- 4C - Satisfaction breakdown (CTE)
-- Using a CTE, count how many trips fall into each satisfaction category
--(Satisfied / Neutral / Unsatisfied / No Rating). Show count and percentage of total completed trips.
WITH sat_counts AS (
    SELECT satisfaction, COUNT(*) AS cnt
    FROM v_clean_trips
    GROUP BY satisfaction
)
SELECT
    satisfaction,
    cnt,
    ROUND(cnt * 100.0 / SUM(cnt) OVER (), 1) AS pct
FROM sat_counts ORDER BY cnt DESC;

-- 4D - Passenger quartiles by spend (NTILE)
-- Using a CTE for total spend per passenger, divide passengers into 4 quartiles using NTILE(4). 
-- Show: passenger_name, total_spent, quartile. Label quartile 4 as 'Top Spender'.
WITH passenger_spend AS (
SELECT
passenger_name,
SUM(total_fare) AS total_spent
FROM v_clean_trips
GROUP BY passenger_name
),
quartiles AS (
SELECT
passenger_name,
total_spent,
NTILE(4) OVER (ORDER BY total_spent) AS quartile
FROM passenger_spend
)
SELECT
passenger_name,
total_spent,
CASE
WHEN quartile = 4 THEN 'Top Spender'
ELSE quartile::TEXT
END AS quartile
FROM quartiles
ORDER BY total_spent DESC;

--==5B - Cancellation rate by route
--Show: route_code, route, total_bookings, completed, cancelled, no_show, cancellation_rate_pct.
SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    COUNT(*) AS total,
    SUM(CASE WHEN booking_status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN booking_status = 'No Show'  THEN 1 ELSE 0 END) AS no_show,
    ROUND(SUM(CASE WHEN booking_status IN ('Cancelled','No Show')
             THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate_pct
FROM bookings
GROUP BY route_code, route_from, route_to
ORDER BY cancel_rate_pct DESC;

--===5C - Revenue lost from cancellations and no-shows
SELECT
route_code,
route_from || ' → ' || route_to AS route,
COUNT(*) AS total_bookings,
-- Volume Counts
SUM(CASE WHEN booking_status = 'Completed' THEN 1 ELSE 0 END) AS completed_count,
SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled_count,
SUM(CASE WHEN booking_status = 'No Show' THEN 1 ELSE 0 END) AS no_show_count,
-- Revenue Calculations (Assuming column name is 'total_fare')
SUM(CASE WHEN booking_status = 'Completed' THEN total_fare ELSE 0 END) AS revenue_earned,
SUM(CASE WHEN booking_status = 'Cancelled' THEN total_fare ELSE 0 END) AS revenue_lost_cancelled,
SUM(CASE WHEN booking_status = 'No Show' THEN total_fare ELSE 0 END) AS revenue_lost_noshow,
-- Total Financial Loss
SUM(CASE WHEN booking_status IN ('Cancelled', 'No Show') THEN total_fare ELSE 0 END) AS total_revenue_lost,
-- Financial Loss Percentage (Lost Revenue / Total Potential Revenue)
ROUND( SUM(CASE WHEN booking_status IN ('Cancelled', 'No Show') THEN total_fare ELSE 0 END) * 100.0
/ NULLIF(SUM(total_fare), 0),
1
) AS revenue_loss_pct
FROM bookings
GROUP BY route_code, route_from, route_to
ORDER BY total_revenue_lost DESC;

--==Question 6 - Operational Patterns
--Business need: Operations wants to schedule more vehicles during peak times and fewer during quiet times.
--6A - Revenue by day of week
SELECT
    EXTRACT(DOW FROM departure_date)AS day_num,
    TO_CHAR(departure_date, 'Day') AS day_name,
    COUNT(*) AS total_bookings,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(total_fare), 2) AS avg_booking_value
FROM v_clean_trips
GROUP BY EXTRACT(DOW FROM departure_date), TO_CHAR(departure_date, 'Day')
ORDER BY day_num;

--=== 6B - Busiest departure times
--Group by departure_time. Show which time slots carry the most passengers and generate the most revenue.
--Departure time with the most passengers
SELECT
    departure_time,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_passengers,
    SUM(total_fare) AS total_revenue
FROM v_clean_trips
GROUP BY departure_time
ORDER BY total_passengers DESC;

--Departure time with the most revenue.
SELECT
    departure_time,
    COUNT(*) AS total_bookings,
    SUM(seats_booked) AS total_passengers,
    SUM(total_fare) AS total_revenue
FROM v_clean_trips
GROUP BY departure_time
ORDER BY total_revenue DESC;

--===6C - Seat utilisation by vehicle type
--Compare how full each vehicle type typically runs. 
--Show: vehicle_type, avg_seats_booked, and a label - 'High Load' if avg > 3, 'Medium Load' if 2-3, 'Low Load' if below 2.
--Create Your Views - Hand Off to BI Developer

-- View 1: Route performance
CREATE OR REPLACE VIEW v_route_performance AS
SELECT
    route_code,
    route_from || ' → ' || route_to      AS route,
    COUNT(*)                              AS total_bookings,
    SUM(seats_booked)                   AS total_seats,
    SUM(total_fare)                     AS total_revenue,
    ROUND(AVG(fare_per_seat), 2)     AS avg_fare,
    ROUND(AVG(trip_rating), 2)       AS avg_rating
FROM v_clean_trips
GROUP BY route_code, route_from, route_to
ORDER BY total_revenue DESC;


-- View 2: Driver performance
CREATE OR REPLACE VIEW v_driver_performance AS
SELECT driver_name,
count (route_code) AS total_trips,
sum (seats_booked) AS total_seats_carried,
sum (total_fare) AS total_revenue,
avg(trip_rating) AS avg_trip_rating,
avg(driver_rating) AS avg_driver_rating
FROM v_clean_trips
GROUP BY driver_name
ORDER BY total_revenue DESC;

-- View 3: Monthly revenue trend
CREATE OR REPLACE VIEW v_monthly_revenue AS
WITH monthly AS (
    SELECT
        TO_CHAR(departure_date, 'YYYY-MM') AS month,
        COUNT(*) AS bookings,
        SUM(total_fare) AS revenue
    FROM v_clean_trips
    GROUP BY TO_CHAR(departure_date, 'YYYY-MM')
)
SELECT
    month, bookings, revenue,
    LAG(revenue) OVER (ORDER BY month) AS prev_month,
    revenue - LAG(revenue) OVER (ORDER BY month) AS change,
    ROUND((revenue - LAG(revenue) OVER (ORDER BY month))
        / NULLIF(LAG(revenue) OVER (ORDER BY month),0) * 100, 1)  AS change_pct
FROM monthly ORDER BY month;

-- View 4: Cancellation analysis
CREATE OR REPLACE VIEW v_cancellation_analysis AS
SELECT
    route_code,
    route_from || ' → ' || route_to AS route,
    COUNT(*) AS total,
    SUM(CASE WHEN booking_status = 'Completed' THEN 1 ELSE 0 END) AS completed,
    SUM(CASE WHEN booking_status = 'Cancelled' THEN 1 ELSE 0 END) AS cancelled,
    SUM(CASE WHEN booking_status = 'No Show'  THEN 1 ELSE 0 END) AS no_show,
    ROUND(SUM(CASE WHEN booking_status IN ('Cancelled','No Show')
             THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS cancel_rate_pct
FROM bookings
GROUP BY route_code, route_from, route_to
ORDER BY cancel_rate_pct DESC;

-- View 5: Passenger city insights
CREATE OR REPLACE VIEW v_passenger_insights AS
SELECT
    passenger_city,
    COUNT(booking_id) AS total_bookings,
    SUM(seats_booked) AS total_seats,
    SUM(total_fare) AS total_revenue,
    ROUND(AVG(fare_per_seat), 2) AS avg_fare
FROM v_clean_trips
GROUP BY passenger_city
HAVING COUNT(booking_id) >= 3
ORDER BY total_bookings DESC;

---=====Add Indexes
CREATE INDEX idx_bookings_depdate     ON bookings (departure_date);
CREATE INDEX idx_bookings_route       ON bookings (route_code);
CREATE INDEX idx_bookings_driver      ON bookings (driver_name);
CREATE INDEX idx_bookings_status      ON bookings (booking_status);
CREATE INDEX idx_bookings_payment     ON bookings (payment_method);
CREATE INDEX idx_bookings_vehicle     ON bookings (vehicle_type);
CREATE INDEX idx_bookings_passcity    ON bookings (passenger_city);

SELECT tablename, indexname FROM pg_indexes
WHERE schemaname = 'safari_connect';

































