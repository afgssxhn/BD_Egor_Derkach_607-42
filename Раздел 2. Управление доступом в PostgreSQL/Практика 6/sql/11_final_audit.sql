-- Этап 10: финальный аудит RLS + матрица видимости
\set ON_ERROR_STOP off

\echo === 1. Таблицы app с включённым RLS ===
SELECT schemaname, tablename, rowsecurity FROM pg_tables WHERE schemaname='app' ORDER BY tablename;

\echo === 2. Все политики схемы app ===
SELECT tablename, policyname, cmd, roles
FROM pg_policies WHERE schemaname='app'
ORDER BY tablename, policyname;

\echo === 3. RLS-функции схемы app ===
SELECT routine_name, routine_type, data_type, security_type
FROM information_schema.routines
WHERE routine_schema='app'
  AND (routine_name LIKE 'get_%' OR routine_name LIKE 'is_%')
ORDER BY routine_name;

\echo === 4. Матрица видимости: роль × таблица ===
DO $$
DECLARE
    test_role TEXT;
    tbl       TEXT;
    cnt       BIGINT;
BEGIN
    FOR test_role IN VALUES ('dev_alice'), ('pm_bob'), ('admin_diana') LOOP
        EXECUTE format('SET ROLE %I', test_role);
        RAISE NOTICE '=== Роль: % ===', test_role;
        FOR tbl IN VALUES ('tasks'), ('comments'), ('projects'), ('users') LOOP
            EXECUTE format('SELECT COUNT(*) FROM app.%I', tbl) INTO cnt;
            RAISE NOTICE '  %: % строк', tbl, cnt;
        END LOOP;
        RESET ROLE;
    END LOOP;
END $$;

\echo === 5. Total строк (под postgres) ===
SELECT 'tasks' AS t, COUNT(*) FROM app.tasks
UNION ALL SELECT 'comments', COUNT(*) FROM app.comments
UNION ALL SELECT 'projects', COUNT(*) FROM app.projects
UNION ALL SELECT 'users',    COUNT(*) FROM app.users;
