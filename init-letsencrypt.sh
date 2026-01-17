#!/bin/bash

domains=(uhalkinavera.ru www.uhalkinavera.ru static.uhalkinavera.ru video.uhalkinavera.ru)
email="your-email@example.com"  # CHANGE THIS

echo "### Creating certbot directories..."
mkdir -p certbot/conf certbot/www

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

echo "### Starting nginx and certbot services..."
docker-compose up -d

echo "### Done! Your site should now be accessible at https://uhalkinavera.ru"
