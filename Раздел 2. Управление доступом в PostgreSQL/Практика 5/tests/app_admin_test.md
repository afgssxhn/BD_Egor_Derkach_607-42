# Тесты прав app_admin (Этап 9)

Под ролью: `admin_diana` (`SET ROLE admin_diana`).
Скрипт: `sql/11_test_app_admin.sql` | вывод: `sql/11_test_app_admin_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | `SELECT COUNT(*) FROM app.access_logs` | успех (app_full_access) | **успех**, 2 |
| 2 | `INSERT … RETURNING task_id; DELETE FROM app.tasks WHERE title='Admin Disposable Task'` | успех | **успех**, INSERT и DELETE прошли |
| 3 | `CREATE TABLE app.admin_test (id INT, name TEXT)` | успех (CREATE on schema) | **успех** |
| 4 | `DROP TABLE app.admin_test` | успех | **успех** |
| 5 | `SELECT … FROM information_schema.role_table_grants` (агрегат по 3 ролям) | успех (information_schema читается всеми) | **успех**, 0 строк — потому что прямых GRANT'ов у app_user/manager/admin теперь нет (всё через контейнеры) |
| 6 | `GRANT SELECT ON TABLE app.access_logs TO app_manager` | технически проходит, но с WARNING «no privileges were granted» | **частично**: команда выполнилась, но не выдала право — `admin_diana` не имеет GRANT OPTION |
| 7 | `REVOKE SELECT ON TABLE app.access_logs FROM app_manager` | WARNING «no privileges could be revoked» | **частично**: то же |

## Наблюдения

- **Тест 5** — отлично иллюстрирует переход к контейнерной модели: запрос `WHERE grantee IN ('app_user','app_manager','app_admin')` возвращает **0 строк**, потому что после Этапа 2 все прямые GRANT'ы у этих ролей сняты, а права теперь приходят через `pg_auth_members` от контейнеров. Чтобы увидеть «эффективные права», нужно либо рекурсивный запрос по членству, либо `has_table_privilege(...)`.
- **Тест 6–7** — admin_diana не является **владельцем** объектов и не получала GRANT с `WITH ADMIN OPTION` на контейнеры. PostgreSQL разрешает синтаксис команды, но фактически право не выдаётся: WARNING «no privileges were granted». Это правильный, осознанный выбор: у нас в системе **никто** не может перевыдавать права, кроме `postgres` (владельца таблиц). См. контрольный вопрос 6 в отчёте — про `WITH GRANT OPTION`.
