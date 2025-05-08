-- TASK 1

SELECT flight_id, EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60 as time_diff FROM flights
WHERE status = 'Arrived' AND EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60 >= 30;

-- TASK 2

SELECT passenger_name, contact_data ->> 'phone' as phone_number from tickets
WHERE (passenger_name LIKE 'A%' or passenger_name LIKE 'a%') AND (contact_data->> 'phone' IS NOT NULL)
ORDER BY passenger_name ASC;

-- TASK 3

SELECT tickets.passenger_id, MAX(ticket_flights.amount) AS max_price FROM tickets
JOIN ticket_flights ON tickets.ticket_no = ticket_flights.ticket_no 
GROUP BY tickets.passenger_id;

-- TASK 4

SELECT t.passenger_id, t.passenger_name FROM tickets t
WHERE NOT EXISTS (
    SELECT 1 FROM ticket_flights tf
    JOIN flights ON tf.flight_id = flights.flight_id
    JOIN seats ON flights.aircraft_code = seats.aircraft_code
    WHERE  tf.ticket_no = t.ticket_no AND (flights.status = 'Arrived' OR flights.status = 'Departed') AND seats.fare_conditions = 'Economy' 
        AND ((flights.actual_arrival >= '2016-01-01' AND flights.actual_arrival < '2016-02-01')
            OR (flights.actual_departure >= '2016-01-01' AND flights.actual_departure < '2016-02-01')
        )
);

-- TASK 5

--  St. Petersburg
-- Moscow

SELECT COUNT(*) FILTER 
    (WHERE departure_airport IN 
        (SELECT airport_code FROM airports 
            WHERE city = 'Moscow'
        )
    ) AS moscow_flights,
    COUNT(*) FILTER 
    (WHERE departure_airport IN 
        (SELECT airport_code FROM airports 
            WHERE city = 'St. Petersburg'
        )
    ) AS spb_flights
FROM flights;

-- TASK 6

SELECT flight_id AS actual_departure,
    (actual_arrival - LAG(actual_arrival, 1) OVER (ORDER BY flight_id)) AS prev_dep_interval,
    (LEAD(actual_arrival, 1) OVER (ORDER BY flight_id) - actual_arrival) AS next_dep_interval 
FROM flights
WHERE status = 'Arrived';

-- TASK 7

WITH consecutive_bookings AS (
    SELECT t.passenger_id, t.passenger_name,
    b.book_ref, b.book_date, b.total_amount,
    RANK() OVER (ORDER BY b.total_amount DESC) as r_amount,
    LAG(b.total_amount, 1) OVER (ORDER BY b.book_date) as prev1,
    LAG(b.total_amount, 2) OVER (ORDER BY b.book_date) as prev2,
    LAG(b.total_amount, 3) OVER (ORDER BY b.book_date) as prev3,
    LAG(b.total_amount, 4) OVER (ORDER BY b.book_date) as prev4
    FROM tickets t
    JOIN bookings b ON t.book_ref = b.book_ref
)
SELECT passenger_id, passenger_name, total_amount,
    (COALESCE(prev1, 0) + COALESCE(prev2, 0) + COALESCE(prev3, 0) + COALESCE(prev4, 0) + total_amount) as consecutive_sum
FROM consecutive_bookings
WHERE r_amount = 1
LIMIT 1;