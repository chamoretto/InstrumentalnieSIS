import asyncio
import datetime
import random
from typing import Union, List, Optional

import asyncpg
import faker
from asyncpg import Record

fake = faker.Faker(locale="ru_RU")

map_firstname_end_to_patronymic_end = {
    "ьд": "ьдович", "ян": "янович", "ий": "иевич", "ен": "енович", "ан": "анович", "ар": "арович", "др": "дрович",
    "он": "онович", "ай": "аевич", "ор": "орович", "ир": "ирович", "рс": "рсович", "ей": "еевич", "ль": "левич",
    "ат": "атович", "тр": "трович", "ит": "итович", "кс": "ксович", "ол": "олович", "еб": "ебович", "кт": "ктович",
    "ав": "авович", "ыд": "ыдович", "ст": "стович", "ил": "илович", "ид": "идович", "иф": "ифович", "нт": "нтович",
    "ом": "омович", "ва": "вович", "ел": "ович", "ын": "ынович",
}


def male_patronymic_to_female(patronymic: str) -> str:
    return f"{patronymic[:len(patronymic) - 2]}на"


def patronymic_from_firstname(firstname: str) -> str:
    end = firstname[len(firstname) - 2:]
    return f"{firstname[:len(firstname) - 2]}{map_firstname_end_to_patronymic_end.get(end, f'{end}ич')}"


def format_dict_as_insert_tuple(d: dict) -> str:
    """
    :param d: словарь вида колонка: значение
    :return: "(значение, значение, значение)" БЕЗ ЗАПЯТОЙ В КОНЦЕ
    """

    values_as_strings = []
    for v in d.values():
        if isinstance(v, int) or isinstance(v, float):
            values_as_strings.append(str(v))
        elif isinstance(v, str):
            values_as_strings.append(f"'{v}'")
        elif isinstance(v, datetime.date):
            values_as_strings.append(f"'{v.strftime('%Y-%m-%d')}'::DATE")
        elif isinstance(v, datetime.datetime):
            values_as_strings.append(f"'{v.strftime('%Y-%m-%d %H:%M:%S')}'::TIMESTAMP")
        elif v is None:
            values_as_strings.append("null")
        else:
            raise ValueError(f"НЕИЗВЕСТНЫЙ ТИП: {type(v)}, ЗНАЧЕНИЕ: {v}, КОЛОНКА: {d}")

    return f"({','.join(values_as_strings)})"


async def setup_connection(
    host: str, port: Union[int, str], database: str, user: str, password: str
) -> asyncpg.Connection:
    try:
        connection = await asyncpg.connect(host=host, port=port, database=database, user=user, password=password)

    except asyncpg.ConnectionDoesNotExistError as exc:  # if we got an exception
        raise asyncpg.ConnectionDoesNotExistError("Data is invalid or server can not be started.") from exc

    else:
        return connection


