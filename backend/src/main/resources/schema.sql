-- Notification Preferences
CREATE TABLE IF NOT EXISTS notification_preferences (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL UNIQUE,
  notify_hour INT NOT NULL DEFAULT 18,
  notify_minute INT NOT NULL DEFAULT 0,
  enabled BIT NOT NULL DEFAULT 1,
  home_only BIT NOT NULL DEFAULT 0
);

-- Home Location
CREATE TABLE IF NOT EXISTS home_locations (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL UNIQUE,
  latitude DOUBLE NOT NULL,
  longitude DOUBLE NOT NULL,
  radius_meters INT NOT NULL DEFAULT 100
);

-- Device Tokens
CREATE TABLE IF NOT EXISTS device_tokens (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  token VARCHAR(255) NOT NULL UNIQUE,
  platform VARCHAR(20) NOT NULL,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Notification Logs
CREATE TABLE IF NOT EXISTS notification_logs (
  id BIGINT PRIMARY KEY AUTO_INCREMENT,
  user_id BIGINT NOT NULL,
  type VARCHAR(30) NOT NULL,
  title VARCHAR(255) NOT NULL,
  body TEXT,
  scheduled_for DATE,
  sent_at TIMESTAMP NULL,
  status VARCHAR(20) NOT NULL DEFAULT 'PENDING'
);

-- App specific schema adjustments (idempotent)
-- Add icon index for items if missing
ALTER TABLE items ADD COLUMN IF NOT EXISTS icon_index INT NOT NULL DEFAULT 0;
