#!/bin/bash

echo "Starting OpenCart Docker entrypoint script..."

# Define OpenCart paths (matching ENV in Dockerfile)
DIR_OPENCART="/var/www/html" # This is our bind-mounted opencart/upload
DIR_STORAGE="/storage"       # This is the new persistent storage location (volume)

# Define admin username/password/email (can be pulled from .env if added there)
ADMIN_USERNAME="admin"
ADMIN_PASSWORD="admin"
ADMIN_EMAIL="admin@example.com"


# --- WAIT FOR DATABASE ---
echo "Waiting for database to be ready..."
DB_HOST="db"  # Use the service name defined in docker-compose.yml
DB_PORT="3306"
DB_TIMEOUT=60 # seconds

# Loop until DB port is open or timeout
for i in $(seq 1 $DB_TIMEOUT); do
    nc -z "$DB_HOST" "$DB_PORT" &>/dev/null
    if [ $? -eq 0 ]; then
        echo "Database is ready!"
        break
    fi
    echo "Waiting for database (${DB_HOST}:${DB_PORT})... ($i/$DB_TIMEOUT)"
    sleep 1
done

# Check if the database is actually reachable
nc -z "$DB_HOST" "$DB_PORT" &>/dev/null
if [ $? -ne 0 ]; then
    echo "Error: Database did not become ready within ${DB_TIMEOUT} seconds."
    exit 1
fi

# --- Automatic CLI Installation (if not already installed) ---
# Check if config.php exists and is non-empty. If so, assume OpenCart is installed.
if [ ! -s "${DIR_OPENCART}/config.php" ]; then
    echo "OpenCart config.php not found or empty. Running CLI installer..."

    # Ensure the installer directory exists (it should from the OpenCart source)
    INSTALL_CLI_PATH="${DIR_OPENCART}/install/cli_install.php"
    if [ ! -f "${INSTALL_CLI_PATH}" ]; then
        echo "Error: OpenCart CLI installer not found at ${INSTALL_CLI_PATH}"
        echo "Please ensure your opencart/upload directory contains a complete OpenCart installation."
        exit 1
    fi

    # Run the CLI installer
    # Using 'db' as hostname as it's the Docker service name for MySQL
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

    # After successful CLI install, delete the install directory for security
    # echo "Removing installer directory for security..."
    # rm -rf "${DIR_OPENCART}/install"
else
    echo "OpenCart config.php found. Skipping CLI installation."
fi


# --- Handle system/storage folder relocation (only if content exists and isn't already in /storage) ---
# Check if the new storage location (${DIR_STORAGE}) is empty AND
# if the old storage location (${DIR_OPENCART}/system/storage) exists and has content.
if [ -z "$(ls -A ${DIR_STORAGE} 2>/dev/null)" ] && \
   [ -d "${DIR_OPENCART}/system/storage" ] && \
   [ -n "$(ls -A ${DIR_OPENCART}/system/storage 2>/dev/null)" ]; then
    echo "Relocating OpenCart system/storage content to persistent ${DIR_STORAGE} volume..."
    cp -r ${DIR_OPENCART}/system/storage/* ${DIR_STORAGE}/
    # Remove the now empty original storage directory on the bind mount.
    # OpenCart expects this to be gone after the move.
    rmdir ${DIR_OPENCART}/system/storage
    echo "Storage content moved successfully."
else
    echo "Storage content already exists in ${DIR_STORAGE} or no content to move from ${DIR_OPENCART}/system/storage."
fi

# --- Set permissions for OpenCart files and directories ---
echo "Setting permissions for OpenCart directories..."

# Ensure the base /storage directory itself is owned by www-data
chown www-data:www-data "${DIR_STORAGE}"
# Give www-data full access, others read/execute for the top-level storage dir
chmod 775 "${DIR_STORAGE}"

# Define directories OpenCart needs to write to.
# These will be subdirectories within ${DIR_STORAGE} or directly in web root.
writable_dirs=(
    "${DIR_STORAGE}/cache"
    "${DIR_STORAGE}/download"
    "${DIR_STORAGE}/logs"
    "${DIR_STORAGE}/session"
    "${DIR_STORAGE}/upload"
    "${DIR_OPENCART}/image/cache"          # Image cache remains under web root
    "${DIR_OPENCART}/catalog/view/theme/*/stylesheet" # For SASS compilation in themes
    "${DIR_OPENCART}/system/storage/vendor" # OpenCart 3.x vendor folder (if not moved to storage root)
    # Add any other folders needing write permissions
)

for dir in "${writable_dirs[@]}"; do
    mkdir -p "$dir" # Ensure directory exists
    echo "Processing writable directory: $dir"
    chown -R www-data:www-data "$dir"
    chmod -R 775 "$dir"
done

# Set permissions for config files (now managed by CLI installer)
# Ensure config.php and admin/config.php are owned by www-data and have correct permissions
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

# Set general read-only permissions for the main application files
echo "Setting general read permissions for OpenCart application files..."
chown -R www-data:www-data "${DIR_OPENCART}" # Ensure www-data is owner of app files
# Directories 755 (rwxr-xr-x), files 644 (rw-r--r--)
chmod -R 755 "${DIR_OPENCART}"
find "${DIR_OPENCART}" -type f -exec chmod 644 {} \;

echo "Permissions set. Starting Apache..."

# Execute the original Apache CMD (crucial for container to stay running)
exec "$@"
