-- TASK 1

SELECT flight_id, EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60 as time_diff FROM flights
WHERE status = 'Arrived' AND EXTRACT(EPOCH FROM (actual_arrival - scheduled_arrival)) / 60 >= 30;

-- TASK 2

SELECT passenger_name, contact_data ->> 'phone' as phone_number from tickets
WHERE (passenger_name LIKE 'A%' or passenger_name LIKE 'a%') AND (contact_data->> 'phone' IS NOT NULL)
ORDER BY passenger_name ASC;

-- TASK 3

SELECT tickets.passenger_name, MAX(ticket_flights.amount) AS max_price FROM tickets
JOIN ticket_flights ON tickets.ticket_no = ticket_flights.ticket_no 
GROUP BY tickets.passenger_name;

-- TASK 4
-- выведите всех пассажиров которые НЕ бронировали билеты эконом класса в январе 2016 года
SELECT t.passenger_name FROM tickets t
WHERE NOT EXISTS (
    SELECT 1 FROM ticket_flights tf
    JOIN flights ON tf.flight_id = flights.flight_id
    JOIN seats ON flights.aircraft_code = seats.aircraft_code
    WHERE  tf.ticket_no = t.ticket_no AND seats.fare_conditions = 'Economy' 
        AND t.book_ref IN (
          SELECT book_ref FROM bookings 
          WHERE book_date >= '2016-01-01' AND book_date < '2016-02-01'
      )
);

SELECT DISTINCT t.passenger_id, t.passenger_name
FROM bookings.tickets t
LEFT JOIN (
    SELECT tf.ticket_no
    FROM bookings.ticket_flights tf
    JOIN bookings.flights f ON tf.flight_id = f.flight_id
    WHERE tf.fare_conditions = 'Economy'
    AND f.scheduled_departure >= '2016-01-01' 
    AND f.scheduled_departure < '2016-02-01'
) eco_tickets ON t.ticket_no = eco_tickets.ticket_no
WHERE eco_tickets.ticket_no IS NULL;

-- TASK 5

--  St. Petersburg
-- Moscow

(
    SELECT airports.city AS departure_city, COUNT(*) AS flights_count 
    FROM flights 
    JOIN airports ON flights.departure_airport = airports.airport_code
    WHERE airports.city = 'Moscow'
    GROUP BY airports.city
)
UNION ALL
(
    SELECT airports.city AS departure_city, COUNT(*) AS flights_count 
    FROM flights JOIN airports ON flights.departure_airport = airports.airport_code
    WHERE  airports.city = 'St. Petersburg'
    GROUP BY airports.city
);

-- TASK 6

SELECT flight_id AS actual_departure,
    (actual_departure - LAG(actual_departure, 1) OVER (ORDER BY flight_id)) AS prev_dep_interval,
    (LEAD(actual_departure, 1) OVER (ORDER BY flight_id) - actual_departure) AS next_dep_interval 
FROM flights
WHERE status = 'Arrived';

-- TASK 7

WITH consecutive_bookings AS (
    SELECT t.passenger_id, t.passenger_name,
    b.book_ref, b.book_date, b.total_amount,
    SUM(b.total_amount) OVER (ORDER BY b.book_date ROWS BETWEEN 4 PRECEDING AND CURRENT ROW) as total_amount_5
    FROM tickets t
    JOIN bookings b ON t.book_ref = b.book_ref
)
SELECT passenger_id, passenger_name, total_amount, book_date, 
    total_amount_5 as consecutive_sum
FROM consecutive_bookings
ORDER BY consecutive_sum DESC
LIMIT 1;

-- TASK 8

SELECT DISTINCT (passenger_id, passenger_name) AS passenger_credits, scheduled_departure FROM tickets_extendent
    WHERE age = 50 AND departure_airport = 'LED' AND arrival_airport = 'DME'
        AND (scheduled_departure BETWEEN '2015-06-01' AND '2016-04-30');

CREATE INDEX idx_tickets_extendent ON tickets_extendent (
    age, departure_airport, arrival_airport, scheduled_departure
);