#!/bin/bash
set -e
cd "$(dirname "${BASH_SOURCE[0]}")"

source ./devcontainer-lib.sh

cleanup_dev_containers

open_in_devcontainer "$(pwd)" "true"
