-- Этап 6: DEFAULT PRIVILEGES для будущих объектов в схеме app
-- идемпотентно: сначала REVOKE old default, потом GRANT
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    REVOKE ALL ON TABLES    FROM app_read_reference, app_task_write, app_full_access;
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    REVOKE ALL ON SEQUENCES FROM app_task_write, app_full_access;

-- таблицы: SELECT → app_read_reference, S/I/U/D → app_task_write, ALL → app_full_access
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    GRANT SELECT                         ON TABLES TO app_read_reference;
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    GRANT SELECT, INSERT, UPDATE, DELETE ON TABLES TO app_task_write;
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    GRANT ALL                            ON TABLES TO app_full_access;

-- последовательности: USAGE → app_task_write, ALL → app_full_access
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    GRANT USAGE ON SEQUENCES TO app_task_write;
ALTER DEFAULT PRIVILEGES FOR ROLE app_admin IN SCHEMA app
    GRANT ALL   ON SEQUENCES TO app_full_access;

\echo === Просмотр настроек DEFAULT PRIVILEGES ===
SELECT defaclrole::regrole AS creator_role,
       defaclnamespace::regnamespace AS schema,
       defaclobjtype AS obj_type,
       defaclacl AS acl
FROM pg_default_acl
WHERE defaclnamespace::regnamespace::text = 'app';
