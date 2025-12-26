#!/bin/bash
set -e

# Load versions
if [ ! -f haskell-versions.env ]; then
    echo "Error: haskell-versions.env not found."
    exit 1
fi

. haskell-versions.env

# Construct tag with UTC timestamp
# Format: GHC_VERSION + "__" + STACKAGE_VERSION + "__" + HLS_VERSION + "__" + UTC_TIMESTAMP
TIMESTAMP=$(date -u +'%Y%m%d-%H%M')
TAG_NAME="${GHC_VERSION}__${STACKAGE_VERSION}__${HLS_VERSION}__${TIMESTAMP}"

echo "Target tag: ${TAG_NAME}"

# Check if tag already exists
if git rev-parse "$TAG_NAME" >/dev/null 2>&1; then
    echo "Tag '${TAG_NAME}' already exists."
    exit 0
fi

# Create tag
git tag "$TAG_NAME"
echo "Tag '${TAG_NAME}' created successfully."
echo "To push the tag, run: git push origin ${TAG_NAME}"
