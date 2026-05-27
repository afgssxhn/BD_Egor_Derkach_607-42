# Тесты прав app_admin (Этап 9, блок A)

Под ролью: `admin_diana` (`SET ROLE admin_diana`). `session_user=postgres`, `current_user=admin_diana`.
Скрипт: `sql/09_test_app_admin.sql` | сырой вывод: `sql/09_test_app_admin_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| A1 | `SELECT COUNT(*) FROM app.access_logs` | успех | **успех**, 0 (на тот момент пусто) |
| A2 | `UPDATE app.users SET is_active=false WHERE username='eve'` | успех | **успех**, eve деактивирована |
| A3 | `CREATE TABLE app.test_admin (...)` | успех | **успех** |
| A4 | `ALTER TABLE app.test_admin ADD COLUMN ...` | успех | **успех** |
| A5 | `DROP TABLE app.test_admin` | успех | **успех** |
| A6 | `SELECT … FROM pg_roles WHERE rolname LIKE 'app_%' OR …` | успех | **успех**, 15 ролей |
| A7 | `SELECT … FROM information_schema.role_table_grants …` | успех | **успех**, 13 строк (8 app_admin + 4 app_manager + 1 app_user) |
| A8 (доп) | `INSERT INTO app.access_logs (...)` | успех | **успех**, log_id=1 |
| A9 (доп) | `ALTER SYSTEM SET work_mem = '8MB'` (SUPERUSER-only) | отказ | **отказ**: `permission denied to set parameter "work_mem"` |

## Наблюдения

- Админ имеет полный DML и DDL в схеме `app`. CREATE/ALTER/DROP TABLE проходят.
- `ALTER SYSTEM` не разрешён — это требует SUPERUSER, чего у `app_admin` принципиально нет. Подтверждение чек-листа из Лекции 4: «Не используйте суперпользователя для приложений».
- Через `pg_roles` админ видит ровно те 15 ролей, что мы создали (7 контейнеров + 3 user-роли + 5 конкретных пользователей).
- `information_schema.role_table_grants` показывает прямые GRANT'ы (без раскрытия наследования) — для отчёта это базовая матрица прав.
