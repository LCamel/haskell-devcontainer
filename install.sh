#!/bin/bash

sudo apt-get update
sudo apt-get install -y build-essential curl libffi-dev libffi8 libgmp-dev libgmp10 libncurses-dev pkg-config

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh

echo '[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env' >> ~/.bashrc
echo '[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env' >> ~/.zshrc

. $HOME/.ghcup/env

time ghcup install ghc 9.12.2; ghcup set ghc 9.12.2
ghc --version

time ghcup install hls 2.10.0.0; ghcup set hls 2.10.0.0
haskell-language-server-wrapper --version

ghcup install stack
stack --version