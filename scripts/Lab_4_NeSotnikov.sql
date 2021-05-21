-- > МОДИФИКАЦИЯ ОДНОГО ОБЪЕКТА <
-- Перенос полёта
-- Данные о состоянии техники, погоде и других обстоятельствах, способных повлиять на перенос
-- Уведомление о переносе полёта Предложение компенсации от компании
CREATE OR REPLACE FUNCTION flight_rescheduling(id_flight INT, new_time TIMESTAMP) RETURNS TEXT
    LANGUAGE plpgsql AS
$$
BEGIN
    UPDATE flight SET departure_datetime = new_time WHERE flight.flight_id = id_flight;
    RETURN(SELECT customer_id FROM customer WHERE customer_id = (SELECT customer_id FROM ticket WHERE flight_id = id_flight)
                                     OR (SELECT customer_id FROM reservation WHERE flight_id = id_flight));
END;
$$;

-- > КОЛЛЕКЦИЯ <
-- Ежеквартальная планировка полётов
-- Данные о рейсах и полётах
-- Расписание полётов на квартал
-- > -------------------------------------------------------------------------------- <

-- > БУДУЩИЙ ТРИГГЕР <
-- Автоотмена полёта при нулевом выкупе
-- Информация о полёте и билетах
-- Уведомление клиентам об отмене полёта
-- > -------------------------------------------------------------------------------- <
