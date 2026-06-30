#!/bin/bash
set -e

UPLOAD_DIR="${GALLERY_UPLOAD_DIR:-/srv/image}"
API_KEY_FILE="${GALLERY_API_KEY_FILE:-$HOME/.gallery-api-key}"
SCRIPT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "=== Generating API key ==="
if [ -f "$API_KEY_FILE" ]; then
    echo "API key file already exists at $API_KEY_FILE"
else
    python -c "import os,hashlib; print hashlib.sha256(os.urandom(32)).hexdigest()[:32]" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    echo "API key saved to $API_KEY_FILE"
fi

echo ""
echo "=== Creating upload directory ==="
sudo mkdir -p "$UPLOAD_DIR"
sudo chown "$(whoami):nginx" "$UPLOAD_DIR"
sudo chmod 750 "$UPLOAD_DIR"

echo ""
echo "=== Installing gallery page ==="
sudo cp "$SCRIPT_DIR/gallery/index.html" "$UPLOAD_DIR/index.html"

echo ""
echo "=== Creating htpasswd ==="
if [ -f /etc/nginx/.htpasswd ]; then
    echo "htpasswd already exists"
else
    echo -n "Enter gallery username: "
    read -r USERNAME
    echo -n "Enter gallery password: "
    read -rs PASSWORD
    echo ""
    HASH=$(openssl passwd -apr1 "$PASSWORD")
    echo "${USERNAME}:${HASH}" | sudo tee /etc/nginx/.htpasswd > /dev/null
    sudo chmod 640 /etc/nginx/.htpasswd
    sudo chown root:nginx /etc/nginx/.htpasswd
fi

echo ""
echo "=== Installing API server ==="
cp "$SCRIPT_DIR/server/gallery-api.py" "$HOME/gallery-api.py"
SERVICE_FILE="$SCRIPT_DIR/server/gallery-api.service"
sed "s|YOUR_USER|$(whoami)|g; s|/home/YOUR_USER|$HOME|g" "$SERVICE_FILE" | sudo tee /etc/systemd/system/gallery-api.service > /dev/null
sudo systemctl daemon-reload
sudo systemctl enable gallery-api
sudo systemctl start gallery-api

echo ""
echo "=== Installing nginx config ==="
sudo cp "$SCRIPT_DIR/nginx/image-gallery.conf" /etc/nginx/conf.d/image-gallery.conf
sudo nginx -t
sudo nginx -s reload

echo ""
echo "=== Generating initial file listing ==="
bash "$SCRIPT_DIR/scripts/refresh-gallery.sh"

echo ""
echo "=== Done! ==="
echo "API key: $(cat "$API_KEY_FILE")"
echo "Upload dir: $UPLOAD_DIR"
echo "Set the API key in the Chrome extension options to start saving images."
