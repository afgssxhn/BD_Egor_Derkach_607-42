-- Этап 5: пользовательские роли app_user / app_manager / app_admin
-- идемпотентно — снести в обратном порядке наследования
DROP ROLE IF EXISTS app_admin;
DROP ROLE IF EXISTS app_manager;
DROP ROLE IF EXISTS app_user;

-- РОЛЬ 1: app_user (обычный сотрудник)
CREATE ROLE app_user WITH
    LOGIN
    PASSWORD 'UserPass123!'
    INHERIT
    CONNECTION LIMIT 20;

GRANT app_connect        TO app_user;
GRANT app_read_reference TO app_user;
GRANT app_task_worker    TO app_user;

-- + просмотр польз приложения (на уровне SQL — все колонки; фильтрация — приложение/RLS)
GRANT SELECT ON TABLE app.users TO app_user;

-- РОЛЬ 2: app_manager (менеджер проекта)
CREATE ROLE app_manager WITH
    LOGIN
    PASSWORD 'ManagerPass456!'
    INHERIT
    CONNECTION LIMIT 50;

-- наследует все права app_user
GRANT app_user TO app_manager;

-- + видимость внутренних комментов и истории
GRANT app_internal_comments TO app_manager;
GRANT app_history_read      TO app_manager;

-- расширенные права на основные таблицы
GRANT SELECT, INSERT, UPDATE         ON TABLE app.projects     TO app_manager;
GRANT USAGE                          ON SEQUENCE app.projects_project_id_seq TO app_manager;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE app.tasks        TO app_manager;
GRANT USAGE                          ON SEQUENCE app.tasks_task_id_seq      TO app_manager;

GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE app.comments     TO app_manager;
-- USAGE на sequence comments уже наследуется через app_task_worker

GRANT INSERT                         ON TABLE app.task_history TO app_manager;
GRANT USAGE                          ON SEQUENCE app.task_history_history_id_seq TO app_manager;

-- РОЛЬ 3: app_admin (администратор)
CREATE ROLE app_admin WITH
    LOGIN
    PASSWORD 'AdminPass789!'
    CREATEDB
    INHERIT
    CONNECTION LIMIT 10;

GRANT app_manager    TO app_admin;
GRANT app_audit_read TO app_admin;

-- полные права на всю схему
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA app TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_admin;

-- DDL в схеме app
GRANT CREATE ON SCHEMA app TO app_admin;

-- управление users (DML) и запись логов
GRANT INSERT, UPDATE, DELETE ON TABLE app.users       TO app_admin;
GRANT INSERT                 ON TABLE app.access_logs TO app_admin;
GRANT USAGE                  ON SEQUENCE app.users_user_id_seq      TO app_admin;
GRANT USAGE                  ON SEQUENCE app.access_logs_log_id_seq TO app_admin;

-- =========================
-- проверки
-- =========================

-- атрибуты пользовательских ролей
SELECT rolname, rolcanlogin, rolinherit, rolcreatedb, rolconnlimit
FROM pg_roles
WHERE rolname IN ('app_user','app_manager','app_admin')
ORDER BY rolname;

-- что наследует каждая
SELECT r.rolname AS role, m.rolname AS inherits_from
FROM pg_auth_members am
JOIN pg_roles r ON r.oid = am.member
JOIN pg_roles m ON m.oid = am.roleid
WHERE r.rolname IN ('app_user','app_manager','app_admin')
ORDER BY role, inherits_from;

-- сводная матрица прав напрямую (без наследования) — что лежит в information_schema
SELECT grantee, table_name, STRING_AGG(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE grantee IN ('app_user','app_manager','app_admin')
  AND table_schema = 'app'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;
