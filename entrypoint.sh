#!/bin/bash
set -e

CONFIG_FILE="/var/www/html/config.php"
OPENCART_HOST="${OPENCART_HOST:-localhost}"
OPENCART_PORT="${OPENCART_PORT:-:8090}"
OPENCART_PUBLIC_URL="${OPENCART_PUBLIC_URL:-http://${OPENCART_HOST}${OPENCART_PORT}}"
OPENCART_PUBLIC_URL="${OPENCART_PUBLIC_URL%/}"
OPENCART_ADMIN_DIR="${OPENCART_ADMIN_DIR:-admin_ivo}"
ADMIN_CONFIG_FILE="/var/www/html/${OPENCART_ADMIN_DIR}/config.php"
OPENCART_STORAGE_DIR="${OPENCART_STORAGE_DIR:-/var/www/storage}"
OPENCART_STORAGE_DIR="${OPENCART_STORAGE_DIR%/}"
OPENCART_DATABASE_HOST="${OPENCART_DATABASE_HOST:-mariadb_opencart_demo}"
OPENCART_DATABASE_USER="${OPENCART_DATABASE_USER:-bn_opencart}"
OPENCART_DATABASE_PASSWORD="${OPENCART_DATABASE_PASSWORD:-}"
OPENCART_DATABASE_NAME="${OPENCART_DATABASE_NAME:-bitnami_opencart}"
OPENCART_RESET_DEMO="${OPENCART_RESET_DEMO:-0}"

mysql_args() {
    local args=(--skip-ssl -h "${OPENCART_DATABASE_HOST}" -u "${OPENCART_DATABASE_USER}")

    if [ -n "${OPENCART_DATABASE_PASSWORD}" ]; then
        args+=("-p${OPENCART_DATABASE_PASSWORD}")
    fi

    args+=("${OPENCART_DATABASE_NAME}")
    printf '%s\n' "${args[@]}"
}

run_mysql() {
    mapfile -t args < <(mysql_args)
    mysql "${args[@]}" "$@"
}

restore_demo_files() {
    echo "Resetting OpenCart files from bundled demo image..."
    find /var/www/html -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    mkdir -p "${OPENCART_STORAGE_DIR}"
    find "${OPENCART_STORAGE_DIR}" -mindepth 1 -maxdepth 1 -exec rm -rf {} +
    cp -a /opt/opencart-pristine/. /var/www/html/
    chown -R www-data:www-data /var/www/html
}

prepare_admin_directory() {
    if [ "${OPENCART_ADMIN_DIR}" = "admin" ]; then
        return
    fi

    if [ ! -d "/var/www/html/${OPENCART_ADMIN_DIR}" ] && [ -d /var/www/html/admin ]; then
        echo "Moving admin directory to ${OPENCART_ADMIN_DIR}..."
        mv /var/www/html/admin "/var/www/html/${OPENCART_ADMIN_DIR}"
    fi

    if [ ! -d "/var/www/html/${OPENCART_ADMIN_DIR}" ] && [ -d /opt/opencart-pristine/admin ]; then
        echo "Restoring admin directory as ${OPENCART_ADMIN_DIR}..."
        cp -a /opt/opencart-pristine/admin "/var/www/html/${OPENCART_ADMIN_DIR}"
    fi

    rm -rf /var/www/html/admin
}

prepare_storage_directory() {
    mkdir -p "${OPENCART_STORAGE_DIR}"

    if [ -d /var/www/html/system/storage ]; then
        echo "Moving storage directory outside web root..."
        cp -a /var/www/html/system/storage/. "${OPENCART_STORAGE_DIR}/"
        rm -rf /var/www/html/system/storage
    fi

    if [ ! -f "${OPENCART_STORAGE_DIR}/vendor.php" ] && [ -f /opt/opencart-storage-pristine/vendor.php ]; then
        cp -a /opt/opencart-storage-pristine/. "${OPENCART_STORAGE_DIR}/"
    fi

    mkdir -p \
        "${OPENCART_STORAGE_DIR}/cache" \
        "${OPENCART_STORAGE_DIR}/download" \
        "${OPENCART_STORAGE_DIR}/logs" \
        "${OPENCART_STORAGE_DIR}/modification" \
        "${OPENCART_STORAGE_DIR}/session" \
        "${OPENCART_STORAGE_DIR}/upload"

    chown -R www-data:www-data "${OPENCART_STORAGE_DIR}"
}

reset_demo_database() {
    echo "Resetting OpenCart database from bundled demo dump..."
    run_mysql -Nse "SET FOREIGN_KEY_CHECKS=0; SELECT CONCAT('DROP ', IF(TABLE_TYPE = 'VIEW', 'VIEW', 'TABLE'), ' IF EXISTS \`', TABLE_NAME, '\`;') FROM information_schema.TABLES WHERE TABLE_SCHEMA = DATABASE(); SET FOREIGN_KEY_CHECKS=1;" | run_mysql
    run_mysql < /dump.sql
}

