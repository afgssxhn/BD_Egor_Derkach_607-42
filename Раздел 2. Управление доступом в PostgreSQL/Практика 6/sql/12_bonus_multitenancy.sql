-- Этап 11 (БОНУС Вариант A): мультитенантная изоляция через переменную сессии
\set ON_ERROR_STOP off

CREATE SCHEMA IF NOT EXISTS tenant_demo;

DROP TABLE IF EXISTS tenant_demo.invoices CASCADE;
CREATE TABLE tenant_demo.invoices (
    invoice_id    SERIAL PRIMARY KEY,
    tenant_id     INT NOT NULL,
    customer_name TEXT NOT NULL,
    amount        NUMERIC(10,2) NOT NULL,
    created_at    TIMESTAMP NOT NULL DEFAULT NOW()
);

INSERT INTO tenant_demo.invoices (tenant_id, customer_name, amount) VALUES
    (1, 'Acme Corp',          1500.00),
    (1, 'Acme Corp',          2300.50),
    (1, 'Initech',             900.00),
    (2, 'Hooli',              4200.75),
    (2, 'Pied Piper',         3100.00),
    (2, 'Bachmanity',          800.25),
    (3, 'Stark Industries',  10500.00),
    (3, 'Wayne Enterprises',  7800.40);

-- роль приложения (NOLOGIN-контейнер + LOGIN-пользователь, как в Практике 4–5)
DROP ROLE IF EXISTS tenant_app_user;
DROP ROLE IF EXISTS tenant_app;

CREATE ROLE tenant_app NOLOGIN;
CREATE ROLE tenant_app_user LOGIN PASSWORD 'TenantApp123!' INHERIT;
GRANT tenant_app TO tenant_app_user;

GRANT USAGE ON SCHEMA tenant_demo TO tenant_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON tenant_demo.invoices TO tenant_app;
GRANT USAGE ON SEQUENCE tenant_demo.invoices_invoice_id_seq TO tenant_app;

-- RLS
ALTER TABLE tenant_demo.invoices ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS invoices_tenant_isolation ON tenant_demo.invoices;
CREATE POLICY invoices_tenant_isolation ON tenant_demo.invoices FOR ALL TO tenant_app
    USING      (tenant_id = current_setting('app.current_tenant_id', true)::INT)
    WITH CHECK (tenant_id = current_setting('app.current_tenant_id', true)::INT);

\echo === Тест 1: tenant_id=1 ===
BEGIN;
SET LOCAL ROLE tenant_app_user;
SET LOCAL app.current_tenant_id = '1';
SELECT invoice_id, tenant_id, customer_name, amount FROM tenant_demo.invoices ORDER BY invoice_id;
COMMIT;

\echo === Тест 2: tenant_id=2 ===
BEGIN;
SET LOCAL ROLE tenant_app_user;
SET LOCAL app.current_tenant_id = '2';
SELECT invoice_id, tenant_id, customer_name, amount FROM tenant_demo.invoices ORDER BY invoice_id;
COMMIT;

\echo === Тест 3: tenant_id=3 ===
BEGIN;
SET LOCAL ROLE tenant_app_user;
SET LOCAL app.current_tenant_id = '3';
SELECT invoice_id, tenant_id, customer_name, amount FROM tenant_demo.invoices ORDER BY invoice_id;
COMMIT;

\echo === Тест 4: INSERT tenant_id=2 при контексте tenant=1 → отказ WITH CHECK ===
BEGIN;
SET LOCAL ROLE tenant_app_user;
SET LOCAL app.current_tenant_id = '1';
INSERT INTO tenant_demo.invoices (tenant_id, customer_name, amount) VALUES (2, 'Sneaky Insert', 999.00);
COMMIT;

\echo === Тест 5: INSERT tenant_id=1 при контексте tenant=1 → успех ===
BEGIN;
SET LOCAL ROLE tenant_app_user;
SET LOCAL app.current_tenant_id = '1';
INSERT INTO tenant_demo.invoices (tenant_id, customer_name, amount) VALUES (1, 'Legit Insert', 555.00)
RETURNING invoice_id, tenant_id, customer_name;
COMMIT;

\echo === Тест 6: без SET LOCAL app.current_tenant_id → 0 строк (безопасный default) ===
BEGIN;
SET LOCAL ROLE tenant_app_user;
SELECT COUNT(*) FROM tenant_demo.invoices;
COMMIT;

\echo === Финальная проверка под postgres — все 9 инвойсов на месте ===
SELECT tenant_id, COUNT(*), SUM(amount) FROM tenant_demo.invoices GROUP BY tenant_id ORDER BY tenant_id;
