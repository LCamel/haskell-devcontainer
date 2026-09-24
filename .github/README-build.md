# GitHub Automation

This directory contains the automation scripts and workflows for the `haskell-devcontainer` project.

## Maintenance

- When updating the GHC or Stackage versions, update `docker/haskell-versions.env`.
- Run `tag-version.sh` on your machine, and push it to the GitHub.
- The CI/CD will pick up these changes automatically and publish to GHCR.
- Once the release has finished, run the `Mirror to Docker Hub` workflow to bring Docker Hub
  up to date. This step is manual - skipping it leaves Docker Hub on the previous release.

## Workflows

- `build-and-push.yml`: The primary CI/CD pipeline.
    - Validates the git ref.
    - Builds multi-architecture images (`amd64` and `arm64`) using Docker Buildx.
    - Pushes a temporary image for smoke testing.
    - Runs smoke tests on both architectures.
    - Promotes the image to the main package if it's a tagged release (e.g. `9.10.2__lts-24.11__2.11.0.0__20251229-1435`).
    - Updates floating tags (e.g., `latest`, `ghc-9.10.2`, `stackage-lts-24.11`).
- `mirror-to-dockerhub.yml`: Manually (`workflow_dispatch`) copies released images from GHCR to Docker Hub.
- `cleanup-packages.yml`: Scheduled task to clean up old versions of the temporary image.

## Registries

GHCR (`ghcr.io/lcamel/haskell-devcontainer`) is the primary registry and the source of truth:
all builds, the temporary test image and the floating-tag calculation live there. The release
pipeline only ever writes to GHCR.

Docker Hub (`docker.io/lcamel/haskell-devcontainer`) is a mirror of released images, filled by
running `mirror-to-dockerhub.yml` by hand. Branch builds and the temporary test image never reach
it. Because the step is manual, Docker Hub can lag behind GHCR until the workflow is run.

### Credentials

`mirror-to-dockerhub.yml` needs both repository secrets:

| Secret | Value |
| --- | --- |
| `DOCKERHUB_USERNAME` | Your Docker Hub account name, e.g. `lcamel` |
| `DOCKERHUB_TOKEN` | A Docker Hub [access token](https://app.docker.com/settings/personal-access-tokens) with `Read & Write` scope (not your password) |

Add them under *Settings → Secrets and variables → Actions → New repository secret*
(repository secrets, not environment secrets - the workflow declares no environment).

The target repository name is the `DOCKERHUB_IMAGE_NAME` variable at the top of
`mirror-to-dockerhub.yml`. Pushing to a repository that does not exist yet creates it
automatically, using the account's *Default repository privacy* setting - so create it
explicitly, or check that setting, if it has to be public.

A fork without those secrets is unaffected: `build-and-push.yml` never touches Docker Hub, and
this workflow is only ever started by hand.

### Running the mirror

*Actions -> Mirror to Docker Hub -> Run workflow*, then pick a scope:

| Scope | What gets copied |
| --- | --- |
| `current-releases` (default) | The newest build of every GHC line, plus all of their tags |
| `latest-release` | Whatever `latest` points at, plus every tag on that same image |
| `all-tags` | Every tag in the GHCR repository |
| `custom` | The space separated tags given in the `tags` input |

Tags are selected by digest, not by name, so a scope always copies whole images together with
every tag pointing at them - Docker Hub never ends up with `latest` and its fixed tag disagreeing.
Tick `dry_run` to see the list without copying anything.

`current-releases` is the default because it makes Docker Hub match the set of images GHCR is
currently serving. Re-running it is cheap: blobs already present at the destination are skipped,
so the GHC lines that did not change cost little more than a manifest push.

The copy uses `crane copy`, which preserves the manifest digest: a mirrored image has the same
digest on both registries.

Sizes, as a rough guide for how long a run takes: each image is about 2.4 GB across both
architectures (~1.15 GB amd64, ~1.22 GB arm64), and there are currently four GHC lines.

## Scripts

- `tag-version.sh`: Generates a timestamped version tag for releases on your local machine (e.g. `9.10.2__lts-24.11__2.11.0.0__20251229-1435`). Push it to trigger the build workflow.
- `validate-ref.sh`: Ensures that only appropriate branches and tags trigger the full build/promote process.
- `smoke-test.sh`: Internal script executed within the container to verify GHC and other tools are working correctly.
- `calculate-floating-tags.sh`: Determines which floating tags need updating based on the current target tag.
- `select-mirror-tags.sh`: Resolves a mirror scope (`latest-release`, `current-releases`, `all-tags`, `custom`) into the list of tags to copy to Docker Hub. Used by `mirror-to-dockerhub.yml`; runs locally too, with `CRANE` overridable if you have `crane` installed natively.

