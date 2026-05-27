-- Этап 2.2: 9 контейнеров согласно методичке Практики 5
-- идемпотентность: DROP OWNED + DROP, потом CREATE
DO $$
DECLARE r RECORD;
BEGIN
    FOR r IN SELECT rolname FROM pg_roles
             WHERE rolname IN ('app_connect','app_read_reference','app_read_main',
                               'app_comments_full','app_task_write','app_project_write',
                               'app_history_full','app_access_log_write','app_full_access')
    LOOP
        EXECUTE format('DROP OWNED BY %I', r.rolname);
        EXECUTE format('DROP ROLE %I',     r.rolname);
    END LOOP;
END $$;

-- 1. базовый коннект
CREATE ROLE app_connect NOLOGIN;
GRANT CONNECT ON DATABASE corporate_tasks TO app_connect;
GRANT USAGE   ON SCHEMA app                TO app_connect;

-- 2. чтение справочников
CREATE ROLE app_read_reference NOLOGIN;
GRANT SELECT ON TABLE app.departments TO app_read_reference;
GRANT SELECT ON TABLE app.positions   TO app_read_reference;

-- 3. чтение основных таблиц
CREATE ROLE app_read_main NOLOGIN;
GRANT SELECT ON TABLE app.users    TO app_read_main;
GRANT SELECT ON TABLE app.projects TO app_read_main;
GRANT SELECT ON TABLE app.tasks    TO app_read_main;

-- 4. полные права на коменты
CREATE ROLE app_comments_full NOLOGIN;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE app.comments TO app_comments_full;
GRANT USAGE ON SEQUENCE app.comments_comment_id_seq TO app_comments_full;

-- 5. упр-е задачами (S/I/U, без DELETE)
CREATE ROLE app_task_write NOLOGIN;
GRANT SELECT, INSERT, UPDATE ON TABLE app.tasks    TO app_task_write;
GRANT USAGE ON SEQUENCE app.tasks_task_id_seq      TO app_task_write;
GRANT SELECT ON TABLE app.projects                 TO app_task_write;  -- для проверки project_id

-- 6. упр-е проектами (S/I/U, без DELETE — намеренно, проверим в тестах)
CREATE ROLE app_project_write NOLOGIN;
GRANT SELECT, INSERT, UPDATE ON TABLE app.projects TO app_project_write;
GRANT USAGE ON SEQUENCE app.projects_project_id_seq TO app_project_write;

-- 7. история (S+I)
CREATE ROLE app_history_full NOLOGIN;
GRANT SELECT, INSERT ON TABLE app.task_history TO app_history_full;
GRANT USAGE ON SEQUENCE app.task_history_history_id_seq TO app_history_full;

-- 8. логи доступа (только запись)
CREATE ROLE app_access_log_write NOLOGIN;
GRANT INSERT ON TABLE app.access_logs TO app_access_log_write;
GRANT USAGE ON SEQUENCE app.access_logs_log_id_seq TO app_access_log_write;

-- 9. полный доступ — для админа
CREATE ROLE app_full_access NOLOGIN;
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA app TO app_full_access;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_full_access;
GRANT CREATE ON SCHEMA app TO app_full_access;

-- комменты (как в методичке)
COMMENT ON ROLE app_connect          IS 'Базовое подключение к БД и схеме';
COMMENT ON ROLE app_read_reference   IS 'Чтение справочников (departments, positions)';
COMMENT ON ROLE app_read_main        IS 'Чтение основных таблиц (users, projects, tasks)';
COMMENT ON ROLE app_comments_full    IS 'Полный доступ к комментариям';
COMMENT ON ROLE app_task_write       IS 'Чтение + запись задач';
COMMENT ON ROLE app_project_write    IS 'Чтение + запись проектов';
COMMENT ON ROLE app_history_full     IS 'Чтение + запись истории изменений';
COMMENT ON ROLE app_access_log_write IS 'Запись в логи доступа';
COMMENT ON ROLE app_full_access      IS 'Полный доступ ко всем объектам (админ)';

\echo === Проверка: 9 контейнеров с описаниями ===
SELECT rolname, rolcanlogin,
       pg_catalog.shobj_description(oid, 'pg_authid') AS description
FROM pg_roles
WHERE rolname IN ('app_connect','app_read_reference','app_read_main',
                  'app_comments_full','app_task_write','app_project_write',
                  'app_history_full','app_access_log_write','app_full_access')
ORDER BY rolname;
