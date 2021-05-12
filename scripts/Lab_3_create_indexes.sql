-- -- -- Сотников запрос 1, колонки в JOIN
-- CREATE INDEX IF NOT EXISTS flight_aircraft_id_idx ON flight (aircraft_id);
-- CREATE INDEX IF NOT EXISTS aircraft_aircraft_type_id_idx ON aircraft (aircraft_type_id);
-- CREATE INDEX IF NOT EXISTS ticket_flight_id_idx ON ticket (flight_id);
-- CREATE INDEX IF NOT EXISTS flight_voyage_id_idx ON flight (voyage_id);
-- -- -- Сотников запрос 2, колонки в JOIN
-- CREATE INDEX IF NOT EXISTS reservation_flight_id_idx ON reservation (flight_id);
-- CREATE INDEX IF NOT EXISTS reservation_is_cancelled_idx ON reservation (is_cancelled); -- просто колонка
-- -- -- Чамор
-- CREATE INDEX IF NOT EXISTS flight_departure_datetime_idx ON flight (departure_datetime); -- просто колонка

-- -- Сотников запрос 1, колонки в JOIN
CREATE INDEX flight_aircraft_id_idx ON flight USING HASH (aircraft_id);
CREATE INDEX aircraft_aircraft_type_id_idx ON aircraft USING HASH (aircraft_type_id);
CREATE INDEX IF NOT EXISTS ticket_flight_id_idx ON ticket USING HASH (flight_id);
CREATE INDEX IF NOT EXISTS flight_voyage_id_idx ON flight USING HASH (voyage_id);
-- -- Сотников запрос 2, колонки в JOIN
CREATE INDEX IF NOT EXISTS reservation_flight_id_idx ON reservation USING HASH (flight_id);
CREATE INDEX IF NOT EXISTS reservation_is_cancelled_idx ON reservation USING HASH (is_cancelled);
-- -- Чамор
CREATE INDEX IF NOT EXISTS flight_departure_datetime_idx ON flight USING HASH (departure_datetime);
