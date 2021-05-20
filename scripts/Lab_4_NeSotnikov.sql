-- > МОДИФИКАЦИЯ ОДНОГО ОБЪЕКТА <
-- ОПИСАНИЕ: Выпуск билета после оплаты брони
-- ОБЛАСТЬ: Информационные системы аэропорта
-- Электронное/физическое воплощение билета после оплаты брони
-- > -------------------------------------------------------------------------------- <

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

-- Темплейтик функции

CREATE OR REPLACE FUNCTION create_ticket_by_paid_reservation(paid_reservation json, place_ int) RETURNS void
    LANGUAGE plpgsql AS
$$
BEGIN

    INSERT INTO ticket (customer_id, flight_id, reservation_id, place, bought_at, is_returned)
    VALUES ((paid_reservation->>'customer_id')::int,
            (paid_reservation->>'flight_id')::int,
            (paid_reservation->>'reservation_id')::int,
            place_,
            CURRENT_TIMESTAMP,
             true);

EXCEPTION
    -- если ошибка - печатаем в консоль. транзакция откатится автоматически
    WHEN OTHERS THEN
        RAISE NOTICE 'ОШИБКА!';
END;
$$;

SELECT create_ticket_by_paid_reservation(
    (SELECT row_to_json(r.*) FROM reservation r WHERE r.reservation_id = 3 LIMIT 1),
    22222
);