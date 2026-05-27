# Тесты прав app_manager (Этап 8)

Под ролью: `pm_bob` (`SET ROLE pm_bob`).
Скрипт: `sql/10_test_app_manager.sql` | вывод: `sql/10_test_app_manager_output.txt`.

| # | Операция | Ожидаемо | Фактически |
|---|---|---|---|
| 1 | `SELECT COUNT(*) FROM app.departments` | успех (наследовано через app_user) | **успех**, 3 |
| 2 | `INSERT INTO app.projects (...)` | успех (app_project_write) | **успех**, project_id=5 |
| 3 | `UPDATE app.projects SET description=... WHERE name=...` | успех | **успех** |
| 4 | `DELETE FROM app.projects WHERE name='Manager Test Project P5'` | **отказ** (app_project_write не содержит DELETE) | **отказ**: `permission denied for table projects` |
| 5 | `SELECT comment_id, is_internal FROM app.comments` | успех (колоночный + наследованный SELECT через app_user→app_comments_full) | **успех**, 5 строк, флаги видны |
| 6 | `SELECT COUNT(*) FROM app.task_history` | успех (унаследовано через app_history_full) | **успех**, 4 |
| 7 | `SELECT * FROM app.access_logs` | отказ (у manager нет SELECT — у app_user/manager только INSERT через app_access_log_write) | **отказ**: `permission denied for table access_logs` |
| 8 (доп) | `UPDATE app.comments SET is_internal = NOT is_internal WHERE comment_id=2` | успех (колоночный UPDATE + UPDATE на остальную таблицу через app_comments_full) | **успех** |
| 9 (доп) | `CREATE TABLE app.foo_mgr (x INT)` | отказ (нет CREATE on schema) | **отказ**: `permission denied for schema app` |

## Ключевые наблюдения

- **Тест 4 — DELETE проектов**: методичка явно намекает «Тест 4: ... или нет? Проверьте!». В нашей реализации `app_project_write` содержит только `SELECT, INSERT, UPDATE` — без `DELETE`. Это правильный архитектурный выбор: «безвозвратное удаление проекта» — операция, которую обычно делают только администраторы, а не менеджеры. Поэтому отказ ожидаем.
- **Тест 5 — is_internal**: видно потому, что `app_user` уже даёт `SELECT` на всю таблицу `comments` через контейнер `app_comments_full`. Колоночный GRANT для манагера дублирует это право, но не отнимает его у `app_user` — это тот же «отнимающий-не-отнимающий» нюанс, что был на Практике 4. В Этапе 11 (бонус) будет противоположный сценарий — где колоночные права работают именно как ограничение, потому что начинаются с REVOKE.
