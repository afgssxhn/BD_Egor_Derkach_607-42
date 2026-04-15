-- Библиотека: Row-Level Security
-- идея: читатель видит только СВОЮ карточку, СВОИ выдачи, брони, штрафы.
-- сотрудники видят всё.

\c library
SET search_path TO lib, public;

BEGIN;

-- функция-маппер: имя PG-роли -> reader_id
-- БЕЗ SECURITY DEFINER, иначе внутри current_user = postgres и RLS сломается
CREATE OR REPLACE FUNCTION lib.current_reader_id()
RETURNS INTEGER
LANGUAGE SQL
STABLE
AS $$
    SELECT reader_id FROM lib.readers WHERE username = current_user;
$$;

GRANT EXECUTE ON FUNCTION lib.current_reader_id() TO PUBLIC;

-- является ли текущий юзер сотрудником?
CREATE OR REPLACE FUNCTION lib.current_is_staff()
RETURNS BOOLEAN
LANGUAGE SQL
STABLE
AS $$
    SELECT pg_has_role(current_user, 'lib_librarian', 'MEMBER');
$$;

GRANT EXECUTE ON FUNCTION lib.current_is_staff() TO PUBLIC;


-- включаем RLS на "чувствительных" таблицах
-- readers, loans, reservations, fines
-- books — каталог, открыт всем, RLS не нужен
ALTER TABLE lib.readers      ENABLE ROW LEVEL SECURITY;
ALTER TABLE lib.loans        ENABLE ROW LEVEL SECURITY;
ALTER TABLE lib.reservations ENABLE ROW LEVEL SECURITY;
ALTER TABLE lib.fines        ENABLE ROW LEVEL SECURITY;


-- политики для READERS
-- читатель — только свою карточку; сотрудники — всех

CREATE POLICY readers_self_select
    ON lib.readers FOR SELECT
    TO lib_reader
    USING (
        username = current_user
        OR lib.current_is_staff()   -- ветка для librarian+
    );

CREATE POLICY readers_admin_all
    ON lib.readers FOR ALL
    TO lib_admin
    USING (TRUE)
    WITH CHECK (TRUE);


-- политики для LOANS
-- читатель видит только свои; сотрудники — всё и могут менять

CREATE POLICY loans_self_select
    ON lib.loans FOR SELECT
    TO lib_reader
    USING (
        reader_id = lib.current_reader_id()
        OR lib.current_is_staff()
    );

CREATE POLICY loans_staff_modify
    ON lib.loans FOR ALL
    TO lib_librarian
    USING (lib.current_is_staff())
    WITH CHECK (lib.current_is_staff());


-- политики для RESERVATIONS
-- читатель видит только свои брони и создаёт только на себя

CREATE POLICY reservations_self_select
    ON lib.reservations FOR SELECT
    TO lib_reader
    USING (
        reader_id = lib.current_reader_id()
        OR lib.current_is_staff()
    );

CREATE POLICY reservations_self_insert
    ON lib.reservations FOR INSERT
    TO lib_reader
    WITH CHECK (
        reader_id = lib.current_reader_id()
        OR lib.current_is_staff()
    );

CREATE POLICY reservations_self_update
    ON lib.reservations FOR UPDATE
    TO lib_reader
    USING (
        reader_id = lib.current_reader_id()
        OR lib.current_is_staff()
    );

CREATE POLICY reservations_self_delete
    ON lib.reservations FOR DELETE
    TO lib_reader
    USING (
        reader_id = lib.current_reader_id()
        OR lib.current_is_staff()
    );


-- политики для FINES
-- читатель — только свои штрафы; старший и админ — всё

CREATE POLICY fines_self_select
    ON lib.fines FOR SELECT
    TO lib_reader
    USING (
        reader_id = lib.current_reader_id()
        OR lib.current_is_staff()
    );

CREATE POLICY fines_staff_modify
    ON lib.fines FOR ALL
    TO lib_senior
    USING (lib.current_is_staff())
    WITH CHECK (lib.current_is_staff());


-- проверим применённые политики
SELECT schemaname, tablename, policyname, roles, cmd
FROM pg_policies
WHERE schemaname = 'lib'
ORDER BY tablename, policyname;

COMMIT;
