-- Этап 4: 7 ролей-контейнеров (NOLOGIN)
-- идемпотентность: дропаем перед созданием
-- ВАЖНО: дропать в обратном порядке зависимостей (сначала наследники)

DROP ROLE IF EXISTS app_audit_read;
DROP ROLE IF EXISTS app_history_read;
DROP ROLE IF EXISTS app_internal_comments;
DROP ROLE IF EXISTS app_task_worker;
DROP ROLE IF EXISTS app_read_reference;
DROP ROLE IF EXISTS app_read_all;
DROP ROLE IF EXISTS app_connect;

-- базовый коннект: CONNECT на БД + USAGE на схему app
CREATE ROLE app_connect NOLOGIN;
GRANT CONNECT ON DATABASE corporate_tasks TO app_connect;
GRANT USAGE   ON SCHEMA app                TO app_connect;

-- чтение справочников (отдельный контейнер, чтобы можно было дать только их)
CREATE ROLE app_read_reference NOLOGIN;
GRANT SELECT ON TABLE app.departments TO app_read_reference;
GRANT SELECT ON TABLE app.positions   TO app_read_reference;

-- польз-таскворкер: читает таски/проекты, пишет коменты
CREATE ROLE app_task_worker NOLOGIN;
GRANT app_read_reference                 TO app_task_worker;     -- справочники нужны
GRANT SELECT ON TABLE app.tasks          TO app_task_worker;
GRANT SELECT ON TABLE app.projects       TO app_task_worker;
GRANT SELECT, INSERT ON TABLE app.comments TO app_task_worker;
GRANT USAGE ON SEQUENCE app.comments_comment_id_seq TO app_task_worker;

-- чтение всех таблиц (используется marketing_eve и app_manager)
-- "read_all" в смысле всех бизнес-таблиц; access_logs принципиально только для аудита (app_audit_read)
CREATE ROLE app_read_all NOLOGIN;
GRANT app_connect TO app_read_all;
GRANT  SELECT ON ALL TABLES IN SCHEMA app TO app_read_all;
REVOKE SELECT ON app.access_logs           FROM app_read_all;

-- внутренние коменты — колоночные GRANT'ы на is_internal
CREATE ROLE app_internal_comments NOLOGIN;
GRANT SELECT (is_internal) ON TABLE app.comments TO app_internal_comments;
GRANT UPDATE (is_internal) ON TABLE app.comments TO app_internal_comments;

-- история изменений задач — отдельный пакет
CREATE ROLE app_history_read NOLOGIN;
GRANT SELECT ON TABLE app.task_history TO app_history_read;

-- логи доступа — только для админов
CREATE ROLE app_audit_read NOLOGIN;
GRANT SELECT ON TABLE app.access_logs TO app_audit_read;

-- проверм атрибуты контейнеров
SELECT rolname, rolcanlogin, rolinherit
FROM pg_roles
WHERE rolname LIKE 'app\_%' ESCAPE '\'
  AND rolname NOT IN ('app_user','app_manager','app_admin')
ORDER BY rolname;

-- какие коннекты-контейнеры наследуются между собой (только меж app_*-ролями)
SELECT r.rolname AS role, m.rolname AS inherits_from
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname LIKE 'app\_%' ESCAPE '\'
  AND m.rolname LIKE 'app\_%' ESCAPE '\'
ORDER BY role, inherits_from;
