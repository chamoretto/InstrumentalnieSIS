--Отмена билета и отмена брони
--Запись о билете / брони
--Запись об отмене брони/возврате билета
DROP FUNCTION IF EXISTS ticket_returning(id_ticket INT);
CREATE OR REPLACE FUNCTION ticket_returning(id_ticket INT) RETURNS VOID
    LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE reservation SET is_cancelled = true WHERE reservation_id = (SELECT reservation_id FROM ticket WHERE ticket_id = id_ticket);
    UPDATE ticket SET is_returned = true WHERE ticket.ticket_id = id_ticket;
END;
$$;

---------------------------------------------------------------------------------------------------------------

DROP FUNCTION IF EXISTS reservation_canceling(id_reservation INT);
CREATE OR REPLACE FUNCTION reservation_canceling(id_reservation INT) RETURNS VOID
    LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE reservation SET is_cancelled = true WHERE reservation.reservation_id = id_reservation;
END;
$$;


--Перенос полёта
--Данные о состоянии техники, погоде и других обстоятельствах, способных повлиять на перенос
--Уведомление о переносе полёта Предложение компенсации от компании
CREATE OR REPLACE FUNCTION flight_rescheduling(id_flight INT, new_time TIMESTAMP) RETURNS TEXT
    LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE flight SET departure_datetime = new_time WHERE flight.flight_id = id_flight;
    RETURN(SELECT customer_id FROM customer WHERE customer_id = (SELECT customer_id FROM ticket WHERE flight_id = (SELECT flight_id FROM flight WHERE flight.flight_id = id_flight))
                                     OR (SELECT customer_id FROM reservation WHERE flight_id = (SELECT flight_id FROM flight WHERE flight.flight_id = id_flight)));
END;
$$;

--Групповая закупка билетов
--Клиентские данные
--Билеты