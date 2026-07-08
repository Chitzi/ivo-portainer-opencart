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
