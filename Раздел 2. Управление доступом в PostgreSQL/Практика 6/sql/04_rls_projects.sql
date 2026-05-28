-- Этап 4.1: RLS для app.projects
ALTER TABLE app.projects ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS projects_user_read     ON app.projects;
DROP POLICY IF EXISTS projects_manager_read  ON app.projects;
DROP POLICY IF EXISTS projects_manager_write ON app.projects;
DROP POLICY IF EXISTS projects_admin_all     ON app.projects;

CREATE POLICY projects_user_read ON app.projects FOR SELECT TO app_user
    USING (
        project_id IN (SELECT project_id FROM app.tasks WHERE assignee_id = app.get_uid_for(current_user))
        OR owner_id = app.get_uid_for(current_user)
    );

CREATE POLICY projects_manager_read ON app.projects FOR SELECT TO app_manager
    USING (
        owner_id = app.get_uid_for(current_user)
        OR department_id = app.get_dept_for(current_user)
    );

CREATE POLICY projects_manager_write ON app.projects FOR ALL TO app_manager
    USING (owner_id = app.get_uid_for(current_user))
    WITH CHECK (owner_id = app.get_uid_for(current_user));

CREATE POLICY projects_admin_all ON app.projects FOR ALL TO app_admin
    USING (true) WITH CHECK (true);

\echo === Политики app.projects ===
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename='projects' ORDER BY policyname;
