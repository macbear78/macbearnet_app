-- Run once on MariaDB (local or Lightsail) after creating database & user
CREATE TABLE IF NOT EXISTS site_greeting (
  id TINYINT UNSIGNED NOT NULL PRIMARY KEY,
  message VARCHAR(255) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO site_greeting (id, message) VALUES (1, '맥베어에 오신 것을 환영합니다')
  ON DUPLICATE KEY UPDATE message = VALUES(message);
