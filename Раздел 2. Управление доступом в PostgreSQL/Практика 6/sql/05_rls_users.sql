-- Этап 4.2: RLS для app.users
-- ВНИМАНИЕ: политики на app.users НЕ вызывают app.get_uid_for() напрямую,
-- иначе пойдёт рекурсия (get_uid_for читает app.users). Используем username = current_user
-- и app.get_dept_for() (SECURITY DEFINER) для определения отдела.
ALTER TABLE app.users ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS users_self_read       ON app.users;
DROP POLICY IF EXISTS users_self_update     ON app.users;
DROP POLICY IF EXISTS users_department_read ON app.users;
DROP POLICY IF EXISTS users_admin_all       ON app.users;

CREATE POLICY users_self_read ON app.users FOR SELECT TO app_user
    USING (username = current_user);

CREATE POLICY users_self_update ON app.users FOR UPDATE TO app_user
    USING (username = current_user)
    WITH CHECK (username = current_user);

CREATE POLICY users_department_read ON app.users FOR SELECT TO app_manager
    USING (department_id = app.get_dept_for(current_user));

CREATE POLICY users_admin_all ON app.users FOR ALL TO app_admin
    USING (true) WITH CHECK (true);

\echo === Политики app.users ===
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename='users' ORDER BY policyname;
