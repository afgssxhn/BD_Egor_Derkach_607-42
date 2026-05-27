# Тесты прав app_user (Этап 7)

Под ролью: `dev_alice` (`SET ROLE dev_alice` от postgres).
Скрипт: `sql/09_test_app_user.sql` | вывод: `sql/09_test_app_user_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | `SELECT COUNT(*) FROM app.departments` | успех (app_read_reference) | **успех**, 3 |
| 2 | `SELECT COUNT(*) FROM app.positions` | успех | **успех**, 5 |
| 3 | `SELECT … FROM app.users` | успех (app_read_main) | **успех**, 5 строк |
| 4 | `SELECT COUNT(*) FROM app.projects` | успех | **успех**, 4 |
| 5 | `SELECT COUNT(*) FROM app.tasks` | успех | **успех**, 11 |
| 6 | `INSERT INTO app.comments (...)` | успех (app_comments_full) | **успех**, comment_id=7 |
| 7 | `UPDATE app.tasks SET status='in_progress' WHERE task_id=2` | успех (app_task_write) | **успех** |
| 8 | `DELETE FROM app.tasks WHERE task_id=11` | отказ (нет DELETE в app_task_write) | **отказ**: `permission denied for table tasks` |
| 9 | `INSERT INTO app.projects (...)` | отказ (нет app_project_write) | **отказ**: `permission denied for table projects` |
| 10 | `SELECT COUNT(*) FROM app.task_history` | успех (app_history_full) | **успех**, 4 |
| 11 | `SELECT * FROM app.access_logs` | отказ (только INSERT) | **отказ**: `permission denied for table access_logs` |
| 12 | `INSERT INTO app.access_logs (...)` без RETURNING | успех (app_access_log_write) | **успех**, 1 строка |
| 13 | `INSERT INTO app.access_logs (...) RETURNING log_id` | **отказ** (RETURNING требует SELECT) | **отказ**: `permission denied for table access_logs` |

## Учебный нюанс (тест 13)

`INSERT ... RETURNING colN` в PostgreSQL требует **двух** привилегий: `INSERT` для самой вставки и **`SELECT` на возвращаемую колонку** для формирования результата. У `app_user` через контейнер `app_access_log_write` есть только `INSERT` — поэтому одна и та же команда вставки работает в варианте без `RETURNING` и падает с ним. Если приложению нужен `RETURNING` (например, чтобы узнать сгенерированный `log_id`), нужно либо добавить SELECT на эту колонку, либо вернуть значение через `currval('...log_id_seq')` (что тоже требует SELECT/USAGE на sequence).
