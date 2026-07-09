-- Generated from OpenCart system/helper/db_schema.php.
-- Repairs the bundled demo dump so it matches the runtime schema.

ALTER TABLE `oc_article`
  ADD COLUMN IF NOT EXISTS `rating` int(11) DEFAULT '0' AFTER `author`;

ALTER TABLE `oc_article_comment`
  ADD COLUMN IF NOT EXISTS `parent_id` int(11) DEFAULT '0' AFTER `article_id`,
  ADD COLUMN IF NOT EXISTS `author` varchar(64) AFTER `customer_id`,
  ADD COLUMN IF NOT EXISTS `rating` int(11) DEFAULT '0' AFTER `comment`,
  ADD COLUMN IF NOT EXISTS `ip` varchar(40) AFTER `rating`;

ALTER TABLE `oc_cart`
  ADD COLUMN IF NOT EXISTS `store_id` int(11) DEFAULT '0' AFTER `cart_id`;

ALTER TABLE `oc_customer`
  ADD COLUMN IF NOT EXISTS `commenter` tinyint(1) DEFAULT '0' AFTER `safe`;

ALTER TABLE `oc_customer_wishlist`
  ADD COLUMN IF NOT EXISTS `store_id` int(11) DEFAULT '0' AFTER `customer_id`;

ALTER TABLE `oc_extension_install`
  ADD COLUMN IF NOT EXISTS `description` text AFTER `name`;

ALTER TABLE `oc_option`
  ADD COLUMN IF NOT EXISTS `validation` varchar(255) AFTER `type`;

ALTER TABLE `oc_order_subscription`
  ADD COLUMN IF NOT EXISTS `quantity` int(4) DEFAULT '1' AFTER `product_id`;

ALTER TABLE `oc_product_discount`
  ADD COLUMN IF NOT EXISTS `type` char(1) DEFAULT 'P' AFTER `price`,
  ADD COLUMN IF NOT EXISTS `special` tinyint(1) DEFAULT '0' AFTER `type`;

ALTER TABLE `oc_startup`
  ADD COLUMN IF NOT EXISTS `description` text AFTER `startup_id`;

ALTER TABLE `oc_subscription`
  ADD COLUMN IF NOT EXISTS `trial_tax` decimal(10,4) AFTER `trial_price`,
  ADD COLUMN IF NOT EXISTS `tax` decimal(10,4) AFTER `price`,
  ADD COLUMN IF NOT EXISTS `language` varchar(5) AFTER `subscription_status_id`,
  ADD COLUMN IF NOT EXISTS `currency` varchar(3) AFTER `language`;

ALTER TABLE `oc_theme`
  ADD COLUMN IF NOT EXISTS `status` tinyint(1) DEFAULT '0' AFTER `code`;

ALTER TABLE `oc_user_authorize`
  ADD COLUMN IF NOT EXISTS `date_expire` datetime AFTER `date_added`;

ALTER TABLE `oc_country`
  MODIFY COLUMN `name` varchar(128) NOT NULL DEFAULT '';

ALTER TABLE `oc_zone`
  MODIFY COLUMN `name` varchar(128) NOT NULL DEFAULT '';

