-- Этап 9: включение логирования подключений
ALTER SYSTEM SET log_connections = on;
ALTER SYSTEM SET log_disconnections = on;
ALTER SYSTEM SET log_line_prefix = '%t [%p]: [%l-1] user=%u,db=%d,app=%a,client=%h ';
SELECT pg_reload_conf();

SHOW log_connections;
SHOW log_disconnections;
SHOW log_line_prefix;
SHOW log_destination;
SHOW logging_collector;
