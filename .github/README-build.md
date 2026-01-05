# GitHub Automation

This directory contains the automation scripts and workflows for the `haskell-devcontainer` project.

## Maintenance

- When updating the GHC or Stackage versions, update `docker/haskell-versions.env`.
- Run `tag-version.sh` on your machine, and push it to the GitHub.
- The CI/CD will pick up these changes automatically.

## Workflows

- `build-and-push.yml`: The primary CI/CD pipeline.
    - Validates the git ref.
    - Builds multi-architecture images (`amd64` and `arm64`) using Docker Buildx.
    - Pushes a temporary image for smoke testing.
    - Runs smoke tests on both architectures.
    - Promotes the image to the main package if it's a tagged release (e.g. `9.10.2__lts-24.11__2.11.0.0__20251229-1435`).
    - Updates floating tags (e.g., `latest`, `ghc-9.10.2`, `stackage-lts-24.11`).
- `cleanup-packages.yml`: Scheduled task to clean up old versions of the temporary image.

## Scripts

- `tag-version.sh`: Generates a timestamped version tag for releases on your local machine (e.g. `9.10.2__lts-24.11__2.11.0.0__20251229-1435`). Push it to trigger the build workflow.
- `validate-ref.sh`: Ensures that only appropriate branches and tags trigger the full build/promote process.
- `smoke-test.sh`: Internal script executed within the container to verify GHC and other tools are working correctly.
- `calculate-floating-tags.sh`: Determines which floating tags need updating based on the current target tag.

