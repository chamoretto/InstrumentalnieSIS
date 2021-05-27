-- DROP TRIGGER if exists check_update
-- При изменении статуса на выкуплена, добовляем запись о билете
CREATE OR REPLACE FUNCTION create_ticket_by_paid_reservation() RETURNS TRIGGER
    LANGUAGE plpgsql AS
$$
BEGIN

    -- тебе надо место найти
    INSERT INTO ticket (customer_id, flight_id, reservation_id, place, bought_at, is_returned)
    VALUES ((NEW.customer_id)::int,
            (NEW.flight_id)::int,
            (NEW.reservation_id)::int,
            (NEW.place)::int,
            CURRENT_TIMESTAMP,
            true);
    RETURN null;
EXCEPTION
    -- если ошибка - печатаем в консоль. транзакция откатится автоматически
    WHEN OTHERS THEN
        RAISE NOTICE 'ошибка';
END;
$$;

DROP TRIGGER IF EXISTS check_update ON reservation;
CREATE TRIGGER check_update
    AFTER UPDATE
    ON reservation
    FOR EACH ROW
    WHEN (NEW.state = 'redeemed'::reservation_state)
EXECUTE FUNCTION create_ticket_by_paid_reservation();

DROP TRIGGER IF EXISTS check_update ON reservation;

--

