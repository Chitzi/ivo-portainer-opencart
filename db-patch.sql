ALTER TABLE `oc_cart`
  ADD COLUMN IF NOT EXISTS `store_id` int(11) NOT NULL DEFAULT 0 AFTER `cart_id`,
  MODIFY COLUMN `customer_id` int(11) NOT NULL DEFAULT 0,
  MODIFY COLUMN `session_id` varchar(32) NOT NULL DEFAULT '',
  MODIFY COLUMN `subscription_plan_id` int(11) NOT NULL DEFAULT 0,
  MODIFY COLUMN `quantity` int(5) NOT NULL DEFAULT 0,
  MODIFY COLUMN `override` text NOT NULL,
  MODIFY COLUMN `price` decimal(15,4) NOT NULL DEFAULT 0.0000;

ALTER TABLE `oc_theme`
  ADD COLUMN IF NOT EXISTS `status` tinyint(1) NOT NULL DEFAULT 0 AFTER `code`;
