-- Библиотека: проверка RLS

\c library
SET search_path TO lib, public;


\echo --- Тест 1. IVAN (reader, id=1): видит только свою карточку ---
BEGIN;
SET LOCAL ROLE ivan;
SELECT reader_id, ticket_number, full_name FROM lib.readers;
COMMIT;


\echo --- Тест 2. IVAN: видит только свои выдачи ---
BEGIN;
SET LOCAL ROLE ivan;
SELECT loan_id, book_id, reader_id, due_date, returned_at FROM lib.loans;
COMMIT;


\echo --- Тест 3. ANTON (reader, id=3): своя задолженность ---
BEGIN;
SET LOCAL ROLE anton;
SELECT loan_id, book_id, due_date FROM lib.loans WHERE returned_at IS NULL;
\echo -- и свой штраф
SELECT fine_id, amount, reason FROM lib.fines;
COMMIT;


\echo --- Тест 4. LENA: попытка брони на чужое имя ---
BEGIN;
SET LOCAL ROLE lena;

\echo -- своя бронь — ок
INSERT INTO lib.reservations (book_id, reader_id) VALUES (7, 4)
RETURNING reservation_id, reader_id;

\echo -- чужая бронь (на Ивана) — упадёт по RLS (WITH CHECK)
INSERT INTO lib.reservations (book_id, reader_id) VALUES (7, 1)
RETURNING reservation_id;

ROLLBACK;


\echo --- Тест 5. OLGA (librarian): видит всё (ветка is_staff) ---
BEGIN;
SET LOCAL ROLE olga;
SELECT COUNT(*) AS всех_читателей FROM lib.readers;
SELECT COUNT(*) AS всех_выдач    FROM lib.loans;
SELECT COUNT(*) AS всех_броней   FROM lib.reservations;
SELECT COUNT(*) AS всех_штрафов  FROM lib.fines;
COMMIT;


\echo --- Тест 6. MARINA (senior): штраф любому читателю ---
BEGIN;
SET LOCAL ROLE marina;
INSERT INTO lib.fines (reader_id, amount, reason, issued_by)
VALUES (5, 25.00, 'Тестовый штраф от senior', 3)
RETURNING fine_id, reader_id, amount;
ROLLBACK;


\echo --- Тест 7. SERGEY (admin): полный обзор ---
BEGIN;
SET LOCAL ROLE sergey;
SELECT COUNT(*) AS всех_читателей FROM lib.readers;
SELECT COUNT(*) AS всех_выдач    FROM lib.loans;
SELECT COUNT(*) AS всех_броней   FROM lib.reservations;
COMMIT;
