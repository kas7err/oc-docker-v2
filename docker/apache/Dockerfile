FROM php:7.4-apache

ENV DIR_OPENCART='/var/www/html/'
ENV DIR_STORAGE='/storage/'

# Install required PHP extensions and system dependencies for OpenCart
RUN apt-get update && apt-get install -y \
    libzip-dev \
    libonig-dev \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libcurl4-openssl-dev \
    libxml2-dev \
    zlib1g-dev \
    libicu-dev \
    zip \
    unzip \
    git \
    netcat-traditional \
    && rm -rf /var/lib/apt/lists/*

# Install core PHP extensions
RUN docker-php-ext-install pdo_mysql mysqli curl mbstring dom zip intl soap opcache

# Configure and install GD extension with JPEG support
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd

# Create the /storage directory inside the container's image.
# This is where the named volume for storage will later be mounted.
RUN mkdir -p ${DIR_STORAGE}

# Set initial, permissive permissions for the /storage directory.
# The entrypoint.sh will set more specific ownership/permissions after the volume mounts.
RUN chmod 777 ${DIR_STORAGE}

# Enable Apache modules (mod_rewrite is essential for OpenCart's SEO URLs)
RUN a2enmod rewrite

# Copy custom Apache virtual host config
COPY httpd-opencart.conf /etc/apache2/sites-available/000-default.conf

# Copy entrypoint script and make it executable
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

# Set the entrypoint to our custom script
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["apache2-foreground"]
