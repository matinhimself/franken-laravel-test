ARG BASE_IMAGE=php:8.5-fpm
FROM ${BASE_IMAGE}

ENV DEBIAN_FRONTEND=noninteractive

# System deps — mirrors base.php.Containerfile
RUN apt-get update && \
    apt-get install -y \
    build-essential ca-certificates locales git curl vim unzip tzdata procps net-tools \
    libcurl4-openssl-dev librabbitmq-dev libonig-dev zlib1g-dev libpng-dev libjpeg-dev \
    libgmp-dev libzip-dev libfreetype-dev npm librdkafka-dev supervisor && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Build tools required by pecl for C extensions (opentelemetry, protobuf, etc.)
RUN apt-get update && apt-get install -y \
    $PHPIZE_DEPS gcc g++ make \
 && rm -rf /var/lib/apt/lists/*

# mpdecimal from source (required by ext-decimal)
RUN cd /tmp && \
    curl -LO https://www.bytereef.org/software/mpdecimal/releases/mpdecimal-2.5.1.tar.gz && \
    tar xf mpdecimal-2.5.1.tar.gz && cd mpdecimal-2.5.1 && \
    ./configure && make && make install && \
    rm -rf /tmp/mpdecimal-2.5.1*

# PHP extensions — base.php.Containerfile set + opentelemetry (pre-installed in the FrankenPHP base but absent from plain FPM)
RUN pecl install protobuf && docker-php-ext-enable protobuf
RUN pecl install opentelemetry && docker-php-ext-enable opentelemetry
RUN pecl install apcu && docker-php-ext-enable apcu
RUN pecl install redis && docker-php-ext-enable redis
RUN pecl install amqp && docker-php-ext-enable amqp
RUN pecl install decimal && docker-php-ext-enable decimal
RUN pecl install timezonedb && docker-php-ext-enable timezonedb
RUN pecl install rdkafka && docker-php-ext-enable rdkafka
RUN docker-php-ext-configure gd --with-jpeg --with-freetype
RUN docker-php-ext-install bcmath
RUN docker-php-ext-install curl 
RUN docker-php-ext-install gd 
RUN docker-php-ext-install pdo_mysql 
RUN docker-php-ext-install sockets 
RUN docker-php-ext-install gmp 
RUN docker-php-ext-install zip 
RUN docker-php-ext-install pcntl
RUN docker-php-ext-enable opcache
RUN rm -rf /tmp/pear

RUN curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer

WORKDIR /srv/app