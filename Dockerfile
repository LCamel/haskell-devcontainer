FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN --mount=type=bind,source=install-os-packages.sh,target=/tmp/install-os-packages.sh \
    bash -x /tmp/install-os-packages.sh

USER vscode

RUN --mount=type=bind,source=install-haskell.sh,target=/tmp/install-haskell.sh \
    bash -x /tmp/install-haskell.sh

CMD ["bash"]
