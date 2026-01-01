#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

echo "This script helps you start a clean VSCode instance to test the devcontainer setup."

echo "Creating temporary VSCode user data and extensions dirs..."
TEMP_DIR=$(mktemp -d)
echo "Temporary directory created at: $TEMP_DIR"
echo

echo "Pre-installing the Dev Containers extension ... (to avoid the prompt)"
code --user-data-dir "$TEMP_DIR/u" --extensions-dir "$TEMP_DIR/e"  --install-extension ms-vscode-remote.remote-containers
echo

echo "Launching VSCode with clean user data and extensions dirs ..."
echo

#echo "Choose 'Reopen in Container' from the Command Palette to open the current folder in the devcontainer."
#echo
#code --user-data-dir "$TEMP_DIR/u" --extensions-dir "$TEMP_DIR/e" .

echo "Entering the devcontainer directly ..."
echo
code --user-data-dir "$TEMP_DIR/u" --extensions-dir "$TEMP_DIR/e" --folder-uri="vscode-remote://dev-container+$(pwd | tr -d '\n' | xxd -c 256 -p)/workspaces/haskell-devcontainer/examples/prebuilt-image" # path from the git root

