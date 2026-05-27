# Тест DEFAULT PRIVILEGES (Этап 6)

Скрипты: `sql/07_default_privileges.sql` (настройка), `sql/08_test_default_privileges.sql` (проверка).

## Что настроили

Для таблиц, создаваемых ролью `app_admin` в схеме `app`:
- `app_read_reference` получает `SELECT`
- `app_task_write` получает `SELECT, INSERT, UPDATE, DELETE`
- `app_full_access` получает `ALL`

Для последовательностей: `USAGE` → `app_task_write`, `ALL` → `app_full_access`.

Содержимое `pg_default_acl` (после ALTER):
```
creator_role | schema | obj_type | acl
app_admin    | app    | r (table)| {app_read_reference=r/app_admin, app_task_write=arwd/app_admin, app_full_access=arwdDxt/app_admin}
app_admin    | app    | S (seq)  | {app_task_write=U/app_admin, app_full_access=rwU/app_admin}
```

## Тест

`SET ROLE app_admin; CREATE TABLE app.test_default_privileges (id SERIAL PRIMARY KEY, name TEXT, description TEXT, created_at TIMESTAMP DEFAULT NOW());`

Сразу после CREATE: запрос к `information_schema.role_table_grants` показывает:

| grantee | privileges на test_default_privileges |
|---|---|
| app_admin | DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE |
| app_full_access | DELETE, INSERT, REFERENCES, SELECT, TRIGGER, TRUNCATE, UPDATE |
| app_read_reference | SELECT |
| app_task_write | DELETE, INSERT, SELECT, UPDATE |

Sequence `test_default_privileges_id_seq` — USAGE для app_admin, app_full_access, app_task_write.

| Шаг | Ожидаемо | Фактически |
|---|---|---|
| dev_alice SELECT новой таблицы | успех (через app_task_write/app_read_reference) | **успех**, 0 строк |
| dev_alice INSERT в новую таблицу | успех (INSERT через app_task_write) | **успех**, 1 строка |
| dev_alice SELECT после INSERT | успех | **успех**, видит id=1 'test row' |

## Смысл

DEFAULT PRIVILEGES избавляет от ручного GRANT'а после каждого CREATE TABLE. Без них новая таблица в схеме `app` была бы недоступна даже dev_alice — пришлось бы каждый раз делать `GRANT SELECT/INSERT/UPDATE TO app_task_write` руками. Лекция 5, раздел 8: «При создании новых объектов права на них не предоставляются автоматически. ALTER DEFAULT PRIVILEGES позволяет настроить автоматическое предоставление прав на будущие объекты.»

Ограничение: действует **только для создателя** (FOR ROLE app_admin) и **только для будущих** объектов. Существующие таблицы не задеты.
