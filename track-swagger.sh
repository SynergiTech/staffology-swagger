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

# === NORMALIZE WITH JQ ===
jq -S . "$TMP_RAW" > "$TMP_NORMALIZED" || { echo "[ERROR] Failed to normalize new swagger.json"; exit 1; }
jq -S . "$SWAGGER_FILE" > "$CURRENT_NORMALIZED" || touch "$CURRENT_NORMALIZED"  # if no existing file, treat as empty

# === CHECK FOR CHANGES ===
if ! diff -q "$CURRENT_NORMALIZED" "$TMP_NORMALIZED" >/dev/null; then
    echo "[INFO] Swagger file has changed. Preparing commit..."

    # Generate a summary diff (you can tweak the grep/head filters)
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
