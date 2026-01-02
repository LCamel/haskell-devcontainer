#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive

# This list can be obtained from `ghcup tool-requirements --raw-format`
apt-get update
apt-get install -y build-essential curl libffi-dev libffi8 libgmp-dev libgmp10 libncurses-dev pkg-config
apt-get clean
rm -rf /var/lib/apt/lists/*
