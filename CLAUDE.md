# uhalkinavera.ru Reverse Proxy

## Project Overview
nginx reverse proxy with Let's Encrypt auto-renewal. Proxies uhalkinavera.ru to Wix backend, rewrites all Wix domain references in responses to uhalkinavera.ru subdomains.

## Key Files
- `docker-compose.yml` - nginx + certbot containers
- `nginx.conf` - reverse proxy config with domain substitution
- `init-letsencrypt.sh` - initial certificate acquisition
- `CLAUDE.md` - this file

## Setup Instructions

### Prerequisites
Configure DNS A records pointing to server IP:
- uhalkinavera.ru
- www.uhalkinavera.ru
- static.uhalkinavera.ru
- video.uhalkinavera.ru

### Deploy
```bash
# Edit init-letsencrypt.sh: set email variable
chmod +x init-letsencrypt.sh
./init-letsencrypt.sh
```

Certificates auto-renew every 12h (certbot checks, renews if <30 days remain).

## Development Notes
- `sub_filter` requires `proxy_set_header Host` to match upstream domain
- All subdomains share single certificate (SAN cert)
- HTTP-01 challenge uses `.well-known/acme-challenge/` path
- nginx must restart after initial cert acquisition (handled by init script)
- `sub_filter_types *` applies to all content types including JS/CSS

## Configuration Files

### docker-compose.yml
```yaml
version: '3.8'
services:
  nginx:
    image: nginx:alpine
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./nginx.conf:/etc/nginx/nginx.conf:ro
      - ./certbot/conf:/etc/letsencrypt:ro
      - ./certbot/www:/var/www/certbot:ro
    restart: unless-stopped

  certbot:
    image: certbot/certbot
    volumes:
      - ./certbot/conf:/etc/letsencrypt
      - ./certbot/www:/var/www/certbot
    entrypoint: "/bin/sh -c 'trap exit TERM; while :; do certbot renew; sleep 12h & wait $${!}; done;'"
```

### nginx-ssl.conf
```nginx
events {
    worker_connections 1024;
}

http {
    # HTTP to HTTPS redirect
    server {
        listen 80;
        server_name uhalkinavera.ru www.uhalkinavera.ru static.uhalkinavera.ru video.uhalkinavera.ru;
        
        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }
        
        location / {
            return 301 https://$host$request_uri;
        }
    }

    # Main domain + www
    server {
        listen 443 ssl;
        server_name uhalkinavera.ru www.uhalkinavera.ru;
        
        ssl_certificate /etc/letsencrypt/live/uhalkinavera.ru/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/uhalkinavera.ru/privkey.pem;
        
        location / {
            proxy_pass https://dzaytseva4.wixsite.com/my-site-2/;
            proxy_ssl_server_name on;
            proxy_set_header Host dzaytseva4.wixsite.com;
            
            sub_filter 'dzaytseva4.wixsite.com' 'uhalkinavera.ru';
            sub_filter 'static.wixstatic.com' 'static.uhalkinavera.ru';
            sub_filter 'video.wixstatic.com' 'video.uhalkinavera.ru';
            sub_filter_once off;
            sub_filter_types *;
        }
    }

    # Static subdomain
    server {
        listen 443 ssl;
        server_name static.uhalkinavera.ru;
        
        ssl_certificate /etc/letsencrypt/live/uhalkinavera.ru/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/uhalkinavera.ru/privkey.pem;
        
        location / {
            proxy_pass https://static.wixstatic.com;
            proxy_ssl_server_name on;
            proxy_set_header Host static.wixstatic.com;
            
            sub_filter 'static.wixstatic.com' 'static.uhalkinavera.ru';
            sub_filter_once off;
            sub_filter_types *;
        }
    }

    # Video subdomain
    server {
        listen 443 ssl;
        server_name video.uhalkinavera.ru;
        
        ssl_certificate /etc/letsencrypt/live/uhalkinavera.ru/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/uhalkinavera.ru/privkey.pem;
        
        location / {
            proxy_pass https://video.wixstatic.com;
            proxy_ssl_server_name on;
            proxy_set_header Host video.wixstatic.com;
            
            sub_filter 'video.wixstatic.com' 'video.uhalkinavera.ru';
            sub_filter_once off;
            sub_filter_types *;
        }
    }
}
```

### init-letsencrypt.sh
Need to be fixed to support initial deploy because on first start nginx fails without cert files and same time without nginx certbot cannot issue certs. For init run nginx-init.conf file should be used.

