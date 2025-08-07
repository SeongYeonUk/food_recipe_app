-- =====================================================================
-- refrigerator_db 데이터베이스 설정 스크립트 (원본 유지 수정본)
-- =====================================================================

-- 1. 데이터베이스가 없다면 만들고, 사용하도록 선택합니다.
CREATE DATABASE IF NOT EXISTS refrigerator_db;
USE refrigerator_db;

-- 2. users 테이블을 올바른 제약조건으로 생성합니다.
DROP TABLE IF EXISTS `users`;
CREATE TABLE `users` (
  `id` bigint NOT NULL AUTO_INCREMENT,
  `uid` varchar(255) NOT NULL,
  `password` varchar(255) NOT NULL,
  `nickname` varchar(255) NOT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `UK_uid` (`uid`),       -- [수정] uid에 UNIQUE KEY 제약조건 추가
  UNIQUE KEY `UK_nickname` (`nickname`) -- [수정] 닉네임 UNIQUE KEY 이름 변경
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;



-- 4. Spring Boot 애플리케이션이 사용할 사용자를 생성하고 권한을 부여합니다.
-- (사용자가 없을 때만 생성하므로 여러 번 실행해도 오류가 나지 않습니다.)
CREATE USER IF NOT EXISTS 'refrigerator_user'@'localhost' IDENTIFIED BY 'ahqkdlf#01';
GRANT ALL PRIVILEGES ON refrigerator_db.* TO 'refrigerator_user'@'localhost';
FLUSH PRIVILEGES;

SELECT 'Original-style DB setup completed.' AS status;
