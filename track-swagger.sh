#!/bin/bash

# === CONFIG ===
REPO_DIR="/home/richard/StaffologySwagger"
SWAGGER_URL="https://api.staffology.co.uk/swagger/v1/swagger.json"
SWAGGER_FILE="swagger.json"

# === SETUP ===
cd "$REPO_DIR" || exit 1
TMP_RAW=$(mktemp)             # raw download
TMP_NORMALIZED=$(mktemp)      # normalized new file
CURRENT_NORMALIZED=$(mktemp)  # normalized existing file

# === FETCH RAW SWAGGER FILE ===
curl -s "$SWAGGER_URL" -o "$TMP_RAW"

# === CHECK FOR EMPTY OR INVALID JSON ===
if [ ! -s "$TMP_RAW" ]; then
    echo "[ERROR] Downloaded Swagger file is empty. Aborting."
    rm -f "$TMP_RAW" "$TMP_NORMALIZED" "$CURRENT_NORMALIZED"
    exit 1
fi

if ! jq empty "$TMP_RAW" >/dev/null 2>&1; then
    echo "[ERROR] Downloaded Swagger file is not valid JSON. Aborting."
    rm -f "$TMP_RAW" "$TMP_NORMALIZED" "$CURRENT_NORMALIZED"
    exit 1
fi

# === NORMALIZE WITH JQ ===
jq -S . "$TMP_RAW" > "$TMP_NORMALIZED"
jq -S . "$SWAGGER_FILE" > "$CURRENT_NORMALIZED" 2>/dev/null || touch "$CURRENT_NORMALIZED"  # ignore error if file doesn't exist

# === CHECK FOR CHANGES ===
if ! diff -q "$CURRENT_NORMALIZED" "$TMP_NORMALIZED" >/dev/null; then
    echo "[INFO] Swagger file has changed. Preparing commit..."

    # Generate a summary diff
    DIFF_SUMMARY=$(diff --unified=0 "$CURRENT_NORMALIZED" "$TMP_NORMALIZED" | grep '^[-+]' | grep -vE '^[-+]{3}' | head -n 20)

    # Save the pretty, sorted new file as the committed version
    cp "$TMP_NORMALIZED" "$SWAGGER_FILE"

    # Commit message with summary
    COMMIT_MSG="Update Swagger file - $(date '+%Y-%m-%d %H:%M:%S')"

    if [ -n "$DIFF_SUMMARY" ]; then
        COMMIT_MSG+="

Changes:
$DIFF_SUMMARY"
    fi

    git add "$SWAGGER_FILE"
    git commit -m "$COMMIT_MSG"
    git push
else
    echo "[INFO] No changes detected."
fi

# === CLEANUP ===
rm -f "$TMP_RAW" "$TMP_NORMALIZED" "$CURRENT_NORMALIZED"
