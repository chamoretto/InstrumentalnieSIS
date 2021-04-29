-- noinspection NonAsciiCharactersForFile

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
                  JOIN aircraft_type ac_t on a.aircraft_type_id =
                                             ac_t.aircraft_type_id
                  JOIN ticket on flight.flight_id = ticket.flight_id
                  JOIN voyage v on v.voyage_id = flight.voyage_id
         GROUP BY v.voyage_id, flight.flight_id, ac_t.manufacturer, ac_t.model,
                  ac_t.places_number, v.title
     ) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title
ORDER BY 5 DESC;

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

SELECT aircraft_type.aircraft_type_id,
       aircraft_type.model,
       aircraft_type.manufacturer,
       SUM(flight.raw_estimated_cost) as profit
FROM flight
         LEFT OUTER JOIN aircraft ON aircraft.aircraft_id = flight.aircraft_id
         LEFT OUTER JOIN aircraft_type on aircraft.aircraft_type_id = aircraft_type.aircraft_type_id
GROUP BY aircraft_type.aircraft_type_id
ORDER BY profit DESC;

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
               JOIN aircraft_type ac_t on a.aircraft_type_id =
                                          ac_t.aircraft_type_id
               JOIN ticket on flight.flight_id = ticket.flight_id
               JOIN voyage v on v.voyage_id = flight.voyage_id
      GROUP BY v.voyage_id, flight.flight_id, ac_t.manufacturer, ac_t.model,
               ac_t.places_number, v.title) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title
ORDER BY 4 DESC;