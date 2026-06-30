#!/bin/bash
UPLOAD_DIR="${GALLERY_UPLOAD_DIR:-/srv/image}"

cd "$UPLOAD_DIR"
ls -1 | python -c "
import sys, json
exts = ('.jpg','.jpeg','.png','.gif','.webp','.bmp','.svg','.avif','.tif','.tiff')
files = [f.strip() for f in sys.stdin if any(f.strip().lower().endswith(e) for e in exts)]
files.sort()
print json.dumps(files)
" > "$UPLOAD_DIR/files.json"

count=$(python -c "import sys,json;print len(json.load(sys.stdin))" < "$UPLOAD_DIR/files.json")
echo "Updated files.json with $count images"
