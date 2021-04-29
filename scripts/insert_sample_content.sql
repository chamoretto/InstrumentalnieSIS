CREATE OR REPLACE FUNCTION load_sample_content(OUT void)
AS
$$
COPY customer (surname, firstname, patronymic, passport_series, passport_number, phone_number)
    FROM '/home/data/customers.csv' WITH DELIMITER ',';
COPY aircraft_type
    FROM '/home/data/aircraft_types.csv' WITH DELIMITER ',';
COPY aircraft_places (service_class, range_start, range_end, aircraft_type_id)
    FROM '/home/data/aircraft_places.csv' WITH DELIMITER ',';
COPY aircraft
    FROM '/home/data/aircrafts.csv' WITH DELIMITER ',';
COPY voyage
    FROM '/home/data/voyages.csv' WITH DELIMITER ',' CSV;
$$
    LANGUAGE SQL;
SELECT load_sample_content();