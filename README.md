# Private Docker Registry Stack

A self-hosted Docker registry with Let's Encrypt TLS certificates, file server, and web UI for private networks.

## Architecture

| Service | Domain | Description |
|---------|--------|-------------|
| Registry | `registry.labs.dae.mn` | Docker registry (port 443 via nginx) |
| Files | `files.labs.dae.mn` | Static file server (port 443) |
| UI | `ui.labs.dae.mn` | Registry web UI (port 443) |

## Prerequisites

- Docker or Rancher Desktop
- Network with DNS configured to resolve `*.labs.dae.mn` to this host
- Let's Encrypt certificates automatically trusted by all clients

## Quick Start

### 1. Start the Stack

```bash
docker-compose up -d
```

### 2. Configure DNS

Configure your router's DNS to point to this machine's IP address for `*.labs.dae.mn` domains.

For each `*.labs.dae.mn` domain, add an A record pointing to the host IP:
- `registry.labs.dae.mn` → `<host-ip>`
- `files.labs.dae.mn` → `<host-ip>`
- `ui.labs.dae.mn` → `<host-ip>`

### 3. (Optional) Hosts File Alternative

If DNS configuration is not possible, add to `/etc/hosts` (macOS/Linux) or `C:\Windows\System32\drivers\etc\hosts` (Windows):
```
<workshop-server-ip> registry.labs.dae.mn files.labs.dae.mn ui.labs.dae.mn
```

## Usage

### Push an Image

```bash
docker tag myimage:latest registry.labs.dae.mn/myimage:latest
docker push registry.labs.dae.mn/myimage:latest
```

### Pull an Image

```bash
docker pull registry.labs.dae.mn/myimage:latest
```

### Access Registry UI

Open https://ui.labs.dae.mn in a browser (automatically trusted Let's Encrypt certificate).

### Access Static Files

Place files in the `www/` directory and access them at:
- http://files.labs.dae.mn
- https://files.labs.dae.mn

## Certificate Details

- **Certificate Type:** Let's Encrypt wildcard certificate
- **Domains:** `*.labs.dae.mn`, `labs.dae.mn`
- **Validity:** 90 days (auto-renewable)
- **Location:** `certs/labs/fullchain.pem` and `certs/labs/privkey.pem`

The certificates are automatically trusted by all modern browsers and Docker clients.

### Certificate Renewal

The Let's Encrypt certificates are valid for 90 days. To renew manually:

```bash
# Using certbot with DNS challenge
certbot certonly --dns-cloudflare -d "*.labs.dae.mn" --manual-public-ip-logging-ok

# Copy renewed certificates
cp /etc/letsencrypt/live/labs.dae.mn/fullchain.pem certs/labs/
cp /etc/letsencrypt/live/labs.dae.mn/privkey.pem certs/labs/

# Restart nginx
docker-compose restart proxy
```

## Troubleshooting

### Certificate errors
- Ensure CA certificate is installed in system trust store
- Restart Docker runtime after installing certificate
- For Rancher Desktop: Preferences → Certificate → Add CA certificate

### Can't access services
- Check Docker containers are running: `docker-compose ps`
- Check firewall allows ports 80, 443

## File Structure

```
.
├── docker-compose.yaml      # Main compose file
├── config.yml               # Registry configuration
├── nginx/
│   └── nginx.conf           # Reverse proxy config
├── certs/                   # TLS certificates
│   ├── labs.ca.pem          # CA cert for clients
│   └── ...
├── www/                     # Static files (place files here)
└── README.md
```