CREATE TABLE IF NOT EXISTS `oc_country_description` (
  `country_id` int(11) NOT NULL,
  `language_id` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`country_id`, `language_id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS `oc_zone_description` (
  `zone_id` int(11) NOT NULL,
  `language_id` int(11) NOT NULL,
  `name` varchar(128) NOT NULL,
  PRIMARY KEY (`zone_id`, `language_id`),
  KEY `name` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

INSERT IGNORE INTO `oc_country_description` (`country_id`, `language_id`, `name`)
SELECT `c`.`country_id`, `l`.`language_id`, `c`.`name`
FROM `oc_country` `c`
CROSS JOIN `oc_language` `l`;

INSERT IGNORE INTO `oc_zone_description` (`zone_id`, `language_id`, `name`)
SELECT `z`.`zone_id`, `l`.`language_id`, `z`.`name`
FROM `oc_zone` `z`
CROSS JOIN `oc_language` `l`;

CREATE TABLE IF NOT EXISTS `oc_identifier` (
  `identifier_id` int(11) NOT NULL AUTO_INCREMENT,
  `name` varchar(64) NOT NULL,
  `code` varchar(48) NOT NULL,
  `validation` varchar(255) NOT NULL,
  `status` tinyint(1) NOT NULL DEFAULT '0',
  PRIMARY KEY (`identifier_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

CREATE TABLE IF NOT EXISTS `oc_product_code` (
  `product_code_id` int(11) NOT NULL AUTO_INCREMENT,
  `product_id` int(11) NOT NULL,
  `code` varchar(48) NOT NULL,
  `value` varchar(255) NOT NULL,
  PRIMARY KEY (`product_code_id`),
  KEY `product_id` (`product_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci ROW_FORMAT=DYNAMIC;

-- Normalize known columns whose old demo types/defaults break OpenCart 4.1 runtime writes.
ALTER TABLE `oc_cart`
  MODIFY COLUMN `customer_id` int(11) NOT NULL DEFAULT 0,
  MODIFY COLUMN `session_id` varchar(32) NOT NULL DEFAULT '',
  MODIFY COLUMN `subscription_plan_id` int(11) NOT NULL DEFAULT 0,
  MODIFY COLUMN `quantity` int(5) NOT NULL DEFAULT 0,
  MODIFY COLUMN `override` text NOT NULL,
  MODIFY COLUMN `price` decimal(15,4) NOT NULL DEFAULT 0.0000;

-- OpenCart 4.1 stores specials in oc_product_discount with special = 1.
INSERT INTO `oc_product_discount` (`product_id`, `customer_group_id`, `quantity`, `priority`, `price`, `type`, `special`, `date_start`, `date_end`)
SELECT `ps`.`product_id`, `ps`.`customer_group_id`, 1, `ps`.`priority`, `ps`.`price`, 'F', 1, `ps`.`date_start`, `ps`.`date_end`
FROM `oc_product_special` `ps`
WHERE NOT EXISTS (
  SELECT 1 FROM `oc_product_discount` `pd`
  WHERE `pd`.`product_id` = `ps`.`product_id`
    AND `pd`.`customer_group_id` = `ps`.`customer_group_id`
    AND `pd`.`quantity` = 1
    AND `pd`.`priority` = `ps`.`priority`
    AND `pd`.`price` = `ps`.`price`
    AND `pd`.`special` = 1
);

-- The bundled dump marks voucher totals as installed, but OpenCart 4.1.0.3 no
-- longer ships extension/opencart/catalog/model/total/voucher.php.
DELETE FROM `oc_extension`
WHERE `extension` = 'opencart' AND `type` = 'total' AND `code` = 'voucher';

DELETE FROM `oc_setting`
WHERE `code` = 'total_voucher';

DELETE FROM `oc_setting`
WHERE `store_id` = 0
  AND `code` = 'config'
  AND `key` IN ('config_image_default_width', 'config_image_default_height');

INSERT INTO `oc_setting` (`store_id`, `code`, `key`, `value`, `serialized`)
VALUES
  (0, 'config', 'config_image_default_width', '100', 0),
  (0, 'config', 'config_image_default_height', '100', 0);

-- IVO demo hero product: Samsung Galaxy Z Fold7 with Color and Memory variants.
SET @ro_language_id := (SELECT `language_id` FROM `oc_language` WHERE `code` = 'ro-ro' LIMIT 1);

REPLACE INTO `oc_manufacturer` (`manufacturer_id`, `name`, `image`, `sort_order`)
VALUES (777, 'Samsung', 'catalog/demo/samsung_tab_1.jpg', 0);

REPLACE INTO `oc_manufacturer_to_store` (`manufacturer_id`, `store_id`)
VALUES (777, 0);

REPLACE INTO `oc_option` (`option_id`, `type`, `validation`, `sort_order`)
VALUES
  (777, 'radio', '', 1),
  (778, 'radio', '', 2);

REPLACE INTO `oc_option_description` (`option_id`, `language_id`, `name`)
VALUES
  (777, 1, 'Color'),
  (778, 1, 'Memory');

INSERT INTO `oc_option_description` (`option_id`, `language_id`, `name`)
SELECT 777, @ro_language_id, 'Culoare'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `oc_option_description` (`option_id`, `language_id`, `name`)
SELECT 778, @ro_language_id, 'Memorie'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

REPLACE INTO `oc_option_value` (`option_value_id`, `option_id`, `image`, `sort_order`)
VALUES
  (7771, 777, '', 1),
  (7772, 777, '', 2),
  (7773, 777, '', 3),
  (7781, 778, '', 1),
  (7782, 778, '', 2);

REPLACE INTO `oc_option_value_description` (`option_value_id`, `language_id`, `option_id`, `name`)
VALUES
  (7771, 1, 777, 'Jetblack'),
  (7772, 1, 777, 'Blue Shadow'),
  (7773, 1, 777, 'Silver Shadow'),
  (7781, 1, 778, '12GB + 256GB'),
  (7782, 1, 778, '12GB + 512GB');

INSERT INTO `oc_option_value_description` (`option_value_id`, `language_id`, `option_id`, `name`)
SELECT 7771, @ro_language_id, 777, 'Jetblack'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `oc_option_value_description` (`option_value_id`, `language_id`, `option_id`, `name`)
SELECT 7772, @ro_language_id, 777, 'Blue Shadow'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `oc_option_value_description` (`option_value_id`, `language_id`, `option_id`, `name`)
SELECT 7773, @ro_language_id, 777, 'Silver Shadow'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `oc_option_value_description` (`option_value_id`, `language_id`, `option_id`, `name`)
SELECT 7781, @ro_language_id, 778, '12GB + 256GB'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

INSERT INTO `oc_option_value_description` (`option_value_id`, `language_id`, `option_id`, `name`)
SELECT 7782, @ro_language_id, 778, '12GB + 512GB'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE `name` = VALUES(`name`);

REPLACE INTO `oc_product` (
  `product_id`, `master_id`, `model`, `sku`, `upc`, `ean`, `jan`, `isbn`, `mpn`, `location`,
  `variant`, `override`, `quantity`, `stock_status_id`, `image`, `manufacturer_id`, `shipping`,
  `price`, `points`, `tax_class_id`, `date_available`, `weight`, `weight_class_id`, `length`,
  `width`, `height`, `length_class_id`, `subtract`, `minimum`, `rating`, `sort_order`, `status`,
  `date_added`, `date_modified`
) VALUES (
  777, 0, 'SM-F966B', 'ZFOLD7-12-256-JB', '', '', '', '', '', '',
  '', '', 100, 7, 'catalog/demo/samsung_tab_1.jpg', 777, 1,
  1999.9900, 0, 9, CURDATE(), 0.21500000, 1, 158.40000000,
  72.80000000, 8.90000000, 1, 1, 1, 0, -100, 1,
  NOW(), NOW()
);

SET @fold7_description := '<p><strong>Samsung Galaxy Z Fold7 AI Foldable Smartphone</strong> with 3-Year Manufacturer Warranty, 12GB RAM, 256GB Storage, 6.5&quot;/8&quot; Display, 200MP Camera, long-lasting battery, and Jet Black finish.</p><p>Experience the thinnest and lightest Galaxy Z Fold ever, with ultra-sleek design and a large foldable display. Galaxy Z Fold7 is even more durable thanks to its Advanced Armor Aluminum chassis and Corning Gorilla Glass Ceramic protected display.</p><ul><li>AI foldable smartphone</li><li>12GB RAM with 256GB or 512GB storage variants</li><li>Jetblack, Blue Shadow, and Silver Shadow color variants</li><li>6.5&quot; cover display and 8&quot; main display</li><li>200MP camera system</li><li>3-Year Manufacturer Warranty</li></ul>';

REPLACE INTO `oc_product_description` (`product_id`, `language_id`, `name`, `description`, `tag`, `meta_title`, `meta_description`, `meta_keyword`)
VALUES (
  777, 1,
  'Samsung Galaxy Z Fold7 AI Foldable Smartphone',
  @fold7_description,
  'Samsung, Galaxy Z Fold7, foldable, AI smartphone, 200MP',
  'Samsung Galaxy Z Fold7 AI Foldable Smartphone',
  'Samsung Galaxy Z Fold7 with 12GB RAM, 256GB storage, foldable 6.5 inch and 8 inch displays, 200MP camera, and 3-Year Manufacturer Warranty.',
  'Samsung Galaxy Z Fold7, foldable smartphone, AI phone'
);

INSERT INTO `oc_product_description` (`product_id`, `language_id`, `name`, `description`, `tag`, `meta_title`, `meta_description`, `meta_keyword`)
SELECT
  777, @ro_language_id,
  'Samsung Galaxy Z Fold7 AI Foldable Smartphone',
  @fold7_description,
  'Samsung, Galaxy Z Fold7, foldable, AI smartphone, 200MP',
  'Samsung Galaxy Z Fold7 AI Foldable Smartphone',
  'Samsung Galaxy Z Fold7 with 12GB RAM, 256GB storage, foldable 6.5 inch and 8 inch displays, 200MP camera, and 3-Year Manufacturer Warranty.',
  'Samsung Galaxy Z Fold7, foldable smartphone, AI phone'
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `description` = VALUES(`description`),
  `tag` = VALUES(`tag`),
  `meta_title` = VALUES(`meta_title`),
  `meta_description` = VALUES(`meta_description`),
  `meta_keyword` = VALUES(`meta_keyword`);

INSERT INTO `oc_category_description` (`category_id`, `language_id`, `name`, `description`, `meta_title`, `meta_description`, `meta_keyword`)
SELECT 24, @ro_language_id, 'Telefoane si PDA', '', 'Telefoane si PDA', '', ''
WHERE @ro_language_id IS NOT NULL
ON DUPLICATE KEY UPDATE
  `name` = VALUES(`name`),
  `meta_title` = VALUES(`meta_title`);

REPLACE INTO `oc_product_to_category` (`product_id`, `category_id`)
VALUES (777, 24);

REPLACE INTO `oc_product_to_store` (`product_id`, `store_id`)
VALUES (777, 0);

DELETE FROM `oc_product_image`
WHERE `product_id` = 777;

INSERT INTO `oc_product_image` (`product_id`, `image`, `sort_order`)
VALUES
  (777, 'catalog/demo/samsung_tab_2.jpg', 1),
  (777, 'catalog/demo/samsung_tab_3.jpg', 2),
  (777, 'catalog/demo/samsung_tab_4.jpg', 3);

DELETE FROM `oc_product_option_value`
WHERE `product_id` = 777;

DELETE FROM `oc_product_option`
WHERE `product_id` = 777;

REPLACE INTO `oc_product_option` (`product_option_id`, `product_id`, `option_id`, `value`, `required`)
VALUES
  (77701, 777, 777, '', 1),
  (77702, 777, 778, '', 1);

REPLACE INTO `oc_product_option_value` (
  `product_option_value_id`, `product_option_id`, `product_id`, `option_id`, `option_value_id`,
  `quantity`, `subtract`, `price`, `price_prefix`, `points`, `points_prefix`, `weight`, `weight_prefix`
) VALUES
  (777001, 77701, 777, 777, 7771, 50, 1, 0.0000, '+', 0, '+', 0.00000000, '+'),
  (777002, 77701, 777, 777, 7772, 50, 1, 0.0000, '+', 0, '+', 0.00000000, '+'),
  (777003, 77701, 777, 777, 7773, 50, 1, 0.0000, '+', 0, '+', 0.00000000, '+'),
  (777004, 77702, 777, 778, 7781, 75, 1, 0.0000, '+', 0, '+', 0.00000000, '+'),
  (777005, 77702, 777, 778, 7782, 75, 1, 200.0000, '+', 0, '+', 0.00000000, '+');

REPLACE INTO `oc_seo_url` (`seo_url_id`, `store_id`, `language_id`, `key`, `value`, `keyword`, `sort_order`)
VALUES
  (7771, 0, 1, 'product_id', '777', 'samsung-galaxy-z-fold7', 1),
  (7772, 0, COALESCE(@ro_language_id, 1), 'product_id', '777', 'samsung-galaxy-z-fold7-ro', 1);

UPDATE `oc_module`
SET `setting` = '{"name":"Featured","product_name":"","product":["777","43","40","42"],"axis":"horizontal","limit":"4","width":"200","height":"200","status":"1"}'
WHERE `code` = 'opencart.featured';
