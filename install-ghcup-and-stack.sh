#!/bin/bash
set -e

curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh

# Manually append to both .bashrc and .zshrc
echo '[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env' >> ~/.bashrc
echo '[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env' >> ~/.zshrc

. $HOME/.ghcup/env

# stackage snapshot lts-24.11 -> ghc 9.10.2
# https://raw.githubusercontent.com/commercialhaskell/stackage-snapshots/master/lts/24/11.yaml
# ghc 9.10.2 -> hls version 2.11.0.0
# https://raw.githubusercontent.com/haskell/ghcup-metadata/master/hls-metadata-0.0.1.json

time ghcup install ghc 9.10.2; ghcup set ghc 9.10.2
ghc --version

time ghcup install hls 2.11.0.0; ghcup set hls 2.11.0.0
haskell-language-server-wrapper --version

# newest stack is fine
time ghcup install stack
stack --version
# ~/.stack/config.yaml
stack config set system-ghc --global true
stack config set install-ghc --global false

# newest cabal is fine (stack uses its own cabal internally anyway)
time ghcup install cabal
cabal --version