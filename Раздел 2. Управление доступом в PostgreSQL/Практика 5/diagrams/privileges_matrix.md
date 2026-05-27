# Финальная матрица привилегий (Практика 5)

После Этапов 2–6 и бонуса (Этап 11). Под каждой ролью указан **источник** права (контейнер либо прямой GRANT).

## По таблицам

| Объект / Операция | app_user | app_manager | app_admin |
|---|---|---|---|
| app.departments — SELECT | ✓ (app_read_reference) | ✓ (наследует) | ✓ (app_full_access) |
| app.positions — SELECT   | ✓ (app_read_reference) | ✓ (наследует) | ✓ |
| app.users — SELECT       | колоночный: user_id, username, full_name (app_read_main после бонуса) | ✓ полный (прямой GRANT) | ✓ полный (app_full_access) |
| app.users — I/U/D        | — | — | ✓ (app_full_access) |
| app.projects — SELECT    | ✓ (app_read_main + app_task_write) | ✓ (+app_project_write) | ✓ |
| app.projects — INSERT    | — | ✓ (app_project_write) | ✓ |
| app.projects — UPDATE    | — | ✓ | ✓ |
| app.projects — DELETE    | — | **— (app_project_write без DELETE — методичный кейс)** | ✓ |
| app.tasks — SELECT       | ✓ | ✓ | ✓ |
| app.tasks — INSERT       | ✓ (app_task_write) | ✓ | ✓ |
| app.tasks — UPDATE       | ✓ | ✓ | ✓ |
| app.tasks — DELETE       | — | — | ✓ |
| app.comments — SELECT    | ✓ (app_comments_full) | ✓ | ✓ |
| app.comments — INSERT    | ✓ | ✓ | ✓ |
| app.comments — UPDATE    | ✓ | ✓ + колоночный UPDATE(is_internal) | ✓ |
| app.comments — DELETE    | ✓ | ✓ | ✓ |
| app.task_history — SELECT | ✓ (app_history_full) | ✓ | ✓ |
| app.task_history — INSERT | ✓ | ✓ | ✓ |
| app.access_logs — SELECT  | — | — | ✓ (app_full_access) |
| app.access_logs — INSERT  | ✓ (app_access_log_write) | ✓ | ✓ |
| DDL на схему app | — | — | ✓ (CREATE on schema) |

## По последовательностям (USAGE)

| Sequence | app_user | app_manager | app_admin |
|---|---|---|---|
| comments_comment_id_seq | ✓ (app_comments_full) | ✓ | ✓ |
| tasks_task_id_seq       | ✓ (app_task_write) | ✓ | ✓ |
| projects_project_id_seq | — | ✓ (app_project_write) | ✓ |
| task_history_history_id_seq | ✓ (app_history_full) | ✓ | ✓ |
| access_logs_log_id_seq | ✓ (app_access_log_write) | ✓ | ✓ |
| departments/positions/users_*_seq | — | — | ✓ (app_full_access) |

## Колоночные права

| Роль | Таблица | Колонка | Тип |
|---|---|---|---|
| app_read_main (→ унаследовано app_user, marketing_eve) | app.users | user_id, username, full_name | SELECT |
| app_manager | app.comments | is_internal | SELECT, UPDATE |

## DEFAULT PRIVILEGES

Для таблиц, создаваемых ролью `app_admin` в схеме `app`:
- `app_read_reference` ← SELECT
- `app_task_write` ← SELECT, INSERT, UPDATE, DELETE
- `app_full_access` ← ALL

Для sequences: USAGE → app_task_write, ALL → app_full_access.

## Обоснование

Принцип минимальных привилегий из Лекции 5 раздел 6: пользователь должен получать только те операции, которые ему необходимы. Поэтому:
- app_user не имеет DELETE на tasks (`app_task_write` создан без DELETE) и не имеет INSERT/UPDATE на projects (нет членства в `app_project_write`).
- app_manager расширяет до управления проектами, но без DELETE (методически — крупная операция, за ней должен идти админ).
- app_admin получает полный набор через `app_full_access` + CREATE on schema. SUPERUSER никому не выдаётся.
- Конфиденциальные колонки (`email`, `password_hash` в users) скрыты от обычного пользователя через колоночный SELECT — Лекция 5, раздел 4.3.
