#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/../prebuilt-image"
DEST_DIR="."

echo "Copying files from prebuilt-image to local-built-image..."
tar -C "$SOURCE_DIR" --exclude='README*' -cf - . | tar -C "$DEST_DIR" -xf -

# Replace "image": ... line in devcontainer.json
DEVCONTAINER_JSON="$DEST_DIR/.devcontainer/devcontainer.json"

if [ -f "$DEVCONTAINER_JSON" ]; then
    echo "Updating devcontainer.json..."
    # Use sed to replace the "image": line with "build": configuration
    # macOS sed requires -i with backup extension, so we use .bak and then remove it
    sed -i.bak '/^  "image":/c\
  "build": {\
    "dockerfile": "../../../docker/Dockerfile",\
    "context": "../../../docker"\
  },' "$DEVCONTAINER_JSON"

    # Remove the initializeCommand line (for pulling prebuilt image) and its comment
    sed -i.bak '/if you want to always pull the latest image/,/initializeCommand.*docker pull/d' "$DEVCONTAINER_JSON"

    rm -f "$DEVCONTAINER_JSON.bak"
    echo "Done! Files copied and devcontainer.json updated."
else
    echo "Error: $DEVCONTAINER_JSON not found"
    exit 1
fi
