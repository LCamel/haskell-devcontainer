FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04

RUN --mount=type=bind,source=install-os-packages.sh,target=/tmp/install-os-packages.sh \
    bash -x /tmp/install-os-packages.sh

USER vscode

RUN --mount=type=bind,source=install-ghcup-and-stack.sh,target=/tmp/install-ghcup-and-stack.sh \
    bash -x /tmp/install-ghcup-and-stack.sh

CMD ["bash"]