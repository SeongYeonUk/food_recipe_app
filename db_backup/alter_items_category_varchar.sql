-- Option A: Relax items.category to VARCHAR with utf8mb4
-- Use in MySQL client as a one‑time migration.

SET NAMES utf8mb4;
SET time_zone = '+00:00';
START TRANSACTION;

-- Ensure the table uses utf8mb4 (optional but recommended)
ALTER TABLE items CONVERT TO CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Change enum column to VARCHAR so new values can be stored without DB enum edits
ALTER TABLE items
  MODIFY category VARCHAR(20)
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci
  NOT NULL;

COMMIT;

-- Verify
-- SHOW COLUMNS FROM items LIKE 'category';
-- Expect: type = varchar(20), collation utf8mb4_unicode_ci, Null = NO

