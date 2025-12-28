#!/bin/bash
cd "$(dirname "${BASH_SOURCE[0]}")" || exit 1

TEMP_DIR=$(mktemp -d)
mkdir -p "$TEMP_DIR/p"
cp -R .devcontainer "$TEMP_DIR/p/.devcontainer"
cp -R .vscode "$TEMP_DIR/p/.vscode"
code --user-data-dir "$TEMP_DIR/u" --extensions-dir "$TEMP_DIR/e" "$TEMP_DIR/p"

