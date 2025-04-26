#!/bin/bash

# Create storage and bootstrap/cache directories if they don't exist
mkdir -p /var/www/html/storage/framework/sessions
mkdir -p /var/www/html/storage/framework/views
mkdir -p /var/www/html/storage/framework/cache/data
mkdir -p /var/www/html/storage/logs
mkdir -p /var/www/html/bootstrap/cache

# Set correct permissions
chown -R www-data:www-data /var/www/html/storage /var/www/html/bootstrap/cache
chmod -R 775 /var/www/html/storage /var/www/html/bootstrap/cache

# Install dependencies
echo "Installing Composer dependencies..."
composer install --no-interaction --prefer-dist

echo "Installing NPM dependencies..."
npm install --no-audit --no-fund

# Run migrations if not in production
if [ "$APP_ENV" != "production" ]; then
    echo "Running migrations..."
    php artisan migrate
fi

# Generate the application key only if it doesn't exist
if [ -f ".env" ] && ! grep -q "^APP_KEY=base64" .env; then
    echo "Generating application key..."
    php artisan key:generate
else
    echo "Application key already exists. Skipping key generation."
fi

# Generate JWT secret if not set
if [ -f ".env" ] && ! grep -q "^JWT_SECRET=" .env; then
    echo "Generating JWT secret..."
    php artisan jwt:secret
else
    echo "JWT secret already exists. Skipping generation."
fi

php artisan telescope:publish

# Clear and cache various application components
echo "Clearing and optimizing application..."
php artisan optimize:clear

# Run Vite in production
echo "Running Vite build..."
./node_modules/.bin/vite build

# Start PHP-FPM as the main process
echo "Starting PHP-FPM..."
exec php-fpm
