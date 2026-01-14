#!/bin/bash
set -e

# Load environment variables
if [ -f "haskell-versions.env" ]; then
    source haskell-versions.env
else
    echo "Error: haskell-versions.env not found in current directory."
    exit 1
fi

echo "Running smoke test with:"
echo "GHC_VERSION=${GHC_VERSION}"
echo "STACKAGE_VERSION=${STACKAGE_VERSION}"
echo ""

# Global test directory
TEST_DIR="/tmp/test1"

# Cleanup function
cleanup_test_directory() {
    echo "Cleaning up test directory: $TEST_DIR"
    rm -rf "$TEST_DIR"
}

# Test: Check GHC version
test_ghc_version() {
    echo "=== Checking GHC version ==="
    GHC_VERSION_OUTPUT=$(ghc --version)
    if ! echo "$GHC_VERSION_OUTPUT" | grep -qE "\<${GHC_VERSION}\>"; then
        echo "Error: GHC version mismatch. Expected $GHC_VERSION, got: $GHC_VERSION_OUTPUT"
        return 1
    fi
    echo "✓ GHC version verified: $GHC_VERSION"
    echo ""
}

# Test: Check stackage-version file
test_stackage_version_file() {
    echo "=== Checking ~/stackage-version file ==="
    STACKAGE_VERSION_FILE="$HOME/stackage-version"
    if [ ! -f "$STACKAGE_VERSION_FILE" ]; then
        echo "Error: $STACKAGE_VERSION_FILE not found."
        return 1
    fi
    STACKAGE_VERSION_CONTENT=$(cat "$STACKAGE_VERSION_FILE")
    if [ "$STACKAGE_VERSION_CONTENT" != "$STACKAGE_VERSION" ]; then
        echo "Error: stackage-version file content mismatch. Expected '$STACKAGE_VERSION', got: '$STACKAGE_VERSION_CONTENT'"
        return 1
    fi
    echo "✓ stackage-version file verified: $STACKAGE_VERSION_CONTENT"
    echo ""
}

# Test: Create and build Stack project
test_stack_project() {
    echo "=== Creating and building Stack project ==="
    echo "Setting up test directory: $TEST_DIR"
    mkdir -p "$TEST_DIR"
    cd "$TEST_DIR"

    echo "Creating new stack project..."
    stack new foo --bare --resolver "$(cat ~/stackage-version)"

    echo "Installing project..."
    stack install

    echo "Running foo-exe..."
    OUTPUT=$(foo-exe)
    if [[ "$OUTPUT" == *"someFunc"* ]]; then
        echo "✓ foo-exe output verified: $OUTPUT"
        echo ""
    else
        echo "Error: foo-exe returned unexpected output: $OUTPUT"
        return 1
    fi
}

# Test: Check HLS probe-tools
test_hls_probe_tools() {
    echo "=== Checking HLS probe-tools ==="
    cd "$TEST_DIR"

    HLS_PROBE=$(haskell-language-server-wrapper --probe-tools)
    echo "$HLS_PROBE"

    MATCH_COUNT=$(echo "$HLS_PROBE" | grep -cE "ghc:[[:space:]]+\<${GHC_VERSION}\>")
    echo "Found $MATCH_COUNT occurrences of 'ghc: $GHC_VERSION'"

    if [ "$MATCH_COUNT" -ge 2 ]; then
        echo "✓ HLS probe confirmed GHC version $GHC_VERSION in both PATH and Project context ($MATCH_COUNT matches)."
        echo ""
    else
        echo "Error: HLS probe expected at least 2 occurrences of 'ghc: $GHC_VERSION' (found $MATCH_COUNT)."
        echo "This usually means HLS detected the system GHC but failed to detect the project GHC."
        return 1
    fi
}

