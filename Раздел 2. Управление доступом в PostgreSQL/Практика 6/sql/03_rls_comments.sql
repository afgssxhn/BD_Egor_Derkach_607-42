-- Этап 3: RLS для app.comments (использует _for-функции из 02_rls_tasks.sql)
ALTER TABLE app.comments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS comments_user_read     ON app.comments;
DROP POLICY IF EXISTS comments_user_insert   ON app.comments;
DROP POLICY IF EXISTS comments_user_update   ON app.comments;
DROP POLICY IF EXISTS comments_user_delete   ON app.comments;
DROP POLICY IF EXISTS comments_manager_read  ON app.comments;
DROP POLICY IF EXISTS comments_manager_insert ON app.comments;
DROP POLICY IF EXISTS comments_manager_update ON app.comments;
DROP POLICY IF EXISTS comments_manager_delete ON app.comments;
DROP POLICY IF EXISTS comments_admin_all     ON app.comments;

-- app_user: свои + не-внутренние к своим задачам
CREATE POLICY comments_user_read ON app.comments FOR SELECT TO app_user
    USING (
        user_id = app.get_uid_for(current_user)
        OR (
            task_id IN (SELECT task_id FROM app.tasks WHERE assignee_id = app.get_uid_for(current_user))
            AND is_internal = false
        )
    );

CREATE POLICY comments_user_insert ON app.comments FOR INSERT TO app_user
    WITH CHECK (
        task_id IN (SELECT task_id FROM app.tasks WHERE assignee_id = app.get_uid_for(current_user))
        AND user_id = app.get_uid_for(current_user)
        AND is_internal = false
    );

CREATE POLICY comments_user_update ON app.comments FOR UPDATE TO app_user
    USING (user_id = app.get_uid_for(current_user))
    WITH CHECK (user_id = app.get_uid_for(current_user) AND is_internal = false);

CREATE POLICY comments_user_delete ON app.comments FOR DELETE TO app_user
    USING (user_id = app.get_uid_for(current_user));

-- app_manager и app_admin: полный доступ
CREATE POLICY comments_manager_read   ON app.comments FOR SELECT TO app_manager USING (true);
CREATE POLICY comments_manager_insert ON app.comments FOR INSERT TO app_manager WITH CHECK (true);
CREATE POLICY comments_manager_update ON app.comments FOR UPDATE TO app_manager USING (true) WITH CHECK (true);
CREATE POLICY comments_manager_delete ON app.comments FOR DELETE TO app_manager USING (true);
CREATE POLICY comments_admin_all      ON app.comments FOR ALL    TO app_admin   USING (true) WITH CHECK (true);

\echo === Политики app.comments ===
SELECT policyname, cmd, roles FROM pg_policies WHERE tablename='comments' ORDER BY policyname;
