-- Этап 2: RLS для app.tasks + функции и политики
-- АРХИТЕКТУРА: SECURITY DEFINER функции принимают имя пользователя как параметр.
-- get_uid_for(uname), is_pm_for(project_id, uname), get_dept_for(uname) — обходят RLS под postgres
-- и работают с переданным именем. Это разрывает рекурсию (политика на app.users ↔ функция).
-- Обёртки get_current_user_id() / is_project_manager() для совместимости — без SECURITY DEFINER.

ALTER TABLE app.tasks ENABLE ROW LEVEL SECURITY;

\echo === Флаг RLS на app.tasks ===
SELECT relname, relrowsecurity FROM pg_class WHERE relname='tasks';

-- сначала роняем зависимые политики, чтобы можно было DROP FUNCTION
DROP POLICY IF EXISTS tasks_select_own      ON app.tasks;
DROP POLICY IF EXISTS tasks_insert_own      ON app.tasks;
DROP POLICY IF EXISTS tasks_update_own      ON app.tasks;
DROP POLICY IF EXISTS tasks_delete_own      ON app.tasks;
DROP POLICY IF EXISTS tasks_select_managed  ON app.tasks;
DROP POLICY IF EXISTS tasks_insert_managed  ON app.tasks;
DROP POLICY IF EXISTS tasks_update_managed  ON app.tasks;
DROP POLICY IF EXISTS tasks_delete_managed  ON app.tasks;
DROP POLICY IF EXISTS tasks_admin_all       ON app.tasks;

-- функции
DROP FUNCTION IF EXISTS app.is_project_manager(INT)   CASCADE;
DROP FUNCTION IF EXISTS app.get_current_user_id()     CASCADE;
DROP FUNCTION IF EXISTS app.get_uid_for(TEXT)         CASCADE;
DROP FUNCTION IF EXISTS app.is_pm_for(INT, TEXT)      CASCADE;
DROP FUNCTION IF EXISTS app.get_dept_for(TEXT)        CASCADE;

CREATE FUNCTION app.get_uid_for(uname TEXT) RETURNS INT
LANGUAGE SQL STABLE SECURITY DEFINER AS $func$
    SELECT user_id FROM app.users WHERE username = uname;
$func$;

CREATE FUNCTION app.is_pm_for(p_project_id INT, uname TEXT) RETURNS BOOLEAN
LANGUAGE SQL STABLE SECURITY DEFINER AS $func$
    SELECT EXISTS (
        SELECT 1 FROM app.projects p
        WHERE p.project_id = p_project_id
          AND p.owner_id   = (SELECT user_id FROM app.users WHERE username = uname)
    );
$func$;

CREATE FUNCTION app.get_dept_for(uname TEXT) RETURNS INT
LANGUAGE SQL STABLE SECURITY DEFINER AS $func$
    SELECT department_id FROM app.users WHERE username = uname;
$func$;

-- "методичные" обёртки — INVOKER, вызывают _for-варианты с current_user
CREATE FUNCTION app.get_current_user_id() RETURNS INT
LANGUAGE SQL STABLE AS $func$ SELECT app.get_uid_for(current_user); $func$;

CREATE FUNCTION app.is_project_manager(p_project_id INT) RETURNS BOOLEAN
LANGUAGE SQL STABLE AS $func$ SELECT app.is_pm_for(p_project_id, current_user); $func$;

GRANT EXECUTE ON FUNCTION app.get_uid_for(TEXT)         TO PUBLIC;
GRANT EXECUTE ON FUNCTION app.is_pm_for(INT, TEXT)      TO PUBLIC;
GRANT EXECUTE ON FUNCTION app.get_dept_for(TEXT)        TO PUBLIC;
GRANT EXECUTE ON FUNCTION app.get_current_user_id()     TO PUBLIC;
GRANT EXECUTE ON FUNCTION app.is_project_manager(INT)   TO PUBLIC;

-- app_user: только свои задачи
CREATE POLICY tasks_select_own ON app.tasks FOR SELECT TO app_user
    USING (assignee_id = app.get_uid_for(current_user));
CREATE POLICY tasks_insert_own ON app.tasks FOR INSERT TO app_user
    WITH CHECK (assignee_id = app.get_uid_for(current_user));
CREATE POLICY tasks_update_own ON app.tasks FOR UPDATE TO app_user
    USING (assignee_id = app.get_uid_for(current_user))
    WITH CHECK (assignee_id = app.get_uid_for(current_user));
CREATE POLICY tasks_delete_own ON app.tasks FOR DELETE TO app_user
    USING (assignee_id = app.get_uid_for(current_user));

-- app_manager: свои + задачи своих проектов
CREATE POLICY tasks_select_managed ON app.tasks FOR SELECT TO app_manager
    USING (assignee_id = app.get_uid_for(current_user) OR app.is_pm_for(project_id, current_user));
CREATE POLICY tasks_insert_managed ON app.tasks FOR INSERT TO app_manager
    WITH CHECK (assignee_id = app.get_uid_for(current_user) OR app.is_pm_for(project_id, current_user));
CREATE POLICY tasks_update_managed ON app.tasks FOR UPDATE TO app_manager
    USING      (assignee_id = app.get_uid_for(current_user) OR app.is_pm_for(project_id, current_user))
    WITH CHECK (assignee_id = app.get_uid_for(current_user) OR app.is_pm_for(project_id, current_user));
CREATE POLICY tasks_delete_managed ON app.tasks FOR DELETE TO app_manager
    USING (assignee_id = app.get_uid_for(current_user) OR app.is_pm_for(project_id, current_user));

CREATE POLICY tasks_admin_all ON app.tasks FOR ALL TO app_admin
    USING (true) WITH CHECK (true);

\echo === Политики app.tasks ===
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename='tasks' ORDER BY policyname;
