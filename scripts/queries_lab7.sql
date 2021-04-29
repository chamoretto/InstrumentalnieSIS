-- Анализ выкупаемости брони по рейсам || Рейтинг рейсов по выкупаемости брони
SELECT inner_query.voyage_id                      as "ID Рейса",
       inner_query.voyage_title                   as "Название рейса",
       COUNT(inner_query.reservation_id)          as "Общее кол-во броней",
       COUNT(inner_query.is_cancelled)            as "Заполненное количество место",
       float4div(COUNT(inner_query.reservation_id),
                 COUNT(inner_query.is_cancelled)) as "Коэф. заполняемости выкупаемости "

FROM (SELECT v.voyage_id as voyage_id,
             v.title     as voyage_title,
             res.reservation_id,
             res.is_cancelled
      FROM flight
               JOIN aircraft a on a.aircraft_id = flight.aircraft_id
               JOIN reservation as res on flight.flight_id = res.flight_id
               JOIN ticket on flight.flight_id = ticket.flight_id
               JOIN voyage v on v.voyage_id = flight.voyage_id

      GROUP BY v.voyage_id, res.reservation_id, flight.flight_id, v.title
     ) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title, inner_query.reservation_id
ORDER BY 5 DESC;


--
SELECT cr.c, all_r.c, float4div(cr.c, all_r.c)
FROM (SELECT COUNT(is_cancelled) as c FROM reservation WHERE is_cancelled = true) cr,
     (SELECT flight_id, COUNT(is_cancelled) as c FROM reservation) all_r;

-- шоша
SELECT cr.voyage_id             as "ID Рейса",
       cr.c                     as "Отменённые брони",
       all_r.c                  as "Все брони",
       float4div(cr.c, all_r.c) as "Доля отменённых броней."
FROM (SELECT v.voyage_id, COUNT(is_cancelled) as c
      FROM reservation r
               INNER JOIN flight f ON f.flight_id = r.flight_id
               INNER JOIN voyage v ON v.voyage_id = f.voyage_id
      WHERE is_cancelled = true
      GROUP BY v.voyage_id
     ) cr
         INNER JOIN (SELECT v.voyage_id, COUNT(is_cancelled) as c
                     FROM reservation r
                              INNER JOIN flight f ON f.flight_id = r.flight_id
                              INNER JOIN voyage v ON v.voyage_id = f.voyage_id
                     GROUP BY v.voyage_id
) all_r ON cr.voyage_id = all_r.voyage_id


-- INNER JOIN flight f ON f.flight_id = cr.flight_id OR f.flight_id = all_r.flight_id
-- INNER JOIN voyage v ON v.voyage_id = f.voyage_id
-- GROUP BY v.voyage_id, f.flight_id
;

SELECT voyage.voyage_id, float4div(cr.c, all_r.c)
FROM voyage
         INNER JOIN flight f on voyage.voyage_id = f.voyage_id
         INNER JOIN reservation r on f.flight_id = r.flight_id
         INNER JOIN (SELECT COUNT(is_cancelled) as c
                     FROM reservation r
                              INNER JOIN flight f ON f.flight_id = r.flight_id
                              INNER JOIN voyage v ON v.voyage_id = f.voyage_id
                     WHERE is_cancelled = true
                     GROUP BY reservation_id)
         INNER JOIN (SELECT flight_id, COUNT(is_cancelled) as c FROM reservation r GROUP BY reservation_id) all_r
                    ON all_r.flight_id = f.flight_id
;

SELECT *
FROM (SELECT v.voyage_id, COUNT(is_cancelled) as c
      FROM reservation r
               INNER JOIN flight f ON f.flight_id = r.flight_id
               INNER JOIN voyage v ON v.voyage_id = f.voyage_id
      WHERE is_cancelled = true
      GROUP BY v.voyage_id
) as cr
   , (SELECT v.voyage_id, COUNT(is_cancelled) as c
      FROM reservation r
               INNER JOIN flight f ON f.flight_id = r.flight_id
               INNER JOIN voyage v ON v.voyage_id = f.voyage_id
      GROUP BY v.voyage_id) as all_r -- all
;

--- ваня
SELECT v.voyage_id, v.title, cr.cancelled, all_r.reserve, float4div(cr.cancelled, all_r.reserve)
FROM (SELECT COUNT(is_cancelled) as cancelled FROM reservation WHERE is_cancelled = true) cr,
     (SELECT flight_id, COUNT(is_cancelled) as reserve FROM reservation GROUP BY flight_id) all_r

         join flight on flight.flight_id = all_r.flight_id
         join voyage v on flight.voyage_id = v.voyage_id
GROUP BY v.voyage_id, cr.cancelled, all_r.reserve;



-- сделать запрос который по рейсам группирует брони и считает общую сумму брони по рейсам
--SELECT cr.flight_id, cr.c, all_r.c, float4div(cr.c, all_r.c) as "поделили"
-- FROM (SELECT flight_id, COUNT(is_cancelled) as c FROM reservation WHERE is_cancelled=true GROUP BY reservation_id) cr
--     INNER JOIN (SELECT flight_id, COUNT(is_cancelled) as c FROM reservation GROUP BY reservation_id) all_r ON cr.flight_id = all_r.flight_id


------------------------------------------------------------------------------------------------------------------------
--                                        ГОТОВЫЕ
------------------------------------------------------------------------------------------------------------------------

