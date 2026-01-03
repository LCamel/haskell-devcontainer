# haskell-devcontainer

This is a ready-to-use environment with GHC + Stackage + HLS.


## Common Usage Patterns

### Simple: GitHub Codespaces + prebuilt image

Suitable for teaching and testing. Works with just a browser. No Docker knowledge required.

Please refer to [HaskellSpace](https://github.com/LCamel/HaskellSpace).

### Advanced: VS Code + prebuilt image

Can serve as the foundation for a project development environment. New team members can quickly get a consistent development environment.

Develop and test in an isolated environment without worrying about conflicts between internal and external dependencies. Even if AI makes a mistake, it won't delete your entire hard drive.

Please refer to [here](./examples/prebuilt-image/).

### Advanced: VS Code + local-built image

Prefer to build your own image? Just review a few simple files and you can build it yourself.

Please refer to [here](./examples/local-built-image/).


## Supported Platforms

`amd64` and `arm64`.


## Tags

- `latest`: Latest recommended version
- `ghc-m.n`: Latest version using a specific GHC, e.g. `ghc-9.10`
- `stackage-lts-n`: Latest version using a specific Stackage snapshot, e.g. `stackage-lts-24`
- `GHC__STACKAGE__HLS__TIMESTAMP`: Fixed version, e.g. `9.10.2__lts-24.11__2.11.0.0__20251229-1435`

For a detailed list, see [here](https://github.com/LCamel/haskell-devcontainer/pkgs/container/haskell-devcontainer).
