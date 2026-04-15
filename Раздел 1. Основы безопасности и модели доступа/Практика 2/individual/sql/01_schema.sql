-- Индивидуальный проект "Библиотека"
-- файл 1: схема и таблицы
-- порядок: создать БД library, этот файл, потом seed

-- CREATE DATABASE library;
\c library;

CREATE SCHEMA IF NOT EXISTS lib;
SET search_path TO lib, public;


-- читатели
CREATE TABLE lib.readers (
    reader_id       SERIAL PRIMARY KEY,
    ticket_number   VARCHAR(20) UNIQUE NOT NULL,       -- номер читательского
    username        VARCHAR(50) UNIQUE NOT NULL,       -- совпадает с PG-ролью
    full_name       VARCHAR(100) NOT NULL,
    email           VARCHAR(100),
    phone           VARCHAR(20),
    password_hash   VARCHAR(255) NOT NULL,
    is_blocked      BOOLEAN DEFAULT FALSE,             -- блок за долги
    registered_at   DATE DEFAULT CURRENT_DATE
);


-- сотрудники (отдельно от читателей)
CREATE TABLE lib.staff (
    staff_id       SERIAL PRIMARY KEY,
    username       VARCHAR(50) UNIQUE NOT NULL,        -- совпадает с PG-ролью
    full_name      VARCHAR(100) NOT NULL,
    position       VARCHAR(30) NOT NULL
                   CHECK (position IN ('librarian', 'senior', 'admin')),
    hired_at       DATE DEFAULT CURRENT_DATE
);


-- каталог книг
CREATE TABLE lib.books (
    book_id           SERIAL PRIMARY KEY,
    title             VARCHAR(200) NOT NULL,
    author            VARCHAR(150) NOT NULL,
    isbn              VARCHAR(20) UNIQUE,
    year_published    INTEGER CHECK (year_published BETWEEN 1500 AND 2100),
    total_copies      INTEGER NOT NULL DEFAULT 1 CHECK (total_copies >= 0),
    available_copies  INTEGER NOT NULL DEFAULT 1 CHECK (available_copies >= 0),
    added_by          INTEGER REFERENCES lib.staff(staff_id),
    added_at          DATE DEFAULT CURRENT_DATE,
    CHECK (available_copies <= total_copies)
);


-- выдачи: кто, что, когда, вернул ли
CREATE TABLE lib.loans (
    loan_id        SERIAL PRIMARY KEY,
    book_id        INTEGER NOT NULL REFERENCES lib.books(book_id),
    reader_id      INTEGER NOT NULL REFERENCES lib.readers(reader_id),
    librarian_id   INTEGER REFERENCES lib.staff(staff_id),   -- кто выдал
    issued_at      DATE DEFAULT CURRENT_DATE,
    due_date       DATE NOT NULL,                            -- срок возврата
    returned_at    DATE                                      -- NULL пока не вернули
);


-- брони
CREATE TABLE lib.reservations (
    reservation_id  SERIAL PRIMARY KEY,
    book_id         INTEGER NOT NULL REFERENCES lib.books(book_id),
    reader_id       INTEGER NOT NULL REFERENCES lib.readers(reader_id),
    reserved_at     TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    status          VARCHAR(20) DEFAULT 'active'
                    CHECK (status IN ('active', 'fulfilled', 'cancelled'))
);


-- штрафы
CREATE TABLE lib.fines (
    fine_id     SERIAL PRIMARY KEY,
    reader_id   INTEGER NOT NULL REFERENCES lib.readers(reader_id),
    loan_id     INTEGER REFERENCES lib.loans(loan_id),
    amount      NUMERIC(10,2) NOT NULL CHECK (amount > 0),
    reason      VARCHAR(200),
    issued_at   DATE DEFAULT CURRENT_DATE,
    paid_at     DATE,
    issued_by   INTEGER REFERENCES lib.staff(staff_id)
);


-- логи доступа (аудит)
CREATE TABLE lib.access_logs (
    log_id      SERIAL PRIMARY KEY,
    username    VARCHAR(50) NOT NULL,
    action      VARCHAR(50) NOT NULL,
    target      VARCHAR(50),
    logged_at   TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);


-- индексы на FK и частые фильтры
CREATE INDEX idx_loans_reader        ON lib.loans(reader_id);
CREATE INDEX idx_loans_book          ON lib.loans(book_id);
CREATE INDEX idx_loans_returned      ON lib.loans(returned_at);
CREATE INDEX idx_reservations_reader ON lib.reservations(reader_id);
CREATE INDEX idx_fines_reader        ON lib.fines(reader_id);
CREATE INDEX idx_books_author        ON lib.books(author);


-- проверка, что всё создалось
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'lib'
ORDER BY table_name;
