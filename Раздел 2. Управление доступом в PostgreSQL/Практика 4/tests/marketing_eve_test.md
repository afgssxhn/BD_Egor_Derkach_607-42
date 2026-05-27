# Тесты прав marketing_eve / app_read_all (Этап 9, блок B)

Под ролью: `marketing_eve` (`SET ROLE marketing_eve`). Только `app_read_all` (без `app_user`).
Скрипт: общий с admin — `sql/09_test_app_admin.sql`, тесты B1–B7.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| B1 | `SELECT COUNT(*) FROM app.projects` | успех | **успех**, 4 |
| B2 | `SELECT COUNT(*) FROM app.tasks` | успех | **успех**, 11 (после DELETE на Этапе 8) |
| B3 | `SELECT … FROM app.comments` (вкл. is_internal) | успех (read_all — это read all) | **успех**, 6 строк, флаги видны |
| B4 | `SELECT * FROM app.access_logs` | отказ (после REVOKE) | **отказ**: `permission denied for table access_logs` |
| B5 | `INSERT INTO app.comments (...)` | отказ (read-only) | **отказ**: `permission denied for table comments` |
| B6 | `UPDATE app.tasks SET status='done'` | отказ | **отказ**: `permission denied for table tasks` |
| B7 | `DELETE FROM app.projects WHERE project_id=1` | отказ | **отказ**: `permission denied for table projects` |

## Исправление, найденное в ходе теста B4

Первый запуск тестов показал: `marketing_eve` смогла прочитать `app.access_logs` — это нарушает принцип «логи аудита только для админа». Причина — широкий `GRANT SELECT ON ALL TABLES IN SCHEMA app TO app_read_all` захватывал и access_logs. Решение: добавлено
`REVOKE SELECT ON app.access_logs FROM app_read_all` в `sql/03_container_roles.sql` сразу после общего GRANT'а. После REVOKE повторный прогон B4 даёт ожидаемый `permission denied`. Это пример того, зачем нужны тесты на негативные сценарии: широкие GRANT'ы по умолчанию ловят больше, чем планируется.

## Наблюдения

- `app_read_all` корректно изолирует marketing_eve в read-only режиме: SELECT по бизнес-таблицам — да, любые DML/DDL — нет.
- Поле `is_internal` в comments видно (это компромисс read_all). При необходимости спрятать — REVOKE на колонку или view.
