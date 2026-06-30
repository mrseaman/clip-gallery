#!/usr/bin/env python
import BaseHTTPServer
import json
import os
import re
import time

UPLOAD_DIR = os.environ.get("GALLERY_UPLOAD_DIR", "/srv/image")
API_KEY_FILE = os.environ.get("GALLERY_API_KEY_FILE", os.path.expanduser("~/.gallery-api-key"))
PORT = int(os.environ.get("GALLERY_PORT", "8081"))

def load_api_key():
    with open(API_KEY_FILE) as f:
        return f.read().strip()

def sanitize_filename(name):
    name = os.path.basename(name)
    name = re.sub(r"[^\w\-.]", "_", name)
    if not name or name.startswith("."):
        name = "image"
    return name

def refresh_files_json():
    exts = (".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp", ".svg", ".avif", ".tif", ".tiff")
    files = sorted([f for f in os.listdir(UPLOAD_DIR) if f.lower().endswith(exts)])
    with open(os.path.join(UPLOAD_DIR, "files.json"), "w") as f:
        json.dump(files, f)

class Handler(BaseHTTPServer.BaseHTTPRequestHandler):
    def do_POST(self):
        api_key = load_api_key()
        if self.headers.get("X-API-Key") != api_key:
            self.send_response(401)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": "unauthorized"}))
            return

        content_length = int(self.headers.get("Content-Length", 0))
        if content_length == 0:
            self.send_response(400)
            self.send_header("Content-Type", "application/json")
            self.end_headers()
            self.wfile.write(json.dumps({"error": "no data"}))
            return

        filename = self.headers.get("X-Filename", "")
        filename = sanitize_filename(filename)

        if not filename or filename == "image":
            ct = self.headers.get("Content-Type", "")
            type_map = {
                "image/png": ".png", "image/gif": ".gif",
                "image/webp": ".webp", "image/jpeg": ".jpg",
                "image/svg+xml": ".svg", "image/bmp": ".bmp",
                "image/avif": ".avif", "image/tiff": ".tiff",
            }
            ext = type_map.get(ct, ".jpg")
            filename = time.strftime("%Y%m%d_%H%M%S") + ext

        base, ext = os.path.splitext(filename)
        path = os.path.join(UPLOAD_DIR, filename)
        counter = 1
        while os.path.exists(path):
            filename = "%s_%d%s" % (base, counter, ext)
            path = os.path.join(UPLOAD_DIR, filename)
            counter += 1

        body = self.rfile.read(content_length)
        with open(path, "wb") as f:
            f.write(body)
        os.chmod(path, 0o664)

        refresh_files_json()

        self.send_response(200)
        self.send_header("Content-Type", "application/json")
        self.end_headers()
        self.wfile.write(json.dumps({"ok": True, "filename": filename}))

    def do_OPTIONS(self):
        self.send_response(200)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.send_header("Access-Control-Allow-Methods", "POST, OPTIONS")
        self.send_header("Access-Control-Allow-Headers", "Content-Type, X-API-Key, X-Filename")
        self.end_headers()

    def log_message(self, format, *args):
        pass

if __name__ == "__main__":
    server = BaseHTTPServer.HTTPServer(("127.0.0.1", PORT), Handler)
    print "Clip Gallery API running on port %d" % PORT
    server.serve_forever()
