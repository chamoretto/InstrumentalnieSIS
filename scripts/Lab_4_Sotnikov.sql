--Отмена билета и отмена брони
--Запись о билете / брони
--Запись об отмене брони/возврате билета
DROP FUNCTION IF EXISTS ticket_returning(id_ticket INT);
CREATE OR REPLACE FUNCTION ticket_returning(id_ticket INT) RETURNS VOID
    LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE reservation
    SET is_cancelled = true
    WHERE reservation_id = (SELECT reservation_id FROM ticket WHERE ticket_id = id_ticket);
    UPDATE ticket SET is_returned = true WHERE ticket.ticket_id = id_ticket;
END;
$$;

-- > МОДИФИКАЦИЯ ОДНОГО ОБЪЕКТА <
-- ОПИСАНИЕ: Выпуск билета после оплаты брони
-- ОБЛАСТЬ: Информационные системы аэропорта
-- Электронное/физическое воплощение билета после оплаты брони
CREATE OR REPLACE FUNCTION create_ticket_by_paid_reservation(paid_reservation json) RETURNS int
    LANGUAGE plpgsql AS
$$
BEGIN

    INSERT INTO ticket (customer_id, flight_id, reservation_id, place, bought_at, is_returned)
    VALUES ((paid_reservation ->> 'customer_id')::int,
            (paid_reservation ->> 'flight_id')::int,
            (paid_reservation ->> 'reservation_id')::int,
            (paid_reservation ->> 'place')::int,
            CURRENT_TIMESTAMP,
            true);
    RETURN 0;

EXCEPTION
    -- если ошибка - печатаем в консоль. транзакция откатится автоматически
    WHEN OTHERS THEN
        RETURN 1;
END;
$$;

SELECT create_ticket_by_paid_reservation(
   (SELECT row_to_json(r.*) FROM reservation r WHERE r.reservation_id = 3 LIMIT 1)
);

---------------------------------------------------------------------------------------------------------------


DROP FUNCTION IF EXISTS reservation_canceling(id_reservation INT);
CREATE OR REPLACE FUNCTION reservation_canceling(id_reservation INT) RETURNS int
    LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE reservation SET is_cancelled = true WHERE reservation.reservation_id = id_reservation;
    RETURN 0;

EXCEPTION
    -- если ошибка - печатаем в консоль. транзакция откатится автоматически
    WHEN OTHERS THEN
        RETURN 1;
END;
$$;


--Групповая закупка билетов
--Клиентские данные
--Билеты

-- ?????????????