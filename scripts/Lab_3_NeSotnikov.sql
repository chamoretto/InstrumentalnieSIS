-- noinspection NonAsciiCharactersForFile

                                  -- -- -- --   -- -- -- --
                                  -- -- -- indexes -- -- --

-- УДАЛИТЬ ИНДЕКСЫ

                                    -- -- -- -- -- -- --
                                    -- -- -- v1 -- -- --

-- Запрос выводит данные о том, сколько денег приходится на каждую из моделей самолётов.
-- Таким образом мы можем судить о выгодности моделей.
SELECT aircraft_type.aircraft_type_id,
       aircraft_type.model,
       aircraft_type.manufacturer,
       SUM(flight.raw_estimated_cost) as profit
FROM flight
         LEFT OUTER JOIN aircraft ON aircraft.aircraft_id = flight.aircraft_id
         LEFT OUTER JOIN aircraft_type on aircraft.aircraft_type_id = aircraft_type.aircraft_type_id
GROUP BY aircraft_type.aircraft_type_id
ORDER BY profit DESC;

-- Запрос выводит данные о посезонной прибыли каждого рейса.
-- Исходя из него можно судить о том, в какой период времени рейс наиболее выгоден.
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

-- Дополнительный запрос. Общий анализ прибыли рейсов в формате рейтинга рейсов по прибыльности
SELECT inner_query.voyage_id          as "ID Рейса",
       inner_query.voyage_title       as "Название рейса",
       COUNT(inner_query.flight_cost) as "Количество полётов по рейсу",
       SUM(inner_query.flight_cost)   as "Итоговая прибыль по рейсу"
FROM (
         SELECT v.voyage_id               as voyage_id,
                v.title                   as voyage_title,
                flight.raw_estimated_cost as flight_cost
         FROM flight
                  JOIN aircraft a on a.aircraft_id = flight.aircraft_id
                  JOIN aircraft_type ac_t on ac_t.aircraft_type_id = a.aircraft_type_id
                  JOIN ticket on ticket.flight_id = flight.flight_id
                  JOIN voyage v on v.voyage_id = flight.voyage_id
         GROUP BY v.voyage_id, flight.flight_id, ac_t.manufacturer, ac_t.model, ac_t.places_number, v.title
     ) as inner_query
GROUP BY inner_query.voyage_id, inner_query.voyage_title
ORDER BY 4 DESC;
                                  -- -- -- --   -- -- -- --
                                  -- -- -- indexes -- -- --

-- ТУТ НУЖНО СОЗДАТЬ ИНДЕКСЫ
                                    -- -- -- -- -- -- --
                                    -- -- -- v2 -- -- --
