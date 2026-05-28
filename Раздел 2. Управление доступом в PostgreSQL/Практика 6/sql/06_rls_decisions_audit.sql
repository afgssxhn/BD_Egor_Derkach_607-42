-- Этап 5: какие таблицы получили RLS, какие нет
SELECT schemaname, tablename, rowsecurity AS rls_enabled
FROM pg_tables
WHERE schemaname='app'
ORDER BY tablename;
