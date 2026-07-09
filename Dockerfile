FROM php:8.1-apache

ENV OPENCART_VER=4.1.0.3
ENV ISKRA_LANGUAGE_PACK_REF=9ba0821729a0607147b8f1e16b1bfedb6e0693c5

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
    && curl -fsSL -o /tmp/iskra_language_pack.zip "https://github.com/iskra-ecommerce/iskra_language_pack/archive/${ISKRA_LANGUAGE_PACK_REF}.zip" \
    && unzip /tmp/iskra_language_pack.zip -d /tmp/iskra_language_pack \
    && mkdir -p /var/www/html/admin/language /var/www/html/catalog/language \
    && cp -a /tmp/iskra_language_pack/iskra_language_pack-${ISKRA_LANGUAGE_PACK_REF}/admin/language/ro-ro /var/www/html/admin/language/ \
    && cp -a /tmp/iskra_language_pack/iskra_language_pack-${ISKRA_LANGUAGE_PACK_REF}/catalog/language/ro-ro /var/www/html/catalog/language/ \
    && curl -fsSL -o /var/www/html/admin/language/ro-ro/ro-ro.png "https://raw.githubusercontent.com/emilalexe/OpenCart-Romanian/main/ro.png" \
    && cp -a /var/www/html/admin/language/ro-ro/ro-ro.png /var/www/html/catalog/language/ro-ro/ro-ro.png \
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
    && rm -rf /var/lib/apt/lists/* /tmp/opencart /tmp/opencart.zip /tmp/iskra_language_pack /tmp/iskra_language_pack.zip

COPY dump.sql /dump.sql
COPY db-patch.sql /db-patch.sql
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /var/www/html
ENTRYPOINT ["entrypoint.sh"]
CMD ["apache2-foreground"]

EXPOSE 80
