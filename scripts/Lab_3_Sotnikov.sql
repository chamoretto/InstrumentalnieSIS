-- noinspection NonAsciiCharactersForFile

                                  -- -- -- --   -- -- -- --
                                  -- -- -- indexes -- -- --

-- УДАЛИТЬ ИНДЕКСЫ

                                    -- -- -- -- -- -- --
                                    -- -- -- v1 -- -- --

-- Запрос выводит сведения о заполняемости мест относительно рейсов.
-- Чем выше коэффициент, тем выше заполняемость рейса.
SELECT inner_query.voyage_id                     as "ID Рейса",
       inner_query.voyage_title                  as "Название рейса",
       SUM(inner_query.places_number)            as "Ожидаемое количество мест",
       SUM(inner_query.count_of_bought_tickets)  as "Заполненное количество место",
       float4div(SUM(inner_query.count_of_bought_tickets),
                 SUM(inner_query.places_number)) as "Коэф. заполняемости, больше = лучше"
FROM (
         SELECT v.voyage_id             as voyage_id,
                v.title                 as voyage_title,
                ac_t.places_number      as places_number,
                COUNT(ticket.ticket_id) as count_of_bought_tickets
         FROM flight
                  JOIN aircraft a on a.aircraft_id = flight.aircraft_id
                  JOIN aircraft_type ac_t on ac_t.aircraft_type_id = a.aircraft_type_id
                  JOIN ticket on ticket.flight_id = flight.flight_id
                  JOIN voyage v on v.voyage_id = flight.voyage_id
         GROUP BY v.voyage_id, flight.flight_id, ac_t.manufacturer, ac_t.model, ac_t.places_number, v.title
     ) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title
ORDER BY 5 DESC;

-- Запрос выводит сведения о выкупаемости броней на каждый рейс.
-- Чем меньше отменённых броней, тем лучше.
SELECT cr.voyage_id             as "ID Рейса",
       cr.c                     as "Отменённые брони",
       all_r.c                  as "Все брони",
       float4div(cr.c, all_r.c) as "Доля отменённых броней."
FROM (
         SELECT v.voyage_id, COUNT(is_cancelled) as c
         FROM reservation r
                  INNER JOIN flight f ON f.flight_id = r.flight_id
                  INNER JOIN voyage v ON v.voyage_id = f.voyage_id
         WHERE is_cancelled = true
         GROUP BY v.voyage_id
     ) cr
         INNER JOIN (
    SELECT v.voyage_id, COUNT(is_cancelled) as c
    FROM reservation r
             INNER JOIN flight f ON f.flight_id = r.flight_id
             INNER JOIN voyage v ON v.voyage_id = f.voyage_id
    GROUP BY v.voyage_id
) all_r ON cr.voyage_id = all_r.voyage_id;


                                  -- -- -- --   -- -- -- --
                                  -- -- -- indexes -- -- --

-- ТУТ НУЖНО СОЗДАТЬ ИНДЕКСЫ
                                    -- -- -- -- -- -- --
                                    -- -- -- v2 -- -- --
