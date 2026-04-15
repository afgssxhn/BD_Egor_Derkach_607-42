-- Библиотека: роли и пользователи

\c library;
SET search_path TO lib, public;

BEGIN;

-- роли-контейнеры без LOGIN
CREATE ROLE lib_reader;
CREATE ROLE lib_librarian;
CREATE ROLE lib_senior;
CREATE ROLE lib_admin;


-- CONNECT к базе + USAGE на схему всем ролям
GRANT CONNECT ON DATABASE library TO lib_reader, lib_librarian, lib_senior, lib_admin;
GRANT USAGE   ON SCHEMA lib       TO lib_reader, lib_librarian, lib_senior, lib_admin;


-- права READER
-- каталог книг + своя карточка + свои выдачи/брони/штрафы

-- безопасные колонки своей карточки (email/password_hash скрыты колоночно + RLS)
GRANT SELECT (reader_id, ticket_number, username, full_name, registered_at, is_blocked)
    ON TABLE lib.readers TO lib_reader;

-- весь каталог можно смотреть
GRANT SELECT ON TABLE lib.books TO lib_reader;

-- выдачи — только SELECT (RLS ограничит до своих)
GRANT SELECT ON TABLE lib.loans TO lib_reader;

-- брони: читатель сам создаёт и отменяет свои
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE lib.reservations TO lib_reader;
GRANT USAGE ON SEQUENCE lib.reservations_reservation_id_seq TO lib_reader;

-- штрафы — только SELECT (RLS урежет до своих)
GRANT SELECT ON TABLE lib.fines TO lib_reader;


-- права LIBRARIAN
-- всё что у читателя + работа с выдачами, видит всех читателей

GRANT lib_reader TO lib_librarian;   -- наследование

-- для связи нужны email/телефон, но password_hash — ни в коем случае.
-- в PG нет "GRANT ALL EXCEPT", поэтому: откатываем и даём колоночный SELECT
REVOKE SELECT ON TABLE lib.readers FROM lib_librarian;
GRANT SELECT (reader_id, ticket_number, username, full_name, email, phone,
              is_blocked, registered_at) ON TABLE lib.readers TO lib_librarian;

-- выдачи: выдача/возврат
GRANT INSERT, UPDATE ON TABLE lib.loans TO lib_librarian;
GRANT USAGE ON SEQUENCE lib.loans_loan_id_seq TO lib_librarian;

-- брони: отменять/исполнять
GRANT SELECT, UPDATE, DELETE ON TABLE lib.reservations TO lib_librarian;

-- штрафы — только SELECT (выставляет старший), уже пришло через lib_reader

-- инфа о сотрудниках
GRANT SELECT ON TABLE lib.staff TO lib_librarian;


-- права SENIOR
-- + управление каталогом + штрафы

GRANT lib_librarian TO lib_senior;

-- каталог книг: добавлять, править, списывать
GRANT INSERT, UPDATE, DELETE ON TABLE lib.books TO lib_senior;
GRANT USAGE ON SEQUENCE lib.books_book_id_seq TO lib_senior;

-- штрафы: выставлять и закрывать
GRANT INSERT, UPDATE, DELETE ON TABLE lib.fines TO lib_senior;
GRANT USAGE ON SEQUENCE lib.fines_fine_id_seq TO lib_senior;


-- права ADMIN
-- + управление читателями/сотрудниками + DDL + логи

GRANT lib_senior TO lib_admin;

-- полный доступ к читателям (включая password_hash — нужен для сброса паролей)
GRANT ALL PRIVILEGES ON TABLE lib.readers TO lib_admin;
GRANT USAGE ON SEQUENCE lib.readers_reader_id_seq TO lib_admin;

-- управление сотрудниками
GRANT ALL PRIVILEGES ON TABLE lib.staff TO lib_admin;
GRANT USAGE ON SEQUENCE lib.staff_staff_id_seq TO lib_admin;

-- логи
GRANT SELECT, INSERT ON TABLE lib.access_logs TO lib_admin;
GRANT USAGE ON SEQUENCE lib.access_logs_log_id_seq TO lib_admin;

-- DDL в своей схеме
GRANT CREATE ON SCHEMA lib TO lib_admin;


-- пользователи
-- ВАЖНО: имя PG-роли должно совпадать с username в таблице,
-- иначе функция current_reader_id() в RLS не найдёт запись

-- читатели
CREATE USER ivan    WITH PASSWORD 'IvanPwd!';
CREATE USER natasha WITH PASSWORD 'NatashaPwd!';
CREATE USER anton   WITH PASSWORD 'AntonPwd!';
CREATE USER lena    WITH PASSWORD 'LenaPwd!';
CREATE USER kirill  WITH PASSWORD 'KirillPwd!';
CREATE USER blocker WITH PASSWORD 'BlockerPwd!';

GRANT lib_reader TO ivan, natasha, anton, lena, kirill, blocker;

-- сотрудники
CREATE USER olga   WITH PASSWORD 'OlgaPwd!';
CREATE USER pavel  WITH PASSWORD 'PavelPwd!';
CREATE USER marina WITH PASSWORD 'MarinaPwd!';
CREATE USER sergey WITH PASSWORD 'SergeyPwd!';

GRANT lib_librarian TO olga, pavel;
GRANT lib_senior    TO marina;
GRANT lib_admin     TO sergey;


-- проверки

-- роли и LOGIN
SELECT rolname, rolcanlogin, rolinherit
FROM pg_roles
WHERE rolname LIKE 'lib_%'
   OR rolname IN ('ivan', 'natasha', 'anton', 'lena', 'kirill', 'blocker',
                  'olga', 'pavel', 'marina', 'sergey')
ORDER BY rolcanlogin, rolname;

-- кто в какую роль входит
SELECT r.rolname AS role, m.rolname AS member
FROM pg_auth_members am
JOIN pg_roles r ON am.roleid = r.oid
JOIN pg_roles m ON am.member = m.oid
WHERE r.rolname LIKE 'lib_%'
ORDER BY r.rolname, m.rolname;

-- матрица прав на таблицы lib.*
SELECT grantee, table_name,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS privileges
FROM information_schema.role_table_grants
WHERE table_schema = 'lib'
  AND grantee LIKE 'lib_%'
GROUP BY grantee, table_name
ORDER BY grantee, table_name;

COMMIT;
