# Setup Guide

## Prerequisites

- A Linux server with:
  - Nginx installed and running
  - Python 2.7
  - OpenSSL
  - sudo access
- An existing nginx site that will proxy requests to the gallery backend
- Google Chrome (for the browser extension)

## Server Setup

### 1. Clone the repository

```bash
git clone <repo-url>
cd personal-gallery
```

### 2. Configure environment (optional)

The defaults work for most setups. Override them by exporting before running the setup script:

```bash
export GALLERY_UPLOAD_DIR=/srv/image      # where images are stored
export GALLERY_API_KEY_FILE=~/.gallery-api-key  # API key file path
export GALLERY_PORT=8081                  # upload API listen port
```

### 3. Run the setup script

```bash
bash scripts/setup.sh
```

This will:
- Generate a random API key and save it to `~/.gallery-api-key`
- Create the upload directory with correct permissions
- Copy the gallery page into the upload directory
- Prompt you to create a username and password for the gallery web UI
- Install and start the upload API as a systemd service
- Install the nginx backend config and reload nginx

Take note of the API key printed at the end — you'll need it for the Chrome extension.

### 4. Configure your main nginx site

Add a location block in your main site's server config that proxies to the gallery backend. For example, if your site serves on HTTPS:

```nginx
server {
    listen 443 ssl;
    server_name your-domain.com;

    # ... your existing config ...

    location /image {
        client_max_body_size 50m;
        proxy_pass http://127.0.0.1:8080;
    }
}
```

Then test and reload:

```bash
sudo nginx -t && sudo nginx -s reload
```

### 5. Verify

Visit `https://your-domain.com/image/` in a browser. You should see a login prompt, then the gallery page.

## Chrome Extension Setup

### 1. Load the extension

1. Open `chrome://extensions/` in Chrome
2. Enable **Developer mode** (toggle in the top right)
3. Click **Load unpacked**
4. Select the `extension/` directory from this repository

### 2. Configure the extension

1. Click the puzzle piece icon in Chrome's toolbar
2. Find **Save to Gallery** and click the gear icon (or right-click → Options)
3. Enter your settings:
   - **Gallery API URL**: `https://your-domain.com/image/upload`
   - **API Key**: the key from the setup script output
4. Click **Save**

### 3. Usage

Right-click any image on the web and select **Save to Gallery**. A notification will confirm the save. The image appears in your gallery immediately on page refresh.

## Maintenance

### Adding images manually

Copy images into the upload directory, then refresh the file listing:

```bash
cp new-photo.jpg /srv/image/
bash scripts/refresh-gallery.sh
```

Images uploaded via the Chrome extension are indexed automatically.

### Viewing the API key

```bash
cat ~/.gallery-api-key
```

### Changing the gallery password

```bash
NEW_HASH=$(openssl passwd -apr1)
echo "username:$NEW_HASH" | sudo tee /etc/nginx/.htpasswd
```

### Restarting the upload API

```bash
sudo systemctl restart gallery-api
sudo systemctl status gallery-api
```

### Checking logs

```bash
sudo journalctl -u gallery-api -f
```

## SSL Certificate

The gallery is served over your site's existing HTTPS. If you need to set up or renew a certificate, [acme.sh](https://github.com/acmesh-official/acme.sh) works well:

```bash
# Install
curl https://get.acme.sh | sh

# Issue (add a .well-known location to your port 80 server block first)
~/.acme.sh/acme.sh --set-default-ca --server letsencrypt
~/.acme.sh/acme.sh --issue -d your-domain.com -w /usr/share/nginx/html

# Install cert
~/.acme.sh/acme.sh --install-cert -d your-domain.com \
  --key-file /path/to/your.key \
  --fullchain-file /path/to/your.pem \
  --reloadcmd 'sudo nginx -s reload'
```

To allow ACME HTTP challenges without HTTPS redirect issues, add this to your port 80 server block **before** the redirect:

```nginx
location /.well-known/acme-challenge/ {
    root /usr/share/nginx/html;
}
```
