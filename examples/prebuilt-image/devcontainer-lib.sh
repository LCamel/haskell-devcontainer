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

# --- Docker Management ---

# Cleanup existing Dev Containers for a given project path
# Usage: cleanup_dev_containers [project_path]
cleanup_dev_containers() {
    local target_path="${1:-$(pwd)}"
    check_docker_command

    echo "Cleaning up existing Dev Containers for: $target_path" >&2
    
    # VS Code labels containers with 'devcontainer.local_folder'
    # This matches the folder that was "opened" (the one hex-encoded in the URI)
    local container_ids
    container_ids=$(docker ps -aq --filter "label=devcontainer.local_folder=$target_path")

    if [ -n "$container_ids" ]; then
        echo "Found existing containers, removing: $container_ids" >&2
        docker rm -f $container_ids > /dev/null
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
# Usage: get_devcontainer_uri [project_path] [explicit_remote_path]
get_devcontainer_uri() {
    local project_path="$1"
    local explicit_remote_path="$2"


    local hex_host_path
    hex_host_path=$(calculate_hex_path "$project_path")

    local remote_path
    if [ -n "$explicit_remote_path" ]; then
        remote_path="$explicit_remote_path"
    else
        # Check if git is available and we are inside a git repository
        local git_root
        if command -v git &> /dev/null && git_root=$(cd "$project_path" && git rev-parse --show-toplevel 2>/dev/null); then
            local repo_name
            repo_name=$(basename "$git_root")
            
            # Calculate absolute project path to ensure correct substitution
            local abs_project_path
            abs_project_path=$(cd "$project_path" && pwd)
            
            # Get relative path by removing git_root from abs_project_path
            local rel_path="${abs_project_path#$git_root}"
            # Remove leading slash from rel_path if present
            rel_path="${rel_path#/}"

            if [ -n "$rel_path" ]; then
                remote_path="/workspaces/${repo_name}/${rel_path}"
            else
                remote_path="/workspaces/${repo_name}"
            fi
        else
            # Fallback: Use the base name of the project_path
            local base_name
            base_name=$(basename "$project_path")
            remote_path="/workspaces/${base_name}"
        fi
    fi

    echo "vscode-remote://dev-container+${hex_host_path}${remote_path}"
}

# --- Launch ---

# Launch VS Code in a Dev Container
# Usage: open_in_devcontainer [project_path] [use_isolated_env: true|false] [install_ext: true|false] [explicit_remote_path]
#
# install_ext:
#   Whether to ensure the Dev Containers extension is installed before launching. (Default: true)
#
# explicit_remote_path:
#   Optional. If provided, this exact path will be used as the path inside the container.
#   If omitted, it is automatically calculated as: /workspaces/<repo_name>/<relative_path>
open_in_devcontainer() {
    local project_path="${1:-$(pwd)}"
    local use_isolated_env="${2:-false}"
    local install_ext="${3:-true}"
    local explicit_remote_path="$4"
    
    check_code_command

    local uri
    uri=$(get_devcontainer_uri "$project_path" "$explicit_remote_path")
    
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
