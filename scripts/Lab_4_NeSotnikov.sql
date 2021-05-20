--Выпуск билета после оплаты брони
--Информмационные системы аэропорта
--Электронное/физическое воплощение билета после оплаты брони

--Автоотмена полёта при нулевом выкупе
--Информация о полёте и билетах
--Уведомление клиентам об отмене полёта

--Ежеквартальная планировка полётов
--Данные о рейсах и полётах
--Расписание полётов на квартал


-- Темплейтик функции

CREATE OR REPLACE FUNCTION process_tasks_journals(OUT void) RETURNS void
    LANGUAGE plpgsql AS
$$
DECLARE
    task tasks;
BEGIN
    IF TG_OP = 'INSERT' THEN
        task = NEW;
        IF NOT EXISTS(SELECT 1 FROM any_table aee WHERE aee.entity_id = task.id) THEN
            IF (SELECT id FROM tasks WHERE task_id = NEW.id) IS NULL THEN
                INSERT INTO tasks (id)
                values ();
            END IF;
        END IF;
        RETURN task;
    ELSIF TG_OP = 'UPDATE' THEN
        task = NEW;
        NEW.updated_at = current_timestamp;
        IF OLD.total_work_time = NEW.total_work_time THEN
            IF OLD.total_cost = NEW.total_cost THEN
                INSERT INTO tasks (id)
                values (task.id);
            END IF;
        END IF;
        RETURN task;
    ELSIF TG_OP = 'DELETE' THEN
        task = OLD;
        INSERT INTO tasks (id)
        values (task.id);
        DELETE
        FROM any_table as aee
        WHERE aee.entity_id = task.id;
        RETURN task;
    END IF;
END;
$$
