FROM mcr.microsoft.com/devcontainers/base:ubuntu-24.04
COPY install-os-packages.sh /tmp/
RUN bash -x /tmp/install-os-packages.sh && rm /tmp/install-os-packages.sh

USER vscode

COPY --chown=vscode:vscode install-ghcup-and-stack.sh /tmp/
RUN bash -x /tmp/install-ghcup-and-stack.sh && rm /tmp/install-ghcup-and-stack.sh

CMD ["bash"]