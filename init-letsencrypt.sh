#!/bin/bash

domains=(uhalkinavera.ru www.uhalkinavera.ru static.uhalkinavera.ru video.uhalkinavera.ru)
email="your-email@example.com"  # CHANGE THIS

echo "### Stopping any existing containers..."
docker-compose down

echo "### Creating certbot directories..."
mkdir -p certbot/conf certbot/www

echo "### Removing nginx.conf if it exists as directory..."
if [ -d "nginx.conf" ]; then
    rm -rf nginx.conf
fi

echo "### Using nginx-init.conf for initial setup (HTTP only)..."
cp nginx-init.conf nginx.conf

echo "### Starting nginx with HTTP-only config..."
docker-compose up -d nginx

echo "### Waiting for nginx to start..."
sleep 5

echo "### Requesting Let's Encrypt certificate for ${domains[*]}..."
docker-compose run --rm certbot certonly --webroot \
    -w /var/www/certbot \
    --email $email \
    --agree-tos \
    --no-eff-email \
    -d ${domains[0]} \
    -d ${domains[1]} \
    -d ${domains[2]} \
    -d ${domains[3]}

echo "### Switching to SSL configuration..."
cp nginx-ssl.conf nginx.conf

echo "### Restarting nginx with SSL config..."
docker-compose restart nginx

echo "### Starting certbot renewal service..."
docker-compose up -d certbot

echo "### Done! Your site should now be accessible at https://uhalkinavera.ru"
