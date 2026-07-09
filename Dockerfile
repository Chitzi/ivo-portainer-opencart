FROM php:8.1-apache

ENV OPENCART_VER=4.1.0.3

RUN apt-get update \
    && apt-get install -y --no-install-recommends \
        curl \
        default-mysql-client \
        libfreetype6-dev \
        libjpeg-dev \
        libpng-dev \
        libzip-dev \
        unzip \
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j"$(nproc)" gd mysqli zip \
    && a2enmod rewrite \
    && curl -fsSL -o /tmp/opencart.zip "https://github.com/opencart/opencart/releases/download/${OPENCART_VER}/opencart-${OPENCART_VER}.zip" \
    && unzip /tmp/opencart.zip -d /tmp/opencart \
    && if [ -d "/tmp/opencart/upload" ]; then mv /tmp/opencart/upload/* /var/www/html/; else mv /tmp/opencart/*/upload/* /var/www/html/; fi \
    && mv /var/www/html/config-dist.php /var/www/html/config.php \
    && mv /var/www/html/admin/config-dist.php /var/www/html/admin/config.php \
    && mkdir -p /var/www/storage \
    && cp -a /var/www/html/system/storage/. /var/www/storage/ \
    && rm -rf /var/www/html/install \
    && rm -rf /var/www/html/system/storage \
    && chown -R www-data:www-data /var/www/html \
    && chown -R www-data:www-data /var/www/storage \
    && mkdir -p /opt/opencart-pristine \
    && mkdir -p /opt/opencart-storage-pristine \
    && cp -a /var/www/html/. /opt/opencart-pristine/ \
    && cp -a /var/www/storage/. /opt/opencart-storage-pristine/ \
    && rm -rf /var/lib/apt/lists/* /tmp/opencart /tmp/opencart.zip

COPY dump.sql /dump.sql
COPY db-patch.sql /db-patch.sql
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

EXPOSE 80
