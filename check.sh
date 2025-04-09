#!/bin/bash

# === CONFIG ===
SWAGGER_URL="https://api.staffology.co.uk/swagger/v1/swagger.json"  # <-- replace with real URL
SWAGGER_FILE="swagger.json"                             # file path in repo

# === FETCH LATEST SWAGGER FILE ===
TMP_FILE=$(mktemp)
curl -s "$SWAGGER_URL" -o "$TMP_FILE"

# === CHECK FOR CHANGES ===
if ! diff -q "$TMP_FILE" "$SWAGGER_FILE" >/dev/null; then
    echo "[INFO] Swagger file has changed. Committing update..."

    mv "$TMP_FILE" "$SWAGGER_FILE"
    git add "$SWAGGER_FILE"
    git commit -m "Update Swagger file - $(date '+%Y-%m-%d %H:%M:%S')"
    git push
else
    echo "[INFO] No changes detected."
    rm "$TMP_FILE"
fi
