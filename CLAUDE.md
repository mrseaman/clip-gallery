# Personal Gallery

Self-hosted image gallery with a Chrome extension for saving images from the web.

## Architecture

- **Gallery page** (`gallery/index.html`): Static HTML served by nginx. Reads `files.json` for the image list, renders a responsive grid with lightbox. No build tools or dependencies.
- **Upload API** (`server/gallery-api.py`): Python 2 `BaseHTTPServer` that accepts image uploads via POST with API key auth. Saves to the upload directory and regenerates `files.json`. Configured via environment variables.
- **Nginx** (`nginx/image-gallery.conf`): Serves the gallery with HTTP basic auth and rate limiting (5 req/min). Proxies `/image/upload` to the API server without basic auth (uses API key instead). The main site is expected to reverse-proxy `/image` to this backend on port 8080.
- **Chrome extension** (`extension/`): Manifest V3. Adds "Save to Gallery" to the right-click context menu on images. Fetches the image blob and POSTs it to the configured API endpoint. API URL and key are set in extension options.
- **Scripts** (`scripts/`): `setup.sh` handles full deployment (htpasswd, systemd service, nginx config, API key generation). `refresh-gallery.sh` regenerates `files.json` from the upload directory.

## Environment variables

The API server reads these at startup:

- `GALLERY_UPLOAD_DIR` — where images are stored (default: `/srv/image`)
- `GALLERY_API_KEY_FILE` — path to file containing the API key (default: `~/.gallery-api-key`)
- `GALLERY_PORT` — port the API listens on (default: `8081`)

These are also set in `gallery-api.service` and used by the scripts.

## Deployment

1. Clone to the server
2. Run `bash scripts/setup.sh` — prompts for htpasswd credentials, generates API key, installs nginx config and systemd service
3. The main nginx site config needs a `location /image { proxy_pass http://127.0.0.1:8080; client_max_body_size 50m; }` block pointing to this backend
4. Load `extension/` as an unpacked Chrome extension and configure the API URL and key in options

## After adding images manually

Run `bash scripts/refresh-gallery.sh` to update `files.json`. Images uploaded via the extension/API are added automatically.

## Server requirements

- Nginx
- Python 2.7 (for the upload API and `refresh-gallery.sh`)
- OpenSSL (for generating htpasswd hashes)
