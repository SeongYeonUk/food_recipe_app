-- Add view count and created_at columns to recipe table
ALTER TABLE `recipe`
  ADD COLUMN `view_count` BIGINT NOT NULL DEFAULT 0,
  ADD COLUMN `created_at` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP;

-- Backfill existing rows
UPDATE `recipe` SET `created_at` = NOW() WHERE `created_at` IS NULL;
