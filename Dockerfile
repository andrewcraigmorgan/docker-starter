# Use PHP 8.4 image
FROM php:8.4-fpm

# Set the user and group IDs as build arguments
ARG DOCKER_UID
ARG DOCKER_GID
ENV DOCKER_UID=${DOCKER_UID}
ENV DOCKER_GID=${DOCKER_GID}

# Install dependencies
RUN apt-get update && apt-get upgrade -y && apt-get install -y --no-install-recommends \
    unzip \
    openssh-client \
    apt-utils \
    sendmail-bin \
    sendmail \
    sudo \
    iproute2 \
    ca-certificates \
    lsb-release \
    software-properties-common \
    libbz2-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libfreetype6-dev \
    libgmp-dev \
    libgpgme11-dev \
    libicu-dev \
    libldap2-dev \
    libpcre3-dev \
    libpspell-dev \
    libtidy-dev \
    libxslt1-dev \
    libyaml-dev \
    libzip-dev \
    zip \
    libonig-dev \
    libmagickwand-dev \
    libmcrypt-dev \
    default-mysql-client \
    vim \
    wget \
    net-tools \
    mc \
    npm \
    iputils-ping \
    dnsutils \
    git \
    && rm -rf /var/lib/apt/lists/*

# Configure and install PHP extensions
RUN docker-php-ext-configure gd --with-freetype --with-jpeg && \
    docker-php-ext-install gd pdo pdo_mysql zip bcmath soap

# Modify the user and group to have the specified UID and GID
RUN groupmod -g ${DOCKER_GID} www-data || true && \
    usermod -u ${DOCKER_UID} -g ${DOCKER_GID} www-data || true

# Update ownership of the working directory
RUN chown -R ${DOCKER_UID}:${DOCKER_GID} /var/www/html

# Clean up unnecessary files
RUN rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /var/www/html

# Install Composer (PHP dependency manager)
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Install Node.js v22 and npm
RUN curl -sL https://deb.nodesource.com/setup_22.x | bash - && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    npm config set cache /var/www/html/.npm-cache && \
    rm -rf /var/lib/apt/lists/*

# Set environment variable for npm cache
ENV NPM_CONFIG_CACHE=/var/www/html/.npm-cache

# Copy the application code with correct ownership
COPY --chown=${DOCKER_UID}:${DOCKER_GID} . /var/www/html/

# Adjust ownership and permissions for entrypoint
RUN chown ${DOCKER_UID}:${DOCKER_GID} /var/www/html/entrypoint.sh && \
    chmod +x /var/www/html/entrypoint.sh

# Set the user to www-data
USER www-data
