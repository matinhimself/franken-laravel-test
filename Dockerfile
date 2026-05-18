# =============================================================================
# Base stage — FrankenPHP + PHP extensions + Composer
# Uses only public images; no private registries or APM agent.
# =============================================================================
FROM dunglas/frankenphp:latest AS base

ENV DEBIAN_FRONTEND=noninteractive

# System dependencies (mirrors base.php.Containerfile)
RUN apt-get update && \
    apt-get install -y \
    build-essential ca-certificates locales git curl vim unzip tzdata procps net-tools \
    libcurl4-openssl-dev librabbitmq-dev libonig-dev zlib1g-dev libpng-dev libjpeg-dev \
    libgmp-dev libzip-dev libfreetype-dev npm librdkafka-dev supervisor && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# pie — PHP Extension Installer (replaces pecl)
RUN curl -fsSL https://github.com/php/pie/releases/latest/download/pie.phar \
        -o /usr/local/bin/pie && \
    chmod +x /usr/local/bin/pie

# mpdecimal 4.x from source (required by the decimal extension)
RUN cd /tmp && \
    curl -LO https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-4.0.1.tar.gz && \
    tar xf mpdecimal-4.0.1.tar.gz && cd mpdecimal-4.0.1 && \
    ./configure && make && make install && \
    rm -rf /tmp/mpdecimal-4.0.1*


RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS \
    librabbitmq-dev \
    libssl-dev \
    libzstd-dev \
    libsasl2-dev \
    libmpdec-dev

RUN pie install --no-cache apcu/apcu
RUN pie install --no-cache phpredis/phpredis
RUN pie install --no-cache php-amqp/php-amqp
RUN pie install --no-cache php-decimal/ext-decimal
RUN pie install --no-cache pecl/timezonedb
RUN pie install --no-cache rdkafka/rdkafka
RUN pie install --no-cache open-telemetry/ext-opentelemetry

RUN docker-php-ext-configure gd --with-jpeg --with-freetype && \
    docker-php-ext-install bcmath curl gd opcache pdo_mysql sockets gmp zip pcntl && \
    mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

# Composer + internal proxy (mirrors prod/php.Containerfile)
RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer
RUN composer config -g repo.proxy composer ${COMPOSER_PROXY}
RUN composer config -g repo.packagist false

# Clean up
RUN pear config-set http_proxy "" && rm -rf /tmp/*