#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

source ./vscode-utils.sh

cleanup_dev_containers

USE_ISOLATED_ENV="false"
if [[ "$1" == "clean" ]]; then
    USE_ISOLATED_ENV="true"
fi

open_in_devcontainer "$(pwd)" "$USE_ISOLATED_ENV"
