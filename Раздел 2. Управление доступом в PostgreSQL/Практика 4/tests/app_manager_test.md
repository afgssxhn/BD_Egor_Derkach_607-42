# Тесты прав app_manager (Этап 8)

Под ролью: `pm_bob` (через `SET ROLE pm_bob`). `session_user=postgres`, `current_user=pm_bob`.
Скрипт: `sql/08_test_app_manager.sql` | сырой вывод: `sql/08_test_app_manager_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | `SELECT … FROM app.users` (все 5 строк, поле is_active) | успех | **успех** |
| 2 | `SELECT comment_id, is_internal, content FROM app.comments` | успех, поле is_internal видно | **успех**, 6 строк, видны is_internal=true для #4 и #5 |
| 3 | `SELECT * FROM app.task_history` | успех (через app_history_read) | **успех**, 3 строки |
| 4 | `INSERT INTO app.projects (...) VALUES (...)` | успех | **успех**, project_id=4 |
| 5 | `UPDATE app.tasks SET status='in_progress' WHERE task_id=2` | успех | **успех** |
| 6 | `DELETE FROM app.tasks WHERE task_id=12` | успех | **успех**, удалена «Report on Q2 metrics» |
| 7 | `INSERT INTO app.task_history (...)` | успех | **успех**, history_id=4 |
| 8 | `SELECT * FROM app.access_logs` | отказ | **отказ**: `permission denied for table access_logs` |
| 9 (доп) | `UPDATE app.comments SET is_internal = NOT is_internal WHERE comment_id=1` | успех | **успех**, флаг переключился в TRUE |
| 10 (доп) | `INSERT INTO app.users (...)` | отказ (manager не управляет users) | **отказ**: `permission denied for table users` |
| 11 (доп) | `CREATE TABLE app.foo (x INT)` | отказ (DDL только admin) | **отказ**: `permission denied for schema app` |

## Наблюдения

- Менеджер видит **все** колонки `app.users`, включая `is_active`, что подтверждает наследование от `app_user` + дополнительный полный SELECT через `GRANT SELECT, INSERT, UPDATE` ... фактически на users у manager ничего прямого нет — он использует SELECT, унаследованный от app_user (`GRANT SELECT ON TABLE app.users TO app_user`). Это и есть демонстрация наследования.
- Поле `is_internal` корректно видно — комменты #4 и #5 имеют `is_internal=t`, для обычного пользователя они были бы такими же, но `dev_alice` не имел SELECT на comments кроме как через app_task_worker (там SELECT тоже есть на всю таблицу). На самом деле и `dev_alice` видит `is_internal` физически — фильтрация по флагу должна делаться приложением или RLS. **Это важная честная нота для отчёта**: колоночный GRANT `app_internal_comments` сам по себе не **отнимает** доступ у app_user, потому что у того уже есть полный SELECT через `GRANT SELECT ON TABLE app.comments TO app_task_worker`. Полная защита `is_internal` требует REVOKE SELECT с конкретных колонок, что в текущей модели не сделано.
- DDL (`CREATE TABLE`) даёт ошибку на уровне SCHEMA, а не TABLE — это правильно: `CREATE` на схеме не выдан, и менеджер не может класть туда новые таблицы.
- Колоночный UPDATE на `is_internal` работает потому, что у manager есть и `app_internal_comments` (колоночный) **и** прямой `GRANT UPDATE` на comments — второе перекрывает первое. У dev_alice ничего этого нет.
