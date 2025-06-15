#!/bin/bash

echo "Setting permissions for OpenCart storage directories..."

# Define directories and files OpenCart needs to write to
writable_dirs=(
    "/var/www/html/system/storage"
    "/var/www/html/image/cache"
    "/var/www/html/image/catalog"
    "/var/www/html/image/data"
    "/var/www/html/download"
    "/var/www/html/image/"
    "/var/www/html/catalog/view/stylesheet"
)

writable_files=(
    "/var/www/html/config.php"
    "/var/www/html/admin/config.php"
)

# Set ownership and permissions for directories
for dir in "${writable_dirs[@]}"; do
    if [ -d "$dir" ]; then
        echo "Processing directory: $dir"
        chown -R www-data:www-data "$dir"
        chmod -R 775 "$dir"
    else
        echo "Warning: Directory not found (will be created by OpenCart if necessary): $dir"
        # Optional: create missing directories if you want them guaranteed
        # mkdir -p "$dir"
        # chown -R www-data:www-data "$dir"
        # chmod -R 775 "$dir"
    fi
done

# Set ownership and permissions for files
for file in "${writable_files[@]}"; do
    if [ -f "$file" ]; then
        echo "Processing file: $file"
        chown www-data:www-data "$file"
        chmod 664 "$file"
    else
        echo "Warning: File not found (ensure you copied config.php from config-dist.php): $file"
    fi
done

echo "Permissions set. Starting Apache..."

# Execute the original Apache CMD (which is apache2-foreground)
exec "$@"
