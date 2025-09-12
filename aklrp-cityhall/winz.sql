-- WINZ Food Grant table (MySQL 8.x)
CREATE TABLE IF NOT EXISTS `winz_food_grants` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(64) NOT NULL,
  `license` VARCHAR(64) DEFAULT NULL,
  `fullname` VARCHAR(80) NOT NULL,
  `why_need` TEXT NOT NULL,
  `what_left_short` TEXT NOT NULL,
  `phone` VARCHAR(30) NOT NULL,
  `amount` INT NOT NULL,
  `status` ENUM('pending','approved','denied') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_by` VARCHAR(80) DEFAULT NULL,
  `reviewed_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


-- WINZ Money Grant table (Phone/Car/Clothing/Power/Rent)
CREATE TABLE IF NOT EXISTS `winz_money_grants` (
  `id` INT NOT NULL AUTO_INCREMENT,
  `citizenid` VARCHAR(64) NOT NULL,
  `license` VARCHAR(64) DEFAULT NULL,
  `fullname` VARCHAR(80) NOT NULL,
  `purpose` ENUM('Phone','Car','Clothing','Power','Rent') NOT NULL,
  `amount` INT NOT NULL,
  `what_left_short` TEXT NOT NULL,
  `status` ENUM('pending','approved','denied') NOT NULL DEFAULT 'pending',
  `created_at` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  `reviewed_by` VARCHAR(80) DEFAULT NULL,
  `reviewed_at` TIMESTAMP NULL DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_status` (`status`),
  KEY `idx_citizenid` (`citizenid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
