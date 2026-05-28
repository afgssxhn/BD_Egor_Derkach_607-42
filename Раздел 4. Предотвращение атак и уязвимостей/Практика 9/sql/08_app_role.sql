-- Этап 4.1: создаём роль приложения с минимальными правами
DROP ROLE IF EXISTS web_app_demo;
CREATE ROLE web_app_demo LOGIN PASSWORD 'demo123';

REVOKE ALL ON SCHEMA injection_lab FROM PUBLIC;
GRANT USAGE ON SCHEMA injection_lab TO web_app_demo;

REVOKE ALL ON ALL TABLES IN SCHEMA injection_lab FROM web_app_demo;

GRANT SELECT ON injection_lab.users TO web_app_demo;
GRANT SELECT ON injection_lab.tasks TO web_app_demo;

-- моделируем смену статуса задачи: даём колоночный UPDATE
GRANT UPDATE(status) ON injection_lab.tasks TO web_app_demo;

\echo === Атрибуты роли ===
SELECT rolname, rolsuper, rolcreatedb, rolcanlogin
FROM pg_roles WHERE rolname='web_app_demo';
