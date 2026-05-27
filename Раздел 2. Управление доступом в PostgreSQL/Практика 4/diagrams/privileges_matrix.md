# Матрица привилегий (Практика 4, Задание 2.1)

Сводная таблица: **объект/операция → app_user / app_manager / app_admin**.

| Объект / Операция                      | app_user                       | app_manager                     | app_admin                            |
|----------------------------------------|--------------------------------|---------------------------------|--------------------------------------|
| `app.departments` — SELECT             | ✓                              | ✓ (наследует)                   | ✓ (наследует)                        |
| `app.departments` — INSERT/UPDATE/DEL  | —                              | —                               | ✓                                    |
| `app.positions` — SELECT               | ✓                              | ✓ (наследует)                   | ✓ (наследует)                        |
| `app.positions` — INSERT/UPDATE/DEL    | —                              | —                               | ✓                                    |
| `app.users` — SELECT                   | ✓ (без password_hash в коде приложения; на уровне SQL — все колонки)¹ | ✓ все поля | ✓ все поля + системные |
| `app.users` — INSERT/UPDATE/DELETE     | —                              | —                               | ✓                                    |
| `app.projects` — SELECT                | ✓                              | ✓                               | ✓                                    |
| `app.projects` — INSERT/UPDATE         | —                              | ✓                               | ✓                                    |
| `app.projects` — DELETE                | —                              | —²                              | ✓                                    |
| `app.tasks` — SELECT                   | ✓                              | ✓                               | ✓                                    |
| `app.tasks` — INSERT                   | —                              | ✓                               | ✓                                    |
| `app.tasks` — UPDATE                   | —³                             | ✓                               | ✓                                    |
| `app.tasks` — DELETE                   | —                              | ✓                               | ✓                                    |
| `app.comments` — SELECT (без is_internal) | ✓                           | ✓                               | ✓                                    |
| `app.comments` — SELECT (is_internal)  | —                              | ✓ (через app_internal_comments) | ✓                                    |
| `app.comments` — INSERT                | ✓                              | ✓                               | ✓                                    |
| `app.comments` — UPDATE (is_internal)  | —                              | ✓ (колоночный GRANT)            | ✓                                    |
| `app.comments` — UPDATE/DELETE общий   | —                              | ✓                               | ✓                                    |
| `app.task_history` — SELECT            | —                              | ✓ (app_history_read)            | ✓                                    |
| `app.task_history` — INSERT            | —                              | ✓                               | ✓                                    |
| `app.access_logs` — SELECT             | —                              | —                               | ✓ (app_audit_read)                   |
| `app.access_logs` — INSERT             | —                              | —                               | ✓                                    |
| DDL в схеме `app` (CREATE/ALTER/DROP)  | —                              | —                               | ✓ (CREATE on SCHEMA)                 |
| CONNECT на БД                          | ✓                              | ✓                               | ✓                                    |
| Атрибут CREATEDB на уровне кластера    | —                              | —                               | ✓                                    |

Сноски:
1. На уровне SQL ограничения по строкам (только свои данные) реализуются через Row-Level Security в Лекции 6. В рамках этой лабы — SELECT на всю таблицу, фильтрация — задача приложения.
2. Удаление проектов в шаблоне методички разрешено только админу — это соответствует принципу: проект — крупный объект, его удаление = нетипичная операция.
3. У `app_user` нет UPDATE на tasks. Изменение статуса своих задач — на уровне приложения через сервис-аккаунт `app_manager`, либо через RLS-политику в Лекции 6.

## Marketing_eve и роль app_read_all

`marketing_eve` получает только `app_read_all` — без `app_user`, без INSERT-прав. Это read-only пользователь: видит всё (включая `is_internal`?... — нет, `app_read_all` даёт `SELECT ON ALL TABLES`, и колонка `is_internal` входит в общую таблицу `comments` — `SELECT * FROM app.comments` для неё **сработает**). Это сознательный компромисс: marketing нужно видеть все материалы кампаний целиком; если требуется скрыть внутренние комменты — это уровень view/RLS, не GRANT.
