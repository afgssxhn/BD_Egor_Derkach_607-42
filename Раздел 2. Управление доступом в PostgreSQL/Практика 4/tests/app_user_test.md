# Тесты прав app_user (Этап 7)

Под ролью: `dev_alice` (через `SET ROLE dev_alice` от `postgres`).
Скрипт: `sql/07_test_app_user.sql` | сырой вывод: `sql/07_test_app_user_output.txt`.

`current_user` = dev_alice, `session_user` = postgres.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | `SELECT COUNT(*) FROM app.departments` | успех | **успех**, 3 |
| 2 | `SELECT COUNT(*) FROM app.positions` | успех | **успех**, 5 |
| 3 | `SELECT COUNT(*) FROM app.projects` | успех | **успех**, 3 |
| 4 | `SELECT COUNT(*) FROM app.tasks` | успех | **успех**, 12 |
| 5 | `INSERT INTO app.comments (...) VALUES (1, 1, '...')` | успех (контейнер app_task_worker даёт INSERT) | **успех**, 1 строка |
| 6 | `UPDATE app.tasks SET status='done' WHERE task_id=1` | отказ | **отказ**: `permission denied for table tasks` |
| 7 | `DELETE FROM app.tasks WHERE task_id=1` | отказ | **отказ**: `permission denied for table tasks` |
| 8 | `SELECT user_id, username, email, full_name FROM app.users` | успех | **успех**, 5 строк |
| 9 | `SELECT * FROM app.access_logs` | отказ | **отказ**: `permission denied for table access_logs` |
| 10 (доп) | `UPDATE app.users SET is_active=false WHERE user_id=5` | отказ | **отказ**: `permission denied for table users` |
| 11 (доп) | `SELECT * FROM app.task_history` | отказ (history для manager+) | **отказ**: `permission denied for table task_history` |

## Наблюдения

- Все 11 кейсов совпали с ожиданием. Принцип минимальных привилегий выдержан: dev_alice имеет ровно набор «чтение справочников + чтение проектов/задач/пользователей + INSERT комментов», ничего лишнего.
- Внутри одной сессии видно разделение `current_user` (активная роль) и `session_user` (имя, с которым было выполнено подключение). Это иллюстрация различия из контрольного вопроса 10.
- `RESET ROLE` корректно возвращает `current_user=postgres`.
