#!/bin/bash
set -e

# Load versions from external file
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
. "$SCRIPT_DIR/haskell-versions.env"


curl --proto '=https' --tlsv1.2 -sSf https://get-ghcup.haskell.org | BOOTSTRAP_HASKELL_NONINTERACTIVE=1 BOOTSTRAP_HASKELL_MINIMAL=1 sh

# Manually append to both .bashrc and .zshrc
echo '[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env' >> ~/.bashrc
echo '[ -f "$HOME/.ghcup/env" ] && . "$HOME/.ghcup/env" # ghcup-env' >> ~/.zshrc

. $HOME/.ghcup/env

time ghcup install ghc $GHC_VERSION; ghcup set ghc $GHC_VERSION
ghc --version

time ghcup install hls $HLS_VERSION; ghcup set hls $HLS_VERSION
haskell-language-server-wrapper --version

# newest stack is fine
time ghcup install stack $STACK_VERSION
stack --version
# ~/.stack/config.yaml
stack config set system-ghc --global true
stack config set install-ghc --global false

# newest cabal is fine (stack uses its own cabal internally anyway)
time ghcup install cabal $CABAL_VERSION
cabal --version
