# Local-built Image

Please read [prebuilt-image's README](../prebuilt-image) first.

If the prebuilt-image does not meet your needs:
- Read and execute [copy-and-edit-example.sh](copy-and-edit-example.sh). This script copies configuration files and scripts from `prebuilt-image/` and changes the image source in `devcontainer.json` to "build".
- Modify the contents of the [docker/](../../docker/) directory.
- Execute `start-clean.sh`. VS Code will now build the image locally.

If you need to push the image, please refer to the workflows and scripts for maintaining images in [.github/](../../.github/).
