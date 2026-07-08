#!/bin/bash
set -e

CONFIG_FILE="/var/www/html/config.php"
ADMIN_CONFIG_FILE="/var/www/html/admin/config.php"
OPENCART_HOST="${OPENCART_HOST:-localhost}"
OPENCART_PORT="${OPENCART_PORT:-:8090}"
OPENCART_PUBLIC_URL="${OPENCART_PUBLIC_URL:-http://${OPENCART_HOST}${OPENCART_PORT}}"
OPENCART_PUBLIC_URL="${OPENCART_PUBLIC_URL%/}"
OPENCART_DATABASE_HOST="${OPENCART_DATABASE_HOST:-mariadb_opencart_demo}"
OPENCART_DATABASE_USER="${OPENCART_DATABASE_USER:-bn_opencart}"
OPENCART_DATABASE_PASSWORD="${OPENCART_DATABASE_PASSWORD:-}"
OPENCART_DATABASE_NAME="${OPENCART_DATABASE_NAME:-bitnami_opencart}"

generate_config() {
cat <<EOF > "$CONFIG_FILE"
<?php
define('HTTP_SERVER', '${OPENCART_PUBLIC_URL}/');
define('HTTPS_SERVER', '${OPENCART_PUBLIC_URL}/');
define('APPLICATION', 'Catalog');
define('DIR_OPENCART', '/var/www/html/');
define('DIR_APPLICATION', '/var/www/html/catalog/');
define('DIR_SYSTEM', '/var/www/html/system/');
define('DIR_IMAGE', '/var/www/html/image/');
define('DIR_STORAGE', '/var/www/html/system/storage/');
define('DIR_LANGUAGE', '/var/www/html/catalog/language/');
define('DIR_TEMPLATE', '/var/www/html/catalog/view/template/');
define('DIR_CONFIG', '/var/www/html/system/config/');
define('DIR_CACHE', '/var/www/html/system/storage/cache/');
define('DIR_DOWNLOAD', '/var/www/html/system/storage/download/');
define('DIR_LOGS', '/var/www/html/system/storage/logs/');
define('DIR_MODIFICATION', '/var/www/html/system/storage/modification/');
define('DIR_SESSION', '/var/www/html/system/storage/session/');
define('DIR_UPLOAD', '/var/www/html/system/storage/upload/');
define('DIR_EXTENSION', '/var/www/html/extension/');
define('DB_DRIVER', 'mysqli');
define('DB_HOSTNAME', '${OPENCART_DATABASE_HOST}');
define('DB_USERNAME', '${OPENCART_DATABASE_USER}');
define('DB_PASSWORD', '${OPENCART_DATABASE_PASSWORD}');
define('DB_DATABASE', '${OPENCART_DATABASE_NAME}');
define('DB_PORT', '3306');
define('DB_PREFIX', 'oc_');
define('OPENCART_SERVER', 'https://www.opencart.com/');
EOF
}

generate_admin_config() {
cat <<EOF > "$ADMIN_CONFIG_FILE"
<?php
define('HTTP_SERVER', '${OPENCART_PUBLIC_URL}/admin/');
define('HTTP_CATALOG', '${OPENCART_PUBLIC_URL}/');
define('HTTPS_SERVER', '${OPENCART_PUBLIC_URL}/admin/');
define('HTTPS_CATALOG', '${OPENCART_PUBLIC_URL}/');
define('APPLICATION', 'Admin');
define('DIR_OPENCART', '/var/www/html/');
define('DIR_APPLICATION', '/var/www/html/admin/');
define('DIR_SYSTEM', '/var/www/html/system/');
define('DIR_IMAGE', '/var/www/html/image/');
define('DIR_STORAGE', '/var/www/html/system/storage/');
define('DIR_LANGUAGE', '/var/www/html/admin/language/');
define('DIR_TEMPLATE', '/var/www/html/admin/view/template/');
define('DIR_CONFIG', '/var/www/html/system/config/');
define('DIR_CACHE', '/var/www/html/system/storage/cache/');
define('DIR_DOWNLOAD', '/var/www/html/system/storage/download/');
define('DIR_LOGS', '/var/www/html/system/storage/logs/');
define('DIR_MODIFICATION', '/var/www/html/system/storage/modification/');
define('DIR_SESSION', '/var/www/html/system/storage/session/');
define('DIR_UPLOAD', '/var/www/html/system/storage/upload/');
define('DIR_EXTENSION', '/var/www/html/extension/');
define('DB_DRIVER', 'mysqli');
define('DB_HOSTNAME', '${OPENCART_DATABASE_HOST}');
define('DB_USERNAME', '${OPENCART_DATABASE_USER}');
define('DB_PASSWORD', '${OPENCART_DATABASE_PASSWORD}');
define('DB_DATABASE', '${OPENCART_DATABASE_NAME}');
define('DB_PORT', '3306');
define('DB_PREFIX', 'oc_');
define('OPENCART_SERVER', 'https://www.opencart.com/');
EOF
}

echo "Generating catalog config.php..."
generate_config

echo "Generating admin/config.php..."
generate_admin_config

chown www-data:www-data "$CONFIG_FILE" "$ADMIN_CONFIG_FILE"

find /var/www/html -type f \( -name '*.php' -o -name '*.twig' -o -name '*.css' -o -name '*.html' \) \
    -exec sed -i 's#http://fonts.googleapis.com#https://fonts.googleapis.com#g' {} +

echo "Waiting for MariaDB on ${OPENCART_DATABASE_HOST}:3306..."
while ! timeout 2 bash -c "</dev/tcp/${OPENCART_DATABASE_HOST}/3306" 2>/dev/null; do
    sleep 2
done

echo "Waiting for OpenCart database login..."
until mysql --skip-ssl -h "${OPENCART_DATABASE_HOST}" -u "${OPENCART_DATABASE_USER}" "${OPENCART_DATABASE_NAME}" -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 2
done

if ! mysql --skip-ssl -h "${OPENCART_DATABASE_HOST}" -u "${OPENCART_DATABASE_USER}" "${OPENCART_DATABASE_NAME}" -e "SELECT 1 FROM oc_store LIMIT 1;" >/dev/null 2>&1; then
    echo "Importing bundled OpenCart demo database..."
    mysql --skip-ssl -h "${OPENCART_DATABASE_HOST}" -u "${OPENCART_DATABASE_USER}" "${OPENCART_DATABASE_NAME}" < /dump.sql
fi

echo "Reconciling OpenCart demo database schema..."
mysql --skip-ssl -h "${OPENCART_DATABASE_HOST}" -u "${OPENCART_DATABASE_USER}" "${OPENCART_DATABASE_NAME}" < /db-patch.sql

echo "Setting demo admin login..."
mysql --skip-ssl -h "${OPENCART_DATABASE_HOST}" -u "${OPENCART_DATABASE_USER}" "${OPENCART_DATABASE_NAME}" -e "UPDATE oc_user SET username='admin', password=CONCAT(CHAR(36),'2y',CHAR(36),'12',CHAR(36),'aEvP0qBFmE0I2nxKXwUL6u5dI5NTt48dTzZz8G6t8yuSGvW3tGcC2'), firstname='Demo', lastname='Admin', email='admin@example.com', status=1 WHERE user_id=1;"

echo "OpenCart demo is ready: ${OPENCART_PUBLIC_URL}/admin admin/admin123"

exec docker-php-entrypoint "$@"
