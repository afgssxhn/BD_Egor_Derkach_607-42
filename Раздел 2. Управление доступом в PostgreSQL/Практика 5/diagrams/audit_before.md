# Snapshot системы привилегий до Практики 5

Базовое состояние, унаследованное от Практики 4 (sql/01_audit_initial.sql, output).

## Роли (15 шт)

**7 контейнеров (NOLOGIN)**: app_audit_read, app_connect, app_history_read, app_internal_comments, app_read_all, app_read_reference, app_task_worker

**3 пользовательские (LOGIN, INHERIT)**:
- app_user — CONN 20
- app_manager — CONN 50
- app_admin — CREATEDB, CONN 10

**5 конкретных пользователей** (LOGIN): dev_alice, dev_charlie, pm_bob, admin_diana, marketing_eve.

## Шаблон отчёта аудита (исходное состояние)

| Роль        | Таблицы (чтение)                                                                  | Таблицы (запись)                                                          | Последовательности                          | Схемы |
|-------------|-----------------------------------------------------------------------------------|---------------------------------------------------------------------------|---------------------------------------------|-------|
| app_user    | app.users (прямой SELECT) + унаследовано через app_task_worker (tasks, projects, comments) + app_read_reference (departments, positions) | INSERT в comments (через app_task_worker)                                | comments_comment_id_seq (через app_task_worker) | USAGE app (через app_connect) |
| app_manager | + всё app_user + app_history_read (task_history) + app_internal_comments (is_internal колоночный) | + INSERT/UPDATE projects, INSERT/UPDATE/DELETE tasks и comments, INSERT task_history | + projects, tasks, task_history             | USAGE app |
| app_admin   | + всё app_manager + app_audit_read (access_logs) + ALL TABLES                     | + ALL PRIVILEGES на 8 таблиц, INSERT/UPDATE/DELETE users, INSERT access_logs | + ALL SEQUENCES                             | USAGE + CREATE app |

## Количественные показатели

- Всего прямых GRANT-записей на таблицы в `app`: **69**
- DEFAULT PRIVILEGES: **0** (не настроены)
- Колоночные GRANT'ы: 2 (`is_internal` SELECT/UPDATE у `app_internal_comments`)
- nspacl app: `{postgres=UC/postgres, app_connect=U/postgres, app_admin=C/postgres}` — у app_connect есть USAGE, у app_admin — CREATE на схему.
- datacl: app_connect имеет CONNECT.

## Что планируется поменять в Практике 5

1. **REVOKE ALL** прямых GRANT'ов у app_user/app_manager/app_admin — обнулить базовое состояние.
2. **DROP** старые 7 контейнеров (Практика 4), **CREATE** новые 9 контейнеров согласно методичке Практики 5 (app_connect, app_read_reference, app_read_main, app_comments_full, app_task_write, app_project_write, app_history_full, app_access_log_write, app_full_access).
3. Переподключить marketing_eve к новой иерархии (она была на удалённом app_read_all).
4. Настроить **DEFAULT PRIVILEGES** для будущих таблиц, создаваемых app_admin.
5. БОНУС: колоночные SELECT'ы на app.users — скрыть email и password_hash от app_user.