-- 1. Анализ заполняемости рейса || Рейтинг рейсов по проданным билетам
SELECT inner_query.voyage_id                     as "ID Рейса",
       inner_query.voyage_title                  as "Название рейса",
       SUM(inner_query.places_number)            as "Ожидаемое количество мест",
       SUM(inner_query.count_of_bought_tickets)  as "Заполненное количество место",
       float4div(SUM(inner_query.count_of_bought_tickets),
                 SUM(inner_query.places_number)) as "Коэф. заполняемости, больше = лучше"

FROM (SELECT v.voyage_id             as voyage_id,
             v.title                 as voyage_title,
             ac_t.places_number      as places_number,
             COUNT(ticket.ticket_id) as count_of_bought_tickets
      FROM flight
               JOIN aircraft a on a.aircraft_id = flight.aircraft_id
               JOIN aircraft_type ac_t on a.aircraft_type_id = ac_t.aircraft_type_id
               JOIN ticket on flight.flight_id = ticket.flight_id
               JOIN voyage v on v.voyage_id = flight.voyage_id

      GROUP BY v.voyage_id, flight.flight_id, ac_t.manufacturer, ac_t.model, ac_t.places_number, v.title) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title
ORDER BY 5 DESC;


--2.  Анализ выкупаемости брони по рейсам || Рейтинг рейсов по выкупаемости брони
SELECT cr.voyage_id             as "ID Рейса",
       cr.c                     as "Отменённые брони",
       all_r.c                  as "Все брони",
       float4div(cr.c, all_r.c) as "Доля отменённых броней."
FROM (SELECT v.voyage_id, COUNT(is_cancelled) as c
      FROM reservation r
               INNER JOIN flight f ON f.flight_id = r.flight_id
               INNER JOIN voyage v ON v.voyage_id = f.voyage_id
      WHERE is_cancelled = true
      GROUP BY v.voyage_id
     ) cr
         INNER JOIN (SELECT v.voyage_id, COUNT(is_cancelled) as c
                     FROM reservation r
                              INNER JOIN flight f ON f.flight_id = r.flight_id
                              INNER JOIN voyage v ON v.voyage_id = f.voyage_id
                     GROUP BY v.voyage_id
) all_r ON cr.voyage_id = all_r.voyage_id;


-- 3. Анализ окупаемости авиапарка || Рейтинг самых окупаемых самолётов
SELECT aircraft_type.aircraft_type_id,
       aircraft_type.model,
       aircraft_type.manufacturer,
       SUM(flight.raw_estimated_cost) as profit
FROM flight
         LEFT OUTER JOIN aircraft ON aircraft.aircraft_id = flight.aircraft_id
         LEFT OUTER JOIN aircraft_type on aircraft.aircraft_type_id = aircraft_type.aircraft_type_id
GROUP BY aircraft_type.aircraft_type_id
ORDER BY profit DESC;


-- 4. Прибыль каждого рейса, разбитая по его сезонам
SELECT iq.title, iq.season, SUM(iq.profit) as season_profit
FROM (
         SELECT v.title, f.raw_estimated_cost as profit, 'winter' as season
         FROM flight as f
                  JOIN voyage v on f.voyage_id = v.voyage_id
         WHERE EXTRACT(MONTH from f.departure_datetime) = 12
            OR EXTRACT(MONTH from f.departure_datetime) = 1
            OR EXTRACT(MONTH from f.departure_datetime) = 2

         UNION ALL

         SELECT v.title, f.raw_estimated_cost as profit, 'spring' as season
         FROM flight as f
                  JOIN voyage v on f.voyage_id = v.voyage_id
         WHERE EXTRACT(MONTH from f.departure_datetime) >= 3
           AND EXTRACT(MONTH from f.departure_datetime) <= 5

         UNION ALL

         SELECT v.title, f.raw_estimated_cost as profit, 'summer' as season
         FROM flight as f
                  JOIN voyage v on f.voyage_id = v.voyage_id
         WHERE EXTRACT(MONTH from f.departure_datetime) >= 6
           AND EXTRACT(MONTH from f.departure_datetime) <= 8

         UNION ALL

         SELECT v.title, f.raw_estimated_cost as profit, 'autumn' as season
         FROM flight as f
                  JOIN voyage v on f.voyage_id = v.voyage_id
         WHERE EXTRACT(MONTH from f.departure_datetime) >= 9
           AND EXTRACT(MONTH from f.departure_datetime) <= 11) iq
GROUP BY iq.title, iq.season
ORDER BY iq.title, array_position(array ['winter', 'sprint', 'summer', 'autumn'], iq.season);


-- BONUS TRACK, запрос из незаявленных. Анализ прибыли рейсов || Рейтинг самых прибыльных рейсов
SELECT inner_query.voyage_id          as "ID Рейса",
       inner_query.voyage_title       as "Название рейса",
       COUNT(inner_query.flight_cost) as "Количество полётов по рейсу",
       SUM(inner_query.flight_cost)   as "Итоговая прибыль по рейсу"

FROM (SELECT v.voyage_id               as voyage_id,
             v.title                   as voyage_title,
             flight.raw_estimated_cost as flight_cost
      FROM flight
               JOIN aircraft a on a.aircraft_id = flight.aircraft_id
               JOIN aircraft_type ac_t on a.aircraft_type_id = ac_t.aircraft_type_id
               JOIN ticket on flight.flight_id = ticket.flight_id
               JOIN voyage v on v.voyage_id = flight.voyage_id

      GROUP BY v.voyage_id, flight.flight_id, ac_t.manufacturer, ac_t.model, ac_t.places_number, v.title) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title
ORDER BY 4 DESC;