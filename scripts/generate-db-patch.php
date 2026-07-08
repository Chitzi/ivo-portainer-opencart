<?php

$schemaFile = $argv[1] ?? '/tmp/opencart-db_schema.php';
$dumpFile = $argv[2] ?? __DIR__ . '/../dump.sql';

require $schemaFile;

$dump = file_get_contents($dumpFile);

if ($dump === false) {
    fwrite(STDERR, "Unable to read dump file: {$dumpFile}\n");
    exit(1);
}

preg_match_all('/CREATE TABLE `oc_([^`]+)` \((.*?)\)\s+ENGINE=/s', $dump, $matches, PREG_SET_ORDER);

$dumpTables = [];

foreach ($matches as $match) {
    preg_match_all('/^\s+`([^`]+)`\s+/m', $match[2], $columns);
    $dumpTables[$match[1]] = array_flip($columns[1]);
}

function columnDefinition(array $field): string {
    $definition = '`' . $field['name'] . '` ' . $field['type'];

    if (!empty($field['not_null'])) {
        $definition .= ' NOT NULL';
    }

    if (array_key_exists('default', $field)) {
        $definition .= " DEFAULT '" . str_replace("'", "''", (string)$field['default']) . "'";
    }

    return $definition;
}

echo "-- Generated from OpenCart system/helper/db_schema.php.\n";
echo "-- Repairs the bundled demo dump so it matches the runtime schema.\n\n";

foreach (oc_db_schema() as $table) {
    $tableName = $table['name'];

    if (!isset($dumpTables[$tableName])) {
        continue;
    }

    $previous = null;
    $missing = [];

    foreach ($table['field'] as $field) {
        if (!isset($dumpTables[$tableName][$field['name']])) {
            $sql = '  ADD COLUMN IF NOT EXISTS ' . columnDefinition($field);

            if ($previous !== null) {
                $sql .= ' AFTER `' . $previous . '`';
            }

            $missing[] = $sql;
        }

        $previous = $field['name'];
    }

    if ($missing) {
        echo 'ALTER TABLE `oc_' . $tableName . "`\n";
        echo implode(",\n", $missing) . ";\n\n";
    }
}

echo "-- Normalize known columns whose old demo types/defaults break OpenCart 4.1 runtime writes.\n";
echo "ALTER TABLE `oc_cart`\n";
echo "  MODIFY COLUMN `customer_id` int(11) NOT NULL DEFAULT 0,\n";
echo "  MODIFY COLUMN `session_id` varchar(32) NOT NULL DEFAULT '',\n";
echo "  MODIFY COLUMN `subscription_plan_id` int(11) NOT NULL DEFAULT 0,\n";
echo "  MODIFY COLUMN `quantity` int(5) NOT NULL DEFAULT 0,\n";
echo "  MODIFY COLUMN `override` text NOT NULL,\n";
echo "  MODIFY COLUMN `price` decimal(15,4) NOT NULL DEFAULT 0.0000;\n\n";

echo "-- OpenCart 4.1 stores specials in oc_product_discount with special = 1.\n";
echo "INSERT INTO `oc_product_discount` (`product_id`, `customer_group_id`, `quantity`, `priority`, `price`, `type`, `special`, `date_start`, `date_end`)\n";
echo "SELECT `ps`.`product_id`, `ps`.`customer_group_id`, 1, `ps`.`priority`, `ps`.`price`, 'F', 1, `ps`.`date_start`, `ps`.`date_end`\n";
echo "FROM `oc_product_special` `ps`\n";
echo "WHERE NOT EXISTS (\n";
echo "  SELECT 1 FROM `oc_product_discount` `pd`\n";
echo "  WHERE `pd`.`product_id` = `ps`.`product_id`\n";
echo "    AND `pd`.`customer_group_id` = `ps`.`customer_group_id`\n";
echo "    AND `pd`.`quantity` = 1\n";
echo "    AND `pd`.`priority` = `ps`.`priority`\n";
echo "    AND `pd`.`price` = `ps`.`price`\n";
echo "    AND `pd`.`special` = 1\n";
echo ");\n";
