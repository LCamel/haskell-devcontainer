# Prebuilt Image

Please install Docker and VS Code first.

Execute `clean-start.sh`. This will open a completely new environment independent of your current VS Code. It is ready to use immediately.

## Customization

For users who want to customize the environment, the current default choices are:
- Use new `--user-data-dir` and `--extensions-dir`.
  - Can also be changed to use the existing environment.
- Install the required Dev Containers extension for the host directly in this extensions dir.
  - Can also be changed to use existing extensions.
  - Or manually allow installation after being prompted by `.vscode/extensions.json`.
- Open the current directory.
  - Can also be changed to other directories.
- Open directly using `vscode-remote:` URI.
  - Can also open with a normal path, then manually "reopen in container".
  - Or install the [`devcontainer` cli](https://github.com/devcontainers/cli) to open.

In `.devcontainer/devcontainer.json`:
- Use the latest image: `ghcr.io/lcamel/haskell-devcontainer:latest`.
  - You can also refer to [other tags](https://github.com/LCamel/haskell-devcontainer) of this image.
  - Or use the scripts here with other devcontainers, such as
    - [This one](https://docs.haskellstack.org/en/stable/dev_containers/)
    - Or [this one](https://www.reddit.com/r/haskell/comments/1jfwcjg/haskelldevenv_an_opinionated_prebuilt_dev/)
- You can add extensions and settings you want to install inside the container.

If you have suggestions, feel free to open a PR, or fork directly to modify.