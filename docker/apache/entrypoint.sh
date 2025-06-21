#!/bin/bash

echo "Starting OpenCart Docker entrypoint script..."

# Define OpenCart paths
DIR_OPENCART="/var/www/html" # Bind-mounted opencart/upload
DIR_STORAGE="/storage"       # Persistent storage location (volume)

# Admin credentials
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"
ADMIN_EMAIL="admin@example.com"

# --- WAIT FOR DATABASE ---
echo "Waiting for database to be ready..."
DB_HOST="db"
DB_PORT="3306"
DB_TIMEOUT=60

for i in $(seq 1 $DB_TIMEOUT); do
    nc -z "$DB_HOST" "$DB_PORT" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting for database (${DB_HOST}:${DB_PORT})... ($i/$DB_TIMEOUT)"
    sleep 1
done

nc -z "$DB_HOST" "$DB_PORT" &>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: Database did not become ready within ${DB_TIMEOUT} seconds."
    exit 1
fi

# --- Automatic CLI Installation ---
if [ ! -s "${DIR_OPENCART}/config.php" ]; then
    echo "OpenCart config.php not found or empty. Running CLI installer..."

    INSTALL_CLI_PATH="${DIR_OPENCART}/install/cli_install.php"
    if [ ! -f "${INSTALL_CLI_PATH}" ]; then
        echo "Error: OpenCart CLI installer not found at ${INSTALL_CLI_PATH}"
        echo "Please ensure your opencart/upload directory contains a complete OpenCart installation."
        exit 1
    fi

    php "${INSTALL_CLI_PATH}" install \
        --db_hostname db \
        --db_username "${MYSQL_USER}" \
        --db_password "${MYSQL_PASSWORD}" \
        --db_database "${MYSQL_DATABASE}" \
        --db_driver mysqli \
        --db_port 3306 \
        --username "${ADMIN_USERNAME}" \
        --password "${ADMIN_PASSWORD}" \
        --email "${ADMIN_EMAIL}" \
        --http_server "http://localhost/" \
        --storage_directory "${DIR_STORAGE}" \
        && echo "OpenCart CLI installation completed successfully." \
        || { echo "Error: OpenCart CLI installation failed!"; exit 1; }
else
    echo "OpenCart config.php found. Skipping CLI installation."
fi

# --- Handle storage folder relocation ---
if [ -z "$(ls -A ${DIR_STORAGE} 2>/dev/null)" ] && \
   [ -d "${DIR_OPENCART}/system/storage" ] && \
   [ -n "$(ls -A ${DIR_OPENCART}/system/storage 2>/dev/null)" ]; then
    echo "Relocating OpenCart system/storage content to persistent ${DIR_STORAGE} volume..."
    cp -r ${DIR_OPENCART}/system/storage/* ${DIR_STORAGE}/
    rmdir ${DIR_OPENCART}/system/storage
    echo "Storage content moved successfully."
else
    echo "Storage content already exists in ${DIR_STORAGE} or no content to move from ${DIR_OPENCART}/system/storage."
fi

# --- Set permissions ---
echo "Setting permissions for OpenCart directories..."

if [ "$(id -u)" = "0" ]; then
    echo "Running as root - setting ownership and permissions..."
    chown www-data:www-data "${DIR_STORAGE}"
    chmod 775 "${DIR_STORAGE}"
    
    writable_dirs=(
        "${DIR_STORAGE}/cache"
        "${DIR_STORAGE}/download"
        "${DIR_STORAGE}/logs"
        "${DIR_STORAGE}/session"
        "${DIR_STORAGE}/upload"
        "${DIR_OPENCART}/image/cache"
        "${DIR_OPENCART}/catalog/view/theme/*/stylesheet"
        "${DIR_OPENCART}/system/storage/vendor"
    )

    for dir in "${writable_dirs[@]}"; do
        mkdir -p "$dir"
        echo "Processing writable directory: $dir"
        chown -R www-data:www-data "$dir"
        chmod -R 775 "$dir"
    done

    writable_files=(
        "${DIR_OPENCART}/config.php"
        "${DIR_OPENCART}/admin/config.php"
    )

    for file in "${writable_files[@]}"; do
        if [ -f "$file" ]; then
            echo "Processing config file: $file"
            chown www-data:www-data "$file"
            chmod 664 "$file"
        else
            echo "Warning: Config file expected but not found after CLI install: $file"
        fi
    done
else
    echo "Running as non-root user - setting permissions only..."
    chmod 777 "${DIR_STORAGE}"
    
    writable_dirs=(
        "${DIR_STORAGE}/cache"
        "${DIR_STORAGE}/download"
        "${DIR_STORAGE}/logs"
        "${DIR_STORAGE}/session"
        "${DIR_STORAGE}/upload"
        "${DIR_OPENCART}/image/cache"
        "${DIR_OPENCART}/catalog/view/theme/*/stylesheet"
        "${DIR_OPENCART}/system/storage/vendor"
    )

    for dir in "${writable_dirs[@]}"; do
        mkdir -p "$dir"
        echo "Processing writable directory: $dir"
        chmod -R 777 "$dir"
    done

    writable_files=(
        "${DIR_OPENCART}/config.php"
        "${DIR_OPENCART}/admin/config.php"
    )

    for file in "${writable_files[@]}"; do
        if [ -f "$file" ]; then
            echo "Processing config file: $file"
            chmod 666 "$file"
        else
            echo "Warning: Config file expected but not found after CLI install: $file"
        fi
    done
fi

# Set general read permissions for application files
echo "Setting general read permissions for OpenCart application files..."
find "${DIR_OPENCART}" -type d -exec chmod 755 {} \;
find "${DIR_OPENCART}" -type f -exec chmod 644 {} \;

echo "Permissions set. Starting Apache..."

exec "$@"