async def main():
    days_of_simulation = int(input("Введите количество дней симуляции работы аэропорта: \n"))

    connection = await setup_connection("65.21.111.96", 5444, "air-port", "bdis", "bdis")

    # фаза подготовки - проверяем базу данных. Должно быть хотя бы 1000 клиентов.
    customers: List[Record]
    async with connection.transaction():

        # разбираемся с клиентами
        customers: List[Record] = await connection.fetch("""SELECT * FROM customer""")
        if len(customers) < 1000:
            new_customers = []
            for i in range(1000):
                sex = random.randint(0, 1)  # 0 = мужчина, 1 = женщина
                male_patronymic = patronymic_from_firstname(fake.first_name_male())
                new_customers.append(
                    {
                        "surname": fake.last_name_male() if sex == 0 else fake.last_name_female(),
                        "firstname": fake.first_name_male() if sex == 0 else fake.first_name_female(),
                        "patronymic": male_patronymic if sex == 0 else male_patronymic_to_female(male_patronymic),
                        "passport_series": str(random.randint(5400, 5600)),
                        "passport_number": str(random.randint(100001, 900000)),
                        "phone_number": f"+7{random.randint(8000000001, 9999999999)}",
                    }
                )

            additional_customers = await connection.fetch(
                f"""
                INSERT INTO customer (surname, firstname, patronymic, passport_series, passport_number, phone_number)
                VALUES {','.join(format_dict_as_insert_tuple(c) for c in new_customers)} 
                RETURNING *;
                """
            )

            customers.extend(additional_customers)

        # подбираем доступные самолёты и рейсы
        voyages: List[Record] = await connection.fetch("""SELECT * FROM voyage""")

        aircrafts: List[Record] = await connection.fetch("""SELECT * FROM aircraft""")
        map_aircraft_by_type = {}
        for a in aircrafts:
            map_aircraft_by_type[a["aircraft_type_id"]] = a

        aircraft_types: List[Record] = await connection.fetch("""SELECT * FROM aircraft_type""")
        map_aircraft_type_by_id = {}
        for t in aircraft_types:
            map_aircraft_type_by_id[t["aircraft_type_id"]] = t

    map_customer_by_id = {}
    for c in customers:
        map_customer_by_id[c["customer_id"]] = c

    last_simulation_day: datetime.datetime
    reservations_count: int
    async with connection.transaction():
        last_simulation: Optional[Record] = (
            await connection.fetchrow(
                """
            SELECT departure_datetime FROM flight
            ORDER BY departure_datetime DESC
            LIMIT 1
        """
            )
        )

        if last_simulation is None:
            last_simulation_day = datetime.datetime.utcnow() - datetime.timedelta(days=300)
        else:
            last_simulation_day = last_simulation["departure_datetime"]

        reservations_count: int = (await connection.fetchrow("""SELECT COUNT(*) FROM reservation"""))["count"] + 1

    # начинаем симуляцию
    for day in range(days_of_simulation):
        print(f"День {day} из {days_of_simulation}")
        shifted = last_simulation_day + datetime.timedelta(days=day + 1)
        iteration_datetime = datetime.datetime(
            year=shifted.year,
            month=shifted.month,
            day=shifted.day,
            hour=random.randint(9, 20),
            minute=int(f"{random.randint(0, 5)}0"),
            second=00,
        )

        reservations_to_insert = []
        tickets_to_insert = []

        async with connection.transaction():
            flights_amount = random.randint(3, 6)
            voyages_this_day = []

            # собираем несколько уникальных рейсов
            while True:
                v = random.choice(voyages)
                if v not in voyages_this_day:
                    voyages_this_day.append(v)
                if len(voyages_this_day) == flights_amount:
                    break

            used_aircrafts = set()  # самолёты, которые сегодня уже летят
            used_customers = set()  # люди, которые уже летят и сегодня больше никуда не полетят
            for v in voyages_this_day:
                print(f"\tОбработка полёта на тур {v}")

                # нельзя летать на одном и том же самолёте, если он подходит для нескольких рейсов
                aircraft = map_aircraft_by_type[v["aircraft_type_id"]]
                if aircraft["aircraft_id"] in used_aircrafts:
                    continue
                else:
                    used_aircrafts.add(aircraft["aircraft_id"])

                # собираем полёт
                flight_dict = {
                    "voyage_id": v["voyage_id"],
                    "aircraft_id": aircraft["aircraft_id"],
                    "raw_estimated_cost": random.random() / 2 * v["max_flight_range"],
                    "departure_datetime": iteration_datetime,
                }
                flight: Record = (
                    await connection.fetch(
                        f"""
                    INSERT INTO flight (voyage_id, aircraft_id, raw_estimated_cost, departure_datetime)
                    VALUES {format_dict_as_insert_tuple(flight_dict)}
                    RETURNING *
                """
                    )
                )[0]
                del flight_dict

                # ДАЛЕЕ - для каждого полёта нужно заполнить самолёт процентов на 90-95, притом симулировать
                # некоторый процент сданных билетов и отменённых броней

                for place in range(1, map_aircraft_type_by_id[v["aircraft_type_id"]]["places_number"]):

                    # тот клиент, который в итоге полетит
                    customer: Optional[Record] = None

                    # та бронь, которую он в итоге выкупил или не выкупил и сразу купил билет
                    redeemed_reservation: Optional[dict] = None

                    if random.randint(0, 100) < 95:  # с шансом 5% билет будет создан без брони
                        for i in range(4):  # каждому месту даём шанс на 4 брони

                            while True:
                                customer = random.choice(customers)
                                if customer["customer_id"] not in used_customers:
                                    used_customers.add(customer["customer_id"])
                                    break

                            is_cancelled: bool = random.randint(0, 100) > 98  # 2% на отмену

                            state: str = "not_redeemed"
                            if not is_cancelled:
                                state_chance = random.randint(0, 100)
                                if 0 <= state_chance < 98:  # с шансом в 98% бронь будет оплачена
                                    state = "redeemed"

                            reservations_count += 1
                            reservation = {
                                "reservation_id": reservations_count,
                                "customer_id": customer["customer_id"],
                                "flight_id": flight["flight_id"],
                                "is_cancelled": is_cancelled,
                                "state": state,
                            }

                            # в любом случае бронь вставим в базу
                            reservations_to_insert.append(reservation)

                            # если бронь не отменена и оплачена - метим её как итоговую и выходим из цикла
                            if not is_cancelled and state == "redeemed":
                                redeemed_reservation = reservation
                                break

                    customer = customer or random.choice(customers)

                    # 2% дополнительно что билет не будет создан даже когда бронь есть
                    if random.randint(0, 100) < 98:
                        is_returned = random.randint(0, 100) > 97  # 3% на возврат билета
                        bought_at = datetime.datetime(
                            year=iteration_datetime.year,
                            month=iteration_datetime.month,
                            day=iteration_datetime.day,
                            hour=random.randint(1, 23),
                            minute=random.randint(0, 59),
                            second=random.randint(0, 59),
                        ) - datetime.timedelta(
                            days=random.randint(1, 60)
                        )  # покупаем билет от 1 до 60 дней назад

                        ticket = {
                            "customer_id": customer["customer_id"],
                            "flight_id": flight["flight_id"],
                            "reservation_id": redeemed_reservation["reservation_id"] if redeemed_reservation else None,
                            "place": place,
                            "bought_at": bought_at,
                            "is_returned": is_returned,
                        }

                        tickets_to_insert.append(ticket)

        await connection.fetch(
            f"""
            INSERT INTO reservation (reservation_id, customer_id, flight_id, is_cancelled, state) 
            VALUES {','.join(format_dict_as_insert_tuple(r) for r in reservations_to_insert)}
        """
        )

        await connection.fetch(
            f"""
            INSERT INTO ticket (customer_id, flight_id, reservation_id, place, bought_at, is_returned) 
            VALUES {','.join(format_dict_as_insert_tuple(t) for t in tickets_to_insert)} 
        """
        )

    print(f"{days_of_simulation} дней завершены, сценарий выполнен.")


if __name__ == "__main__":
    asyncio.run(main())
