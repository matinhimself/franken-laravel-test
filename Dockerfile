# =============================================================================
# Base stage — FrankenPHP + PHP extensions + Composer
# Uses only public images; no private registries or APM agent.
# =============================================================================
FROM dunglas/frankenphp:latest AS base

RUN apt-get update && \
    apt-get install -y \
    build-essential ca-certificates locales git curl unzip tzdata procps net-tools \
    libcurl4-openssl-dev librabbitmq-dev libonig-dev zlib1g-dev libpng-dev libjpeg-dev \
    libgmp-dev libzip-dev libfreetype-dev && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# mpdecimal is required by the decimal PHP extension (removed from Debian bookworm)
RUN cd /tmp && \
    curl -LO https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-2.5.1.tar.gz && \
    tar xf mpdecimal-2.5.1.tar.gz && cd mpdecimal-2.5.1 && \
    ./configure && make && make install && \
    rm -rf /tmp/mpdecimal-2.5.1*

RUN install-php-extensions \
    pdo_mysql \
    apcu \
    redis \
    amqp \
    decimal \
    timezonedb \
    bcmath \
    gd \
    intl \
    gmp \
    zip \
    opcache \
    pcntl \
    sockets

RUN mv "$PHP_INI_DIR/php.ini-production" "$PHP_INI_DIR/php.ini"

RUN curl -sS https://getcomposer.org/installer | php -- \
    --install-dir=/usr/local/bin --filename=composer

# =============================================================================
# App stage — Install dependencies and copy application code
# =============================================================================
FROM base AS app

WORKDIR /app

COPY composer.json ./

RUN mkdir -p database/factories database/migrations database/seeds tests

RUN --mount=type=cache,target=/root/.composer/cache \
    composer install --no-scripts --no-progress --optimize-autoloader

COPY --chown=www-data:www-data . .

RUN chown -R www-data:www-data database tests
