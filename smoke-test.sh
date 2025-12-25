#!/bin/bash
set -e

if [ -f "haskell-versions.env" ]; then
    source haskell-versions.env
else
    echo "Error: haskell-versions.env not found in current directory."
    exit 1
fi

echo "Running smoke test with:"
echo "GHC_VERSION=${GHC_VERSION}"
echo "STACKAGE_VERSION=${STACKAGE_VERSION}"

echo "Checking GHC version..."
GHC_VERSION_OUTPUT=$(ghc --version)
if ! echo "$GHC_VERSION_OUTPUT" | grep -qE "\<${GHC_VERSION}\>"; then
    echo "Error: GHC version mismatch. Expected $GHC_VERSION, got: $GHC_VERSION_OUTPUT"
    exit 1
fi
echo "GHC version verified."


TEST_DIR="/tmp/test1"
echo "Setting up test directory: $TEST_DIR"
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"
echo "Creating new stack project..."
stack new foo --bare --resolver "${STACKAGE_VERSION}"
echo "Installing project..."
stack install
echo "Running foo-exe..."
OUTPUT=$(foo-exe)
if [[ "$OUTPUT" == *"someFunc"* ]]; then
    echo "foo-exe output verified: $OUTPUT"
else
    echo "Error: foo-exe returned unexpected output: $OUTPUT"
    exit 1
fi

echo "Checking HLS probe-tools..."
HLS_PROBE=$(haskell-language-server-wrapper --probe-tools)
echo "$HLS_PROBE"
MATCH_COUNT=$(echo "$HLS_PROBE" | grep -cE "ghc:[[:space:]]+\<${GHC_VERSION}\>")
echo "Found $MATCH_COUNT occurrences of 'ghc: $GHC_VERSION'"
if [ "$MATCH_COUNT" -ge 2 ]; then
    echo "HLS probe confirmed GHC version $GHC_VERSION in both PATH and Project context ($MATCH_COUNT matches)."
else
    echo "Error: HLS probe expected at least 2 occurrences of 'ghc: $GHC_VERSION' (found $MATCH_COUNT)."
    echo "This usually means HLS detected the system GHC but failed to detect the project GHC."
    exit 1
fi

echo "Smoke test passed successfully!"
