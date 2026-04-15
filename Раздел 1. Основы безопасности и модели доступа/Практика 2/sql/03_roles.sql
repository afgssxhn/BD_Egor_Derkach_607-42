-- Практика 2, задание 2.3 — RBAC в PostgreSQL
-- запускать после 01_schema.sql и 02_seed.sql
-- всё в одной транзакции, чтоб при ошибке ничего не осталось висеть

\c task_management;
SET search_path TO app, public;

BEGIN;

-- базовые роли без LOGIN — это контейнеры для прав, под ними никто не логинится
CREATE ROLE app_guest;
CREATE ROLE app_employee;
CREATE ROLE app_manager;
CREATE ROLE app_admin;
CREATE ROLE app_superuser;


-- подключение к базе и доступ к схеме

-- гость
GRANT CONNECT ON DATABASE task_management TO app_guest;
GRANT USAGE   ON SCHEMA app                TO app_guest;

-- сотрудник, базовый минимум
GRANT CONNECT ON DATABASE task_management TO app_employee;
GRANT USAGE   ON SCHEMA app                TO app_employee;


-- права guest
-- гость видит только публичные проекты, фильтр включится через RLS позже
GRANT SELECT ON TABLE app.projects TO app_guest;


-- права employee

-- колоночный GRANT: только безопасные поля users, до password_hash и email сотрудник не дотянется
GRANT SELECT (user_id, username, full_name) ON TABLE app.users TO app_employee;

-- чтение общей инфы по проектам и задачам
GRANT SELECT ON TABLE app.projects TO app_employee;
GRANT SELECT ON TABLE app.tasks    TO app_employee;

-- создание и правка задач, "только свои" добавится через RLS
GRANT INSERT, UPDATE ON TABLE app.tasks TO app_employee;
GRANT USAGE ON SEQUENCE app.tasks_task_id_seq TO app_employee;

-- коментарии: читать и писать свои
GRANT SELECT, INSERT ON TABLE app.comments TO app_employee;
GRANT USAGE ON SEQUENCE app.comments_comment_id_seq TO app_employee;

-- чтение истории изменений (до чужих записей не пустит RLS)
GRANT SELECT ON TABLE app.task_history TO app_employee;


-- права manager, всё что было у employee + своё сверху

GRANT app_employee TO app_manager;   -- наследование, самая важная строка

-- полный доступ к проектам, "свои проекты" — через RLS
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE app.projects TO app_manager;
GRANT USAGE ON SEQUENCE app.projects_project_id_seq TO app_manager;

-- задачи
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE app.tasks TO app_manager;

-- коментарии: менеджер может ещё и удалять
GRANT DELETE ON TABLE app.comments TO app_manager;

-- история: и читать, и писать (нужно для аудита действий менеджера)
GRANT INSERT ON TABLE app.task_history TO app_manager;
GRANT USAGE  ON SEQUENCE app.task_history_history_id_seq TO app_manager;


-- права admin, наследует manager

GRANT app_manager TO app_admin;

-- управление пользователями
GRANT SELECT, INSERT, UPDATE ON TABLE app.users TO app_admin;
GRANT USAGE ON SEQUENCE app.users_user_id_seq TO app_admin;

-- всё подряд на таблицах и секвенциях схемы
GRANT ALL PRIVILEGES ON ALL TABLES     IN SCHEMA app TO app_admin;
GRANT ALL PRIVILEGES ON ALL SEQUENCES  IN SCHEMA app TO app_admin;

-- DDL в своей схеме
GRANT CREATE ON SCHEMA app TO app_admin;

-- логи доступа — зона админа
GRANT SELECT ON TABLE app.access_logs TO app_admin;


-- права superuser, наследует admin

GRANT app_admin TO app_superuser;

-- все права на саму бд (CONNECT/CREATE/TEMP)
GRANT ALL PRIVILEGES ON DATABASE task_management TO app_superuser;

-- ALL на схему и все таблицы — часть уже пришла через admin, но прописываем явно
GRANT ALL PRIVILEGES ON SCHEMA app TO app_superuser;
GRANT ALL PRIVILEGES ON ALL TABLES    IN SCHEMA app TO app_superuser;
GRANT ALL PRIVILEGES ON ALL SEQUENCES IN SCHEMA app TO app_superuser;

-- это не PG SUPERUSER (rolsuper=true), а прикладная роль.
-- настоящего суперюзера прикладухе давать нельзя


-- пользователи и назначение им ролей

CREATE USER alice   WITH PASSWORD 'AliceSecure123!';
CREATE USER bob     WITH PASSWORD 'BobSecure456!';
CREATE USER charlie WITH PASSWORD 'CharlieSecure789!';
CREATE USER diana   WITH PASSWORD 'DianaSecure012!';
CREATE USER eve     WITH PASSWORD 'EveSecure345!';

-- Alice ведёт проект Website Redesign
GRANT app_manager TO alice;

-- Bob и Charlie — рядовые сотрудники
GRANT app_employee TO bob;
GRANT app_employee TO charlie;

-- Diana — админ
GRANT app_admin TO diana;

-- Eve — суперпользователь для теста крайнего случая
GRANT app_superuser TO eve;


-- проверочные запросы

-- список ролей и юзеров
SELECT rolname, rolcanlogin, rolinherit
FROM pg_roles
WHERE rolname LIKE 'app_%'
   OR rolname IN ('alice', 'bob', 'charlie', 'diana', 'eve')
ORDER BY rolcanlogin, rolname;

-- кто в какую роль входит
SELECT
    r.rolname AS role_name,
    m.rolname AS member_name
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname LIKE 'app_%'
ORDER BY r.rolname, m.rolname;

-- сводка прав: что может каждая роль
SELECT
    grantee,
    table_name,
    string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'app'
  AND grantee LIKE 'app_%'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

COMMIT;

-- если что-то пошло не так — ROLLBACK;
-- полная зачистка для повторного прогона с нуля:
--   DROP OWNED BY app_superuser, app_admin, app_manager,
--                 app_employee, app_guest CASCADE;
--   DROP USER IF EXISTS alice, bob, charlie, diana, eve;
--   DROP ROLE IF EXISTS app_superuser, app_admin, app_manager,
--                       app_employee, app_guest;