if [ "${OPENCART_RESET_DEMO}" = "1" ] || [ "${OPENCART_RESET_DEMO}" = "true" ]; then
    restore_demo_files
fi

rm -rf /var/www/html/install
prepare_admin_directory
prepare_storage_directory

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
define('DIR_STORAGE', '${OPENCART_STORAGE_DIR}/');
define('DIR_LANGUAGE', '/var/www/html/catalog/language/');
define('DIR_TEMPLATE', '/var/www/html/catalog/view/template/');
define('DIR_CONFIG', '/var/www/html/system/config/');
define('DIR_CACHE', '${OPENCART_STORAGE_DIR}/cache/');
define('DIR_DOWNLOAD', '${OPENCART_STORAGE_DIR}/download/');
define('DIR_LOGS', '${OPENCART_STORAGE_DIR}/logs/');
define('DIR_MODIFICATION', '${OPENCART_STORAGE_DIR}/modification/');
define('DIR_SESSION', '${OPENCART_STORAGE_DIR}/session/');
define('DIR_UPLOAD', '${OPENCART_STORAGE_DIR}/upload/');
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
define('HTTP_SERVER', '${OPENCART_PUBLIC_URL}/${OPENCART_ADMIN_DIR}/');
define('HTTP_CATALOG', '${OPENCART_PUBLIC_URL}/');
define('HTTPS_SERVER', '${OPENCART_PUBLIC_URL}/${OPENCART_ADMIN_DIR}/');
define('HTTPS_CATALOG', '${OPENCART_PUBLIC_URL}/');
define('APPLICATION', 'Admin');
define('DIR_OPENCART', '/var/www/html/');
define('DIR_APPLICATION', '/var/www/html/${OPENCART_ADMIN_DIR}/');
define('DIR_SYSTEM', '/var/www/html/system/');
define('DIR_IMAGE', '/var/www/html/image/');
define('DIR_STORAGE', '${OPENCART_STORAGE_DIR}/');
define('DIR_LANGUAGE', '/var/www/html/${OPENCART_ADMIN_DIR}/language/');
define('DIR_TEMPLATE', '/var/www/html/${OPENCART_ADMIN_DIR}/view/template/');
define('DIR_CONFIG', '/var/www/html/system/config/');
define('DIR_CACHE', '${OPENCART_STORAGE_DIR}/cache/');
define('DIR_DOWNLOAD', '${OPENCART_STORAGE_DIR}/download/');
define('DIR_LOGS', '${OPENCART_STORAGE_DIR}/logs/');
define('DIR_MODIFICATION', '${OPENCART_STORAGE_DIR}/modification/');
define('DIR_SESSION', '${OPENCART_STORAGE_DIR}/session/');
define('DIR_UPLOAD', '${OPENCART_STORAGE_DIR}/upload/');
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

echo "Generating ${OPENCART_ADMIN_DIR}/config.php..."
generate_admin_config

chown www-data:www-data "$CONFIG_FILE" "$ADMIN_CONFIG_FILE"

find /var/www/html -type f \( -name '*.php' -o -name '*.twig' -o -name '*.css' -o -name '*.html' \) \
    -exec sed -i 's#http://fonts.googleapis.com#https://fonts.googleapis.com#g' {} +

echo "Waiting for MariaDB on ${OPENCART_DATABASE_HOST}:3306..."
while ! timeout 2 bash -c "</dev/tcp/${OPENCART_DATABASE_HOST}/3306" 2>/dev/null; do
    sleep 2
done

echo "Waiting for OpenCart database login..."
until run_mysql -e "SELECT 1;" >/dev/null 2>&1; do
    sleep 2
done

if [ "${OPENCART_RESET_DEMO}" = "1" ] || [ "${OPENCART_RESET_DEMO}" = "true" ]; then
    reset_demo_database
elif ! run_mysql -e "SELECT 1 FROM oc_store LIMIT 1;" >/dev/null 2>&1; then
    echo "Importing bundled OpenCart demo database..."
    run_mysql < /dump.sql
fi

echo "Reconciling OpenCart demo database schema..."
run_mysql < /db-patch.sql

echo "Setting demo admin login..."
run_mysql -e "UPDATE oc_user SET username='admin', password=CONCAT(CHAR(36),'2y',CHAR(36),'12',CHAR(36),'aEvP0qBFmE0I2nxKXwUL6u5dI5NTt48dTzZz8G6t8yuSGvW3tGcC2'), firstname='Demo', lastname='Admin', email='admin@example.com', status=1 WHERE user_id=1;"

echo "OpenCart demo is ready: ${OPENCART_PUBLIC_URL}/${OPENCART_ADMIN_DIR} admin/admin123"

exec docker-php-entrypoint "$@"
