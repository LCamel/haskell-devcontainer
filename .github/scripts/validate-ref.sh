#!/bin/bash
set -e

# Usage: ./validate-ref.sh <ref_name> <ref_type>
# ref_type: "tag" or "branch"
# Exit code: 0 if valid, 1 if invalid

REF_NAME="$1"
REF_TYPE="$2"

if [ -z "$REF_NAME" ]; then
    echo "Error: REF_NAME argument is required." >&2
    echo "Usage: $0 <ref_name> <ref_type>" >&2
    exit 1
fi

if [ -z "$REF_TYPE" ]; then
    echo "Error: REF_TYPE argument is required." >&2
    echo "Usage: $0 <ref_name> <ref_type>" >&2
    exit 1
fi

echo "Validating ref_name: ${REF_NAME}"
echo "Ref type: ${REF_TYPE}"

if [ "$REF_TYPE" == "tag" ]; then
    # Tags must match the exact format: GHC__STACKAGE__HLS__TIMESTAMP
    # Example: 9.10.2__lts-24.11__2.11.0.0__20251227-0218
    # HLS version allows flexible depth (min 2 components), e.g., 2.11, 2.11.0, 2.11.0.0
    PATTERN='^[0-9]+\.[0-9]+\.[0-9]+__lts-[0-9]+\.[0-9]+__[0-9]+(\.[0-9]+)+__[0-9]{8}-[0-9]{4}$'

    if ! echo "${REF_NAME}" | grep -qE "$PATTERN"; then
        echo "❌ ERROR: Tag does not match required format" >&2
        echo "" >&2
        echo "Required format: GHC__STACKAGE__HLS__TIMESTAMP" >&2
        echo "  - GHC: X.Y.Z (e.g., 9.10.2)" >&2
        echo "  - STACKAGE: lts-X.Y (e.g., lts-24.11)" >&2
        echo "  - HLS: X.Y[.Z[.W]] (e.g., 2.11.0.0 or 2.11.0)" >&2
        echo "  - TIMESTAMP: YYYYMMDD-HHMM (e.g., 20251227-0218)" >&2
        echo "" >&2
        echo "Example: 9.10.2__lts-24.11__2.11.0.0__20251227-0218" >&2
        echo "Got: ${REF_NAME}" >&2
        exit 1
    fi

elif [ "$REF_TYPE" == "branch" ]; then
    # Branches must contain only: a-z, A-Z, 0-9, '.', '_', '-'
    if echo "${REF_NAME}" | grep -qE '[^a-zA-Z0-9._-]'; then
        echo "❌ ERROR: Branch name contains invalid characters" >&2
        echo "" >&2
        echo "Allowed characters: a-z, A-Z, 0-9, '.', '_', '-'" >&2
        echo "" >&2
        echo "Invalid characters found:" >&2
        echo "${REF_NAME}" | grep -oE '[^a-zA-Z0-9._-]' | sort -u >&2
        echo "" >&2
        echo "Branch name: ${REF_NAME}" >&2
        exit 1
    fi

else
    echo "❌ ERROR: Unknown ref_type: ${REF_TYPE}" >&2
    echo "Expected: 'tag' or 'branch'" >&2
    exit 1
fi

echo "✅ Validation passed"
exit 0
