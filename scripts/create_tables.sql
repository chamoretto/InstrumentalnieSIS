-- ENUMS --
CREATE TYPE service_class AS ENUM ('economy_class', 'business_class', 'first_class');
ALTER TYPE service_class OWNER TO bdis;

CREATE TYPE reservation_state AS ENUM ('not_redeemed', 'redeemed', 'expired');
ALTER TYPE reservation_state OWNER TO bdis;

-- TABLES --
CREATE TABLE customer -- клиенты --
(
    customer_id     SERIAL      NOT NULL -- Автоинкремент --
        CONSTRAINT customer_pkey PRIMARY KEY,
    surname         VARCHAR(64) NOT NULL,
    firstname       VARCHAR(64) NOT NULL,
    patronymic      VARCHAR(64) DEFAULT NULL,
    passport_series INTEGER     NOT NULL,
    passport_number INTEGER     NOT NULL,
    phone_number    VARCHAR(15) DEFAULT NULL
);
ALTER TABLE customer
    OWNER TO bdis;

CREATE TABLE aircraft_type -- тип самолёта
(
    aircraft_type_id SERIAL      NOT NULL -- Автоинкремент
        CONSTRAINT aircraft_type_pkey PRIMARY KEY,
    model            VARCHAR(64) NOT NULL,
    manufacturer     VARCHAR(64) NOT NULL,
    places_number    INTEGER     NOT NULL,
    max_flight_range INTEGER     NOT NULL
);
ALTER TABLE aircraft_type
    OWNER TO bdis;


CREATE TABLE aircraft -- таблица самих самолётов
(
    aircraft_id           SERIAL  NOT NULL            -- Автоинкремент
        CONSTRAINT aircraft_pkey PRIMARY KEY,
    bought_at             DATE    NOT NULL,           -- дата покупки
    total_flying_distance INTEGER NOT NULL DEFAULT 0, -- полная налётанная самолётом дистанция
    aircraft_type_id      INTEGER NOT NULL
        CONSTRAINT aircraft_aircraft_type_id_fkey REFERENCES aircraft_type ON DELETE RESTRICT
);
ALTER TABLE aircraft
    OWNER TO bdis;


CREATE TABLE aircraft_places -- таблица, соотносящаяся тип самолёта и рейнджи мест
(
    aircraft_places_id SERIAL        NOT NULL  -- Автоинкремент --
        CONSTRAINT aircraft_places_pkey PRIMARY KEY,
    service_class      service_class NOT NULL, -- класс обслуживания мест
    range_start        INTEGER       NOT NULL, -- начало, ВКЛЮЧАЯ
    range_end          INTEGER       NOT NULL, -- конец, ВКЛЮЧАЯ
    aircraft_type_id   INTEGER       NOT NULL
        CONSTRAINT aircraft_places_aircraft_type_id_fkey REFERENCES aircraft_type ON DELETE RESTRICT
);
ALTER TABLE aircraft_places
    OWNER TO bdis;


CREATE TABLE voyage -- регулярные рейсы
(
    voyage_id         SERIAL      NOT NULL  -- Автоинкремент --
        CONSTRAINT voyage_pkey PRIMARY KEY,
    title             VARCHAR(64) NOT NULL,
    departure_point   VARCHAR(64) NOT NULL, -- пункт отправки
    destination_point VARCHAR(64) NOT NULL, -- пункт назначения
    max_flight_range  INTEGER     NOT NULL,
    created_at        DATE        NOT NULL,
    aircraft_type_id  INTEGER     NOT NULL
        CONSTRAINT voyage_aircraft_type_id_fkey REFERENCES aircraft_type ON DELETE RESTRICT
);
ALTER TABLE voyage
    OWNER TO bdis;


CREATE TABLE flight -- конкретные разовые полёты
(
    flight_id          SERIAL    NOT NULL  -- Автоинкремент --
        CONSTRAINT flight_pkey PRIMARY KEY,
    voyage_id          INTEGER   NOT NULL
        CONSTRAINT flight_voyage_id_fkey REFERENCES voyage ON DELETE RESTRICT,
    aircraft_id        INTEGER   NOT NULL
        CONSTRAINT flight_aircraft_id_fkey REFERENCES aircraft ON DELETE RESTRICT,
    raw_estimated_cost INTEGER   NOT NULL, -- ожидаемая стоимость полёта
    departure_datetime TIMESTAMP NOT NULL  -- время отправки
);
ALTER TABLE flight
    OWNER TO bdis;

CREATE TABLE reservation -- брони
(
    reservation_id SERIAL            NOT NULL -- Автоинкремент --
        CONSTRAINT reservation_pkey PRIMARY KEY,
    customer_id    INTEGER           NULL
        CONSTRAINT reservation_customer_id_fkey REFERENCES customer ON DELETE RESTRICT,
    flight_id      INTEGER           NOT NULL
        CONSTRAINT reservation_flight_id_fkey REFERENCES flight ON DELETE RESTRICT,
    is_cancelled   boolean           NOT NULL DEFAULT false,
    state          reservation_state NOT NULL
);
ALTER TABLE reservation
    OWNER TO bdis;


CREATE TABLE ticket -- билеты
(
    ticket_id      SERIAL  NOT NULL -- Автоинкремент --
        CONSTRAINT ticket_pkey PRIMARY KEY,
    customer_id    INTEGER NOT NULL
        CONSTRAINT ticket_customer_id_fkey REFERENCES customer ON DELETE RESTRICT,
    flight_id      INTEGER NOT NULL
        CONSTRAINT ticket_flight_id_fkey REFERENCES flight ON DELETE RESTRICT,
    reservation_id INTEGER          DEFAULT NULL
        CONSTRAINT ticket_reservation_id_fkey REFERENCES reservation ON DELETE RESTRICT,
    place          INTEGER NOT NULL,
    bought_at      DATE    NOT NULL,
    is_returned    boolean NOT NULL DEFAULT false
);
ALTER TABLE ticket
    OWNER TO bdis;

