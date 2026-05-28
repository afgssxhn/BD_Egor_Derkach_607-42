-- Этап 4.2: матрица прав web_app_demo
\echo === Прямые GRANTы на таблицы для web_app_demo ===
SELECT grantee, table_schema, table_name, privilege_type
FROM information_schema.role_table_grants
WHERE grantee = 'web_app_demo'
ORDER BY table_name, privilege_type;

\echo === Колоночные GRANTы (UPDATE status) ===
SELECT grantee, table_name, column_name, privilege_type
FROM information_schema.column_privileges
WHERE grantee = 'web_app_demo'
ORDER BY table_name, column_name, privilege_type;

\echo === Сравнение с postgres (суперпольз): что он может на injection_lab.tasks ===
SELECT 'postgres' AS who,
       has_table_privilege('postgres','injection_lab.tasks','SELECT') AS sel,
       has_table_privilege('postgres','injection_lab.tasks','INSERT') AS ins,
       has_table_privilege('postgres','injection_lab.tasks','UPDATE') AS upd,
       has_table_privilege('postgres','injection_lab.tasks','DELETE') AS del,
       has_table_privilege('postgres','injection_lab.tasks','TRUNCATE') AS trunc
UNION ALL
SELECT 'web_app_demo',
       has_table_privilege('web_app_demo','injection_lab.tasks','SELECT'),
       has_table_privilege('web_app_demo','injection_lab.tasks','INSERT'),
       has_table_privilege('web_app_demo','injection_lab.tasks','UPDATE'),
       has_table_privilege('web_app_demo','injection_lab.tasks','DELETE'),
       has_table_privilege('web_app_demo','injection_lab.tasks','TRUNCATE');