# Test: HLS LSP initialization
# This tests that HLS can:
# 1. Start as an LSP server
# 2. Accept and respond to initialize request
# 3. Handle initialized notification
# 4. Shutdown gracefully
test_hls_lsp_initialization() {
    echo "=== Testing HLS LSP initialization ==="

    # Use a subdirectory for LSP test to avoid interfering with stack project
    local LSP_TEST_DIR="$TEST_DIR/hls-lsp-test"
    rm -rf "$LSP_TEST_DIR"
    mkdir -p "$LSP_TEST_DIR"
    cd "$LSP_TEST_DIR"

    # Create a minimal Haskell project for LSP to work with
    cat > Main.hs <<'EOF'
module Main where

main :: IO ()
main = putStrLn "Hello, World!"
EOF

    cat > hie.yaml <<'EOF'
cradle:
  direct:
    arguments: []
EOF

    # Function to create LSP message with Content-Length header
    create_lsp_message() {
        local payload="$1"
        local length=${#payload}
        printf "Content-Length: %d\r\n\r\n%s" "$length" "$payload"
    }

    # Create input file with all LSP messages
    local INPUT_FILE="$LSP_TEST_DIR/lsp-input.txt"
    local OUTPUT_FILE="$LSP_TEST_DIR/lsp-output.txt"

    # Initialize request
    local INITIALIZE_REQUEST='{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"processId":null,"clientInfo":{"name":"smoke-test","version":"1.0.0"},"rootUri":"file://'"$LSP_TEST_DIR"'","capabilities":{"textDocument":{"hover":{"contentFormat":["plaintext"]}}},"initializationOptions":{}}}'

    # Initialized notification
    local INITIALIZED_NOTIFICATION='{"jsonrpc":"2.0","method":"initialized","params":{}}'

    # Shutdown request
    local SHUTDOWN_REQUEST='{"jsonrpc":"2.0","id":2,"method":"shutdown","params":null}'

    # Exit notification
    local EXIT_NOTIFICATION='{"jsonrpc":"2.0","method":"exit"}'

    echo ""
    echo "=== LSP Requests ==="
    echo ""
    echo "1. Initialize Request:"
    echo "$INITIALIZE_REQUEST" | jq '.'
    echo ""
    echo "2. Initialized Notification:"
    echo "$INITIALIZED_NOTIFICATION" | jq '.'
    echo ""
    echo "3. Shutdown Request:"
    echo "$SHUTDOWN_REQUEST" | jq '.'
    echo ""
    echo "4. Exit Notification:"
    echo "$EXIT_NOTIFICATION" | jq '.'
    echo ""

    # Write all messages to input file
    {
        create_lsp_message "$INITIALIZE_REQUEST"
        create_lsp_message "$INITIALIZED_NOTIFICATION"
        create_lsp_message "$SHUTDOWN_REQUEST"
        create_lsp_message "$EXIT_NOTIFICATION"
    } > "$INPUT_FILE"

    # Start HLS
    echo "Starting HLS..."
    timeout 30 haskell-language-server-wrapper --lsp < "$INPUT_FILE" > "$OUTPUT_FILE" 2>/tmp/hls-stderr.log || HLS_EXIT=$?

    # Check exit code (0 = success, 124 = timeout, other = error)
    if [ "${HLS_EXIT:-0}" -eq 124 ]; then
        echo "Error: HLS timed out"
        echo "HLS stderr output:"
        cat /tmp/hls-stderr.log
        return 1
    elif [ "${HLS_EXIT:-0}" -ne 0 ] && [ "${HLS_EXIT:-0}" -ne 1 ]; then
        echo "Error: HLS exited with code ${HLS_EXIT}"
        echo "HLS stderr output:"
        cat /tmp/hls-stderr.log
        return 1
    fi

    echo "✓ HLS completed"

    # Parse output for initialize response
    echo "Parsing LSP responses..."

    # Extract all JSON messages from output
    local EXTRACTED_JSON="$LSP_TEST_DIR/messages.json"
    grep -o '{.*}' "$OUTPUT_FILE" > "$EXTRACTED_JSON" || {
        echo "Error: No JSON messages found in output"
        echo "HLS stderr output:"
        cat /tmp/hls-stderr.log
        echo ""
        echo "HLS stdout output (first 500 chars):"
        head -c 500 "$OUTPUT_FILE"
        return 1
    }

    # Check for initialize response (id=1 with result.capabilities)
    local INIT_RESPONSE=$(grep -m 1 '"id":1' "$EXTRACTED_JSON" || echo "")

    if [ -z "$INIT_RESPONSE" ]; then
        echo "Error: No initialize response found (id=1)"
        echo "Extracted messages:"
        cat "$EXTRACTED_JSON"
        return 1
    fi

    # Validate capabilities using jq
    if ! echo "$INIT_RESPONSE" | jq -e '.result.capabilities' > /dev/null 2>&1; then
        echo "Error: Initialize response missing capabilities"
        echo "Response: $INIT_RESPONSE"
        return 1
    fi

    echo "✓ Initialize response validated - capabilities present"

    echo ""
    echo "=== LSP Responses ==="
    echo ""
    echo "1. Initialize Response:"
    echo "$INIT_RESPONSE" | jq '.'
    echo ""

    # Print some key capabilities
    local SAMPLE_CAPS=$(echo "$INIT_RESPONSE" | jq -r '.result.capabilities | keys | .[:10] | join(", ")')
    echo "Key capabilities (first 10): $SAMPLE_CAPS"
    echo ""

    # Check for shutdown response (id=2)
    local SHUTDOWN_RESPONSE=$(grep -m 1 '"id":2' "$EXTRACTED_JSON" || echo "")
    if [ -n "$SHUTDOWN_RESPONSE" ]; then
        echo "✓ Shutdown response received"
        echo ""
        echo "2. Shutdown Response:"
        echo "$SHUTDOWN_RESPONSE" | jq '.'
        echo ""
    else
        echo "Warning: No shutdown response found (id=2)"
    fi

    # Cleanup LSP test directory
    cd "$TEST_DIR"
    rm -rf "$LSP_TEST_DIR"

    echo "✓ HLS LSP initialization test passed!"
    echo ""
}

# Main test runner
main() {
    # Clean up test directory before starting
    cleanup_test_directory

    # Run all tests
    test_ghc_version
    test_stackage_version_file
    test_stack_project
    test_hls_probe_tools
    test_hls_lsp_initialization

    # Clean up test directory after all tests
    cleanup_test_directory

    echo "========================================"
    echo "✓ All smoke tests passed successfully!"
    echo "========================================"
}

# Run main
main
