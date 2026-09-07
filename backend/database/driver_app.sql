-- ==============================================================================
-- Cheetah Courier & Logistics - Standalone Mobile App Database
-- Specialized Database for Delivery Driver & Warehouse Picker Mobile Suite
-- Compatible with: MySQL 5.7+, MySQL 8.0+, MariaDB 10.3+
-- Engine: InnoDB | Collation: utf8mb4_unicode_ci
-- ==============================================================================

SET FOREIGN_KEY_CHECKS = 0;
SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";

-- ------------------------------------------------------------------------------
-- Table: branches
-- Logistics fulfillment centers and linehaul branches
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `branches` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `code` varchar(20) NOT NULL,
  `city` varchar(100) NOT NULL,
  `address` text DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `status` tinyint(1) NOT NULL DEFAULT 1,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_branch_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `branches` (`id`, `name`, `code`, `city`, `address`, `phone`, `status`) VALUES
(1, 'Karachi Central Logistics Hub', 'KHI-01', 'Karachi', 'Plot 42, Air Cargo Complex, Airport Road, Karachi', '+92 21 39988771', 1),
(2, 'Lahore Linehaul Terminal', 'LHR-01', 'Lahore', 'Warehouse 8, Multan Road Industrial Estate, Lahore', '+92 42 37788992', 1),
(3, 'Islamabad Express Facility', 'ISB-01', 'Islamabad', 'Sector I-9/2, Dry Port Link Road, Islamabad', '+92 51 35566773', 1)
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- ------------------------------------------------------------------------------
-- Table: users
-- Core authentication and user profile table
-- Demo Accounts:
--   Driver:  rider@cheetah.com  / Rider123
--   Picker:  picker@cheetah.com / Picker123
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `users` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(100) NOT NULL,
  `email` varchar(150) NOT NULL,
  `password` varchar(255) NOT NULL,
  `phone` varchar(30) DEFAULT NULL,
  `role` enum('driver','picker','admin','agent') NOT NULL DEFAULT 'driver',
  `status` tinyint(1) NOT NULL DEFAULT 1,
  `branch_id` int(11) DEFAULT 1,
  `profile_image` varchar(255) DEFAULT NULL,
  `api_token` varchar(64) DEFAULT NULL,
  `api_token_hash` varchar(64) DEFAULT NULL,
  `api_token_expires_at` datetime DEFAULT NULL,
  `fcm_token` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_user_email` (`email`),
  KEY `idx_user_token_hash` (`api_token_hash`),
  KEY `idx_user_role` (`role`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `users` (`id`, `name`, `email`, `password`, `phone`, `role`, `status`, `branch_id`, `profile_image`, `created_at`) VALUES
(1, 'Rashid Khan (Courier Driver)', 'rider@cheetah.com', '$2y$10$v1Hq13HOKnjf1TE87AhvXetRtBQ1.ZJZbxvdIZkwJZXCRpEk6qU2S', '+92 300 1234567', 'driver', 1, 1, 'uploads/profiles/demo_driver.png', NOW()),
(2, 'Ali Raza (Warehouse Picker)', 'picker@cheetah.com', '$2y$10$UG8Be3wYQjPRV6EKoHfZDuAlMcsRueewnLNYHtj37hZs7mnlcI2iS', '+92 321 7654321', 'picker', 1, 1, 'uploads/profiles/demo_picker.png', NOW())
ON DUPLICATE KEY UPDATE `email`=VALUES(`email`);

-- ------------------------------------------------------------------------------
-- Table: drivers
-- Driver specific metadata and vehicle assignment
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `drivers` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `user_id` int(11) NOT NULL,
  `vehicle_type` varchar(50) NOT NULL DEFAULT 'Motorcycle',
  `vehicle_number` varchar(50) NOT NULL DEFAULT 'KHI-7892',
  `license_number` varchar(50) NOT NULL DEFAULT 'DL-99281',
  `max_load_capacity` decimal(8,2) NOT NULL DEFAULT 40.00,
  `status` enum('active','inactive','on_trip') NOT NULL DEFAULT 'active',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_driver_user` (`user_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `drivers` (`id`, `user_id`, `vehicle_type`, `vehicle_number`, `license_number`, `max_load_capacity`, `status`) VALUES
(1, 1, 'Motorcycle (Cargo Box)', 'KHI-7892', 'DL-99281-KHI', 35.00, 'active')
ON DUPLICATE KEY UPDATE `vehicle_number`=VALUES(`vehicle_number`);

-- ------------------------------------------------------------------------------
-- Table: parcels
-- Core shipment records assigned to drivers for last-mile delivery
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `parcels` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `tracking_number` varchar(50) NOT NULL,
  `driver_id` int(11) DEFAULT NULL,
  `origin_branch_id` int(11) NOT NULL DEFAULT 1,
  `destination_branch_id` int(11) NOT NULL DEFAULT 1,
  `sender_name` varchar(150) NOT NULL,
  `sender_phone` varchar(50) NOT NULL,
  `sender_address` text NOT NULL,
  `receiver_name` varchar(150) NOT NULL,
  `receiver_phone` varchar(50) NOT NULL,
  `receiver_address` text NOT NULL,
  `weight` decimal(8,2) NOT NULL DEFAULT 1.00,
  `status` enum('Pending','In Transit','Out for Delivery','Delivered','Returned','Failed Attempt') NOT NULL DEFAULT 'Pending',
  `payment_status` enum('Prepaid','COD','Postpaid') NOT NULL DEFAULT 'COD',
  `amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `cod_collected` tinyint(1) NOT NULL DEFAULT 0,
  `cod_settled` tinyint(1) NOT NULL DEFAULT 0,
  `delivery_otp` varchar(10) DEFAULT NULL,
  `delivery_otp_hash` varchar(64) DEFAULT NULL,
  `delivery_otp_expires_at` datetime DEFAULT NULL,
  `delivery_otp_attempts` int(11) NOT NULL DEFAULT 0,
  `proof_of_delivery` text DEFAULT NULL,
  `signature_data` text DEFAULT NULL,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_tracking_number` (`tracking_number`),
  KEY `idx_parcel_driver` (`driver_id`),
  KEY `idx_parcel_status` (`status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `parcels` (`id`, `tracking_number`, `driver_id`, `origin_branch_id`, `destination_branch_id`, `sender_name`, `sender_phone`, `sender_address`, `receiver_name`, `receiver_phone`, `receiver_address`, `weight`, `status`, `payment_status`, `amount`, `created_at`, `updated_at`) VALUES
(1, 'CHT-KHI-000101', 1, 1, 1, 'TechGadgets Official', '+92 21 34567890', 'Plaza 14, I.I. Chundrigar Rd, Karachi', 'Zubair Ahmed', '+92 300 9876541', 'House 12-B, Block 4, Clifton, Karachi', 1.80, 'Out for Delivery', 'COD', 45.00, NOW(), NOW()),
(2, 'CHT-KHI-000102', 1, 1, 1, 'Glamour Apparel', '+92 21 32345678', 'Dolmen City Mall, Clifton, Karachi', 'Fatima Noor', '+92 321 8765432', 'Flat 402, Sunset Towers, Phase 5 DHA, Karachi', 0.60, 'Out for Delivery', 'Prepaid', 0.00, NOW(), NOW()),
(3, 'CHT-KHI-000103', 1, 1, 1, 'Mega Book Store', '+92 21 31122334', 'Saddar Book Bazaar, Karachi', 'Bilal Tariq', '+92 333 4567890', 'Shop 14, Gulberg Commercial Center, F.B Area, Karachi', 3.20, 'Pending', 'COD', 120.00, NOW(), NOW()),
(4, 'CHT-KHI-000104', 1, 1, 1, 'Apex Electronics', '+92 21 35566778', 'Regal Trade Square, Saddar, Karachi', 'Ayesha Malik', '+92 312 3456789', 'Bungalow 78, Street 9, PECHS Block 2, Karachi', 2.10, 'In Transit', 'COD', 85.50, NOW(), NOW()),
(5, 'CHT-KHI-000105', 1, 1, 1, 'Gourmet Roasters', '+92 21 38899001', 'Khayaban-e-Seher, DHA Phase 6, Karachi', 'Kamran Shah', '+92 345 6789012', 'Office 301, Business Avenue, Shahrah-e-Faisal, Karachi', 0.90, 'Delivered', 'COD', 60.00, NOW(), NOW())
ON DUPLICATE KEY UPDATE `tracking_number`=VALUES(`tracking_number`);

-- ------------------------------------------------------------------------------
-- Table: parcel_history
-- Full lifecycle audit trail for every status change
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `parcel_history` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `parcel_id` int(11) NOT NULL,
  `status` varchar(50) NOT NULL,
  `location` varchar(150) DEFAULT 'Karachi Central Logistics Hub',
  `notes` text DEFAULT NULL,
  `updated_by` int(11) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_history_parcel` (`parcel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `parcel_history` (`parcel_id`, `status`, `location`, `notes`, `updated_by`, `created_at`) VALUES
(1, 'Pending', 'Karachi Central Hub', 'Shipment booked and manifested', 1, NOW()),
(1, 'In Transit', 'Karachi Central Hub', 'Sorted and placed in route bag', 1, NOW()),
(1, 'Out for Delivery', 'Clifton Route', 'Dispatched with Courier Driver Rashid Khan', 1, NOW()),
(5, 'Delivered', 'PECHS Block 2', 'Delivered to consignee with signature & photo POD', 1, NOW());

-- ------------------------------------------------------------------------------
-- Table: driver_locations
-- Real-time GPS telemetry from courier mobile app
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `driver_locations` (
  `id` bigint(20) NOT NULL AUTO_INCREMENT,
  `driver_id` int(11) NOT NULL,
  `latitude` decimal(10,8) NOT NULL,
  `longitude` decimal(11,8) NOT NULL,
  `speed` decimal(5,2) DEFAULT 0.00,
  `heading` decimal(5,2) DEFAULT 0.00,
  `battery_level` int(3) DEFAULT 95,
  `gps_enabled` tinyint(1) NOT NULL DEFAULT 1,
  `is_mock` tinyint(1) NOT NULL DEFAULT 0,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_driver_location_time` (`driver_id`, `created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `driver_locations` (`driver_id`, `latitude`, `longitude`, `speed`, `heading`, `battery_level`, `gps_enabled`, `created_at`) VALUES
(1, 24.86070000, 67.00110000, 24.50, 180.00, 92, 1, NOW());

-- ------------------------------------------------------------------------------
-- Table: driver_commissions
-- Delivery commission earnings per parcel
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `driver_commissions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `driver_id` int(11) NOT NULL,
  `parcel_id` int(11) NOT NULL,
  `amount` decimal(10,2) NOT NULL DEFAULT 5.00,
  `status` enum('pending','paid','cancelled') NOT NULL DEFAULT 'pending',
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `paid_at` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_commission_driver` (`driver_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `driver_commissions` (`driver_id`, `parcel_id`, `amount`, `status`, `created_at`, `paid_at`) VALUES
(1, 5, 5.00, 'paid', DATE_SUB(NOW(), INTERVAL 2 HOUR), NOW()),
(1, 1, 5.00, 'pending', NOW(), NULL);

-- ------------------------------------------------------------------------------
-- Table: driver_wallets
-- Digital wallet for Cash on Delivery (COD) custody & payout balances
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `driver_wallets` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `driver_id` int(11) NOT NULL,
  `balance` decimal(12,2) NOT NULL DEFAULT 0.00,
  `pending_cod` decimal(12,2) NOT NULL DEFAULT 0.00,
  `total_withdrawn` decimal(12,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_wallet_driver` (`driver_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `driver_wallets` (`id`, `driver_id`, `balance`, `pending_cod`, `total_withdrawn`, `created_at`) VALUES
(1, 1, 25.00, 60.00, 100.00, NOW())
ON DUPLICATE KEY UPDATE `balance`=VALUES(`balance`);

-- ------------------------------------------------------------------------------
-- Table: driver_wallet_transactions
-- Immutable ledger of wallet transactions
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `driver_wallet_transactions` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `wallet_id` int(11) NOT NULL,
  `driver_id` int(11) NOT NULL,
  `parcel_id` int(11) DEFAULT NULL,
  `type` enum('commission','cod_deposit','payout','bonus') NOT NULL,
  `amount` decimal(12,2) NOT NULL,
  `balance_after` decimal(12,2) NOT NULL,
  `description` varchar(255) NOT NULL,
  `idempotency_key` varchar(64) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_tx_idempotency` (`idempotency_key`),
  KEY `idx_tx_wallet` (`wallet_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `driver_wallet_transactions` (`wallet_id`, `driver_id`, `parcel_id`, `type`, `amount`, `balance_after`, `description`, `created_at`) VALUES
(1, 1, 5, 'commission', 5.00, 25.00, 'Commission credited for delivering CHT-KHI-000105', NOW());

-- ------------------------------------------------------------------------------
-- Table: driver_login_attempts
-- Brute-force authentication rate limiter
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `driver_login_attempts` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email` varchar(150) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `attempted_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_attempt_rate` (`email`, `ip_address`, `attempted_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- ------------------------------------------------------------------------------
-- Table: wms_stores
-- Merchant / Client stores fulfillment partners
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `wms_stores` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(150) NOT NULL,
  `code` varchar(50) NOT NULL,
  `contact_person` varchar(100) DEFAULT NULL,
  `phone` varchar(50) DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_store_code` (`code`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wms_stores` (`id`, `name`, `code`, `contact_person`, `phone`) VALUES
(1, 'TechMart Electronics Superstore', 'STR-TECH', 'Noman Farooq', '+92 21 34991122'),
(2, 'StyleTrend Apparel & Footwear', 'STR-STYLE', 'Sana Mir', '+92 21 34993344')
ON DUPLICATE KEY UPDATE `name`=VALUES(`name`);

-- ------------------------------------------------------------------------------
-- Table: wms_sales_orders
-- B2B and B2C sales orders queued for warehouse wave fulfillment
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `wms_sales_orders` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_number` varchar(50) NOT NULL,
  `store_id` int(11) NOT NULL DEFAULT 1,
  `customer_name` varchar(150) NOT NULL,
  `customer_phone` varchar(50) NOT NULL,
  `customer_address` text NOT NULL,
  `status` enum('Pending','Allocated','Picking','Prepared','Dispatched','Cancelled') NOT NULL DEFAULT 'Allocated',
  `total_amount` decimal(12,2) NOT NULL DEFAULT 0.00,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `idx_so_number` (`order_number`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wms_sales_orders` (`id`, `order_number`, `store_id`, `customer_name`, `customer_phone`, `customer_address`, `status`, `total_amount`, `created_at`) VALUES
(1, 'SO-2026-0041', 1, 'Hassan Raza', '+92 300 8877665', 'House 45, Sector 11-A, North Karachi', 'Allocated', 380.00, NOW()),
(2, 'SO-2026-0042', 2, 'Mariam Siddiqui', '+92 321 4455667', 'Flat 102, Gulshan Heights, Block 7 Gulshan-e-Iqbal', 'Picking', 145.00, NOW())
ON DUPLICATE KEY UPDATE `order_number`=VALUES(`order_number`);

-- ------------------------------------------------------------------------------
-- Table: wms_pick_tasks
-- Pick tasks dispatched to warehouse pickers with barcode shelf directives
-- ------------------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS `wms_pick_tasks` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `order_id` int(11) NOT NULL,
  `picker_id` int(11) NOT NULL,
  `status` enum('Pending','In Progress','Completed','Cancelled') NOT NULL DEFAULT 'Pending',
  `total_items` int(11) NOT NULL DEFAULT 1,
  `picked_items` int(11) NOT NULL DEFAULT 0,
  `notes` text DEFAULT NULL,
  `created_at` timestamp NOT NULL DEFAULT current_timestamp(),
  `updated_at` timestamp NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_task_picker` (`picker_id`, `status`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT INTO `wms_pick_tasks` (`id`, `order_id`, `picker_id`, `status`, `total_items`, `picked_items`, `notes`, `created_at`) VALUES
(1, 1, 2, 'Pending', 3, 0, 'High priority pick. Fragile electronic items at Bin WH1-Z1-A02-S3-B05', NOW()),
(2, 2, 2, 'In Progress', 2, 1, 'Apparel wave pick at Bin WH1-Z2-A05-S1-B02', NOW())
ON DUPLICATE KEY UPDATE `order_id`=VALUES(`order_id`);

SET FOREIGN_KEY_CHECKS = 1;
COMMIT;
