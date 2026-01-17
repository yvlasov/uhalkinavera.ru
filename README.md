# uhalkinavera.ru Reverse Proxy

Nginx reverse proxy with Let's Encrypt SSL certificates that proxies uhalkinavera.ru to a Wix site, rewriting all Wix domain references to custom subdomains.

## Features

- Automatic SSL certificate generation and renewal via Let's Encrypt
- Domain rewriting from Wix domains to custom subdomains
- HTTP to HTTPS redirect
- Supports main domain, www, and resource subdomains (static, video)
- Auto-renewal checks every 12 hours

## Architecture

```
┌─────────────────────────────────────────────────┐
│  uhalkinavera.ru                                │
│  www.uhalkinavera.ru          ┌────────────────┐│
│  static.uhalkinavera.ru  ───► │  nginx:alpine  ││
│  video.uhalkinavera.ru        └────────┬───────┘│
│                                        │        │
│                         ┌──────────────┘        │
│                         │                       │
│                ┌────────▼────────┐              │
│                │ certbot/certbot │              │
│                └─────────────────┘              │
└─────────────────────────────────────────────────┘
                         │
                         ▼
         ┌───────────────────────────────┐
         │  dzaytseva4.wixsite.com       │
         │  static.wixstatic.com         │
         │  video.wixstatic.com          │
         └───────────────────────────────┘
```

## Prerequisites

1. **Docker and Docker Compose** installed on your server
2. **DNS A records** configured for:
   - uhalkinavera.ru
   - www.uhalkinavera.ru
   - static.uhalkinavera.ru
   - video.uhalkinavera.ru

   All pointing to your server's public IP address

3. **Ports 80 and 443** open on your server firewall

## Setup Instructions

### 1. Clone or copy project files

Ensure you have these files in your project directory:
```
uhalkinavera.ru/
├── docker-compose.yml
├── nginx.conf
├── init-letsencrypt.sh
└── README.md
```

### 2. Configure email for Let's Encrypt

Edit `init-letsencrypt.sh` and change the email address:

```bash
email="your-email@example.com"  # CHANGE THIS to your actual email
```

### 3. Make the init script executable

```bash
chmod +x init-letsencrypt.sh
```

### 4. Run the initialization script

```bash
./init-letsencrypt.sh
```

This script will:
- Create necessary directories for certbot
- Request SSL certificates from Let's Encrypt
- Start nginx and certbot containers

### 5. Verify deployment

Visit your site at:
- https://uhalkinavera.ru
- https://www.uhalkinavera.ru

## How It Works

### Domain Rewriting

The nginx configuration uses `sub_filter` to replace all occurrences of Wix domains in the response:

| Original Domain | Replaced With |
|----------------|---------------|
| dzaytseva4.wixsite.com | uhalkinavera.ru |
| static.wixstatic.com | static.uhalkinavera.ru |
| video.wixstatic.com | video.uhalkinavera.ru |

This ensures all resources (images, videos, scripts, CSS) load from your custom domain.

### SSL Certificates

- **Initial generation**: Handled by `init-letsencrypt.sh`
- **Auto-renewal**: certbot container checks every 12 hours and renews if certificates expire in less than 30 days
- **SAN certificate**: Single certificate covers all subdomains

### HTTP to HTTPS

All HTTP traffic on port 80 is automatically redirected to HTTPS port 443, except for Let's Encrypt challenge requests (`.well-known/acme-challenge/`).

## Management Commands

### View logs
```bash
# All services
docker-compose logs -f

# Nginx only
docker-compose logs -f nginx

# Certbot only
docker-compose logs -f certbot
```

### Restart services
```bash
docker-compose restart
```

### Stop services
```bash
docker-compose down
```

### Start services
```bash
docker-compose up -d
```

### Force certificate renewal
```bash
docker-compose run --rm certbot renew --force-renewal
docker-compose restart nginx
```

### View certificate expiration
```bash
docker-compose run --rm certbot certificates
```

## Troubleshooting

### Certificate generation fails

1. Verify DNS records are correctly pointing to your server:
   ```bash
   nslookup uhalkinavera.ru
   ```

2. Ensure ports 80 and 443 are accessible:
   ```bash
   curl -I http://your-server-ip
   ```

3. Check certbot logs:
   ```bash
   docker-compose logs certbot
   ```

### Site not loading

1. Check nginx logs for errors:
   ```bash
   docker-compose logs nginx
   ```

2. Verify nginx configuration syntax:
   ```bash
   docker-compose exec nginx nginx -t
   ```

3. Ensure all containers are running:
   ```bash
   docker-compose ps
   ```

### Mixed content warnings

If you see mixed content warnings in the browser console, it means some resources are still loading over HTTP. Check the nginx logs and verify that `sub_filter` is working correctly.

## Configuration Customization

### Change upstream Wix site

Edit `nginx.conf` and modify the `proxy_pass` directive:

```nginx
proxy_pass https://your-site.wixsite.com/your-page/;
proxy_set_header Host your-site.wixsite.com;
```

Also update the `sub_filter` directives:

```nginx
sub_filter 'your-site.wixsite.com' 'uhalkinavera.ru';
```

After making changes:
```bash
docker-compose restart nginx
```

### Add additional subdomains

1. Add DNS A record for the new subdomain
2. Add subdomain to `init-letsencrypt.sh` domains array
3. Add new server block in `nginx.conf`
4. Re-run the init script or manually add domain to certificate

## File Structure

```
uhalkinavera.ru/
├── docker-compose.yml      # Docker services configuration
├── nginx.conf              # Nginx reverse proxy configuration
├── init-letsencrypt.sh     # Certificate initialization script
├── CLAUDE.md               # Technical documentation
├── README.md               # This file
└── certbot/                # Created by init script
    ├── conf/               # Let's Encrypt certificates
    └── www/                # ACME challenge files
```

## Security Notes

- Certificates are automatically renewed before expiration
- All HTTP traffic is redirected to HTTPS
- nginx runs in read-only mode for configuration files
- Minimal attack surface with alpine-based images

## License

This is a private project for uhalkinavera.ru domain.

## Support

For issues or questions, refer to:
- nginx documentation: https://nginx.org/en/docs/
- Let's Encrypt documentation: https://letsencrypt.org/docs/
- Docker Compose documentation: https://docs.docker.com/compose/
