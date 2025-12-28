#!/bin/bash
set -e

# Usage: echo "$ALL_TAGS" | ./calculate-floating-tags.sh "$TARGET_TAG"
# Output: List of floating tags that should be updated to point to TARGET_TAG

TARGET_TAG="$1"

if [ -z "$TARGET_TAG" ]; then
    echo "Error: TARGET_TAG argument is required." >&2
    exit 1
fi

# Read all remote tags from stdin into a variable
REMOTE_TAGS=$(cat)

if [ -z "$REMOTE_TAGS" ]; then
    echo "Error: No remote tags provided on stdin." >&2
    exit 1
fi

# Parse version components from the Target Tag
# Format: GHC__STACKAGE__HLS__TIMESTAMP
# Example: 9.10.2__lts-24.11__2.11.0.0__20251227-0218

GHC_FULL=$(echo "$TARGET_TAG" | awk -F__ '{print $1}')      # 9.10.2
GHC_MM=$(echo "$GHC_FULL" | cut -d. -f1-2)                 # 9.10

STACKAGE_FULL=$(echo "$TARGET_TAG" | awk -F__ '{print $2}') # lts-24.11
STACKAGE_SERIES=$(echo "$STACKAGE_FULL" | cut -d. -f1)      # lts-24

# debug info to stderr
echo "Debug: Target='$TARGET_TAG'" >&2
echo "Debug: GHC_MM='$GHC_MM', STACKAGE_SERIES='$STACKAGE_SERIES'" >&2

# Helper function to filter and sort tags using the project's logic
# Format: GHC__STACKAGE__HLS__TIMESTAMP
# Sort keys: 1.GHC(V) 2.Stackage(V) 3.HLS(V) 4.Timestamp(txt)
filter_and_sort_tags() {
    grep -E '.+__.+__.+__.+' | \
    # Safe to use space as delimiter for sort because Docker tags cannot contain whitespace.
    sed 's/__/ /g' | \
    sort -k1V -k2V -k3V -k4 | \
    sed 's/ /__/g'
}

# Function to check if TARGET_TAG is the latest in a given scope
# Returns 0 (true) if it IS the latest, 1 (false) otherwise.
is_latest() {
    local pattern="$1"
    local relevant_tags
    
    if [ "$pattern" == ".*" ]; then
        relevant_tags="$REMOTE_TAGS"
    else
        relevant_tags=$(echo "$REMOTE_TAGS" | grep -E "$pattern" || true)
    fi

    # Defensive: append TARGET_TAG to handle cases where it's not yet visible in REMOTE_TAGS.
    # If it's already there, duplicate lines don't affect 'tail -n 1' results.
    local sorted_latest=$(echo -e "${relevant_tags}\n${TARGET_TAG}" | filter_and_sort_tags | tail -n 1)
    
    if [ "$TARGET_TAG" = "$sorted_latest" ]; then
        return 0
    else
        return 1
    fi
}

# 1. Check 'latest'
if is_latest ".*"; then
    echo "latest"
fi

# 2. Check GHC floating tag (ghc-X.Y)
if [ -n "$GHC_MM" ]; then
    # Regex: Start of line, then GHC_MM, then a dot. e.g. ^9\.10\.
    PATTERN="^${GHC_MM//./\.}\."
    if is_latest "$PATTERN"; then
        echo "ghc-${GHC_MM}"
    fi
fi

# 3. Check Stackage floating tag (stackage-lts-X)
if [ -n "$STACKAGE_SERIES" ]; then
    # Regex: Contains __STACKAGE_SERIES. e.g. __lts-24\.
    PATTERN="__${STACKAGE_SERIES//./\.}\."
    if is_latest "$PATTERN"; then
        echo "stackage-${STACKAGE_SERIES}"
    fi
fi
