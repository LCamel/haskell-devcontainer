#!/bin/bash

# VS Code Dev Container Utility Library
# This library provides functions to automate VS Code tasks, especially around Dev Containers.
#
# Reference for Source Mounts and Workspace Folder logic:
# https://code.visualstudio.com/remote/advancedcontainers/change-default-source-mount

# --- Environment Checks ---

# Check if VS Code 'code' command is available
# Exits the script if not found
check_code_command() {
    if ! command -v code &> /dev/null; then
        echo "Error: VS Code CLI 'code' is not installed or not in PATH." >&2
        echo "Tip: Choose ">Shell Command: Install 'code' command in PATH" from the VS Code Command Palette." >&2
        exit 1
    fi
}

# Check if 'docker' command is available
# Exits the script if not found
check_docker_command() {
    if ! command -v docker &> /dev/null; then
        echo "Error: 'docker' command not found." >&2
        exit 1
    fi
}

# --- Project Discovery ---

# Get the root directory of the git repository for a given path
# Usage: get_git_root_dir [path]
get_git_root_dir() {
    local project_dir="${1:-$(pwd -P)}"
    if command -v git &> /dev/null; then
        (cd "$project_dir" && git rev-parse --show-toplevel 2>/dev/null)
    fi
}

# Get the directory that should be mounted from the host
# If in a git repo, returns the git root. Otherwise, returns the project path.
# Usage: get_host_mount_dir [path]
get_host_mount_dir() {
    local project_dir="${1:-$(pwd -P)}"
    local git_root

    git_root=$(get_git_root_dir "$project_dir")

    if [ -n "$git_root" ]; then
        echo "$git_root"
    else
        echo "$project_dir"
    fi
}

# Calculate the remote path based on the project path and host mount directory
# Logic: /<basename(host_mount_dir)>/<relative_path>
# Example: project=/a/b/c/d/e, mount=/a/b/c -> /c/d/e
# Usage: get_remote_dir <project_dir>
get_remote_dir() {
    local project_dir="$1"

    # Ensure project_dir is absolute
    project_dir=$(cd "$project_dir" && pwd -P)

    local host_mount_dir
    host_mount_dir=$(get_host_mount_dir "$project_dir")

    # Get the folder name of the mount dir (e.g., 'c' from '/a/b/c')
    local mount_name
    mount_name=$(basename "$host_mount_dir")

    # Get relative path (e.g., '/d/e')
    # If project_dir == host_mount_dir, this will be empty
    local rel_path="${project_dir#$host_mount_dir}"

    echo "/${mount_name}${rel_path}"
}

# Ensure the project directory contains Dev Container settings
# Exits the script if not found
# Usage: check_project_dir_contains_devcontainer_settings [path]
check_project_dir_contains_devcontainer_settings() {
    local project_dir="${1:-$(pwd -P)}"
    if [ ! -f "$project_dir/.devcontainer/devcontainer.json" ] && [ ! -f "$project_dir/.devcontainer.json" ]; then
        echo "Error: No Dev Container configuration found in '$project_dir'." >&2
        echo "Expected '.devcontainer/devcontainer.json' or '.devcontainer.json'." >&2
        exit 1
    fi
}

# --- Docker Management ---

# Cleanup existing Dev Containers for a given project path
# Usage: cleanup_dev_containers [project_dir]
cleanup_dev_containers() {
    local input_dir="${1:-.}"
    check_docker_command

    # Resolve paths
    local phys_path
    phys_path=$(cd "$input_dir" && pwd -P)

    local log_path
    log_path=$(cd "$input_dir" && pwd -L)

    echo "Cleaning up existing Dev Containers for:" >&2
    echo "  Physical: $phys_path" >&2
    if [ "$phys_path" != "$log_path" ]; then
        echo "  Logical:  $log_path" >&2
    fi

    # Find containers for Physical Path
    local ids_phys
    ids_phys=$(docker ps -aq --filter "label=devcontainer.local_folder=$phys_path")

    # Find containers for Logical Path (if different)
    local ids_log=""
    if [ "$phys_path" != "$log_path" ]; then
        ids_log=$(docker ps -aq --filter "label=devcontainer.local_folder=$log_path")
    fi

    # Combine IDs, sort, and remove duplicates
    local all_ids
    all_ids=$(printf "%s\n%s" "$ids_phys" "$ids_log" | grep -v '^$' | sort -u)

    if [ -n "$all_ids" ]; then
        echo "Found existing containers, removing: $all_ids" >&2
        # Use xargs for safer handling if many IDs, though standard variable expansion usually works for docker rm
        echo "$all_ids" | xargs docker rm -f > /dev/null
    else
        echo "No existing containers found for this path." >&2
    fi
}
# --- URI Construction ---

# Hex encode a string (required for VS Code remote URIs)
# Usage: calculate_hex_path <string>
calculate_hex_path() {
    printf '%s' "$1" | od -An -v -tx1 | tr -d ' \n'
}

# Generate the Dev Container URI for a given path
# Usage: get_devcontainer_uri [project_dir] [explicit_remote_path]
get_devcontainer_uri() {
    local project_dir="${1:-$(pwd -P)}"
    local explicit_remote_path="$2"

    local hex_host_path
    hex_host_path=$(calculate_hex_path "$project_dir")

    local remote_path
    if [ -n "$explicit_remote_path" ]; then
        remote_path="$explicit_remote_path"
    else
        remote_path="/workspaces$(get_remote_dir "$project_dir")"
    fi

    echo "vscode-remote://dev-container+${hex_host_path}${remote_path}"
}

# --- Launch ---

# Launch VS Code in a Dev Container
# Usage: open_in_devcontainer [project_dir] [use_isolated_env: true|false] [install_ext: true|false] [explicit_remote_path]
#
# install_ext:
#   Whether to ensure the Dev Containers extension is installed before launching. (Default: true)
#
# explicit_remote_path:
#   Optional. If provided, this exact path will be used as the path inside the container.
#   If omitted, it is automatically calculated as: /workspaces/<repo_name>/<relative_path>
open_in_devcontainer() {
    local project_dir="${1:-$(pwd -P)}"
    local use_isolated_env="${2:-false}"
    local install_ext="${3:-true}"
    local explicit_remote_path="$4"

    check_code_command

    local uri
    uri=$(get_devcontainer_uri "$project_dir" "$explicit_remote_path")

    local env_args=()

    if [ "$use_isolated_env" = "true" ]; then
        # Create temporary VS Code user data and extensions directories
        local temp_root
        temp_root=$(mktemp -d)
        local user_data_dir="$temp_root/my-user-data-dir"
        local extensions_dir="$temp_root/my-extensions-dir"
        mkdir -p "$user_data_dir" "$extensions_dir"

        env_args=("--user-data-dir" "$user_data_dir" "--extensions-dir" "$extensions_dir")

        echo "Launching with temporary environment at: $temp_root" >&2
    fi

    # Ensure the extension is installed
    if [ "$install_ext" = "true" ]; then
        echo "Installing Dev Containers extension..." >&2
        code "${env_args[@]}" --install-extension ms-vscode-remote.remote-containers
    fi

    echo "Opening Dev Container: $uri" >&2
    code "${env_args[@]}" --folder-uri="$uri"
}
