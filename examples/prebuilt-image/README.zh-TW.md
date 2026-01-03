# Prebuilt Image

請先安裝 Docker 和 VS Code.

執行 `clean-start.sh`, 這會開啟一個與目前 VS Code 獨立的全新環境. 馬上可以使用.

## Customization

對於想要 customize 環境的使用者, 目前 default 的選擇是:
- 用全新的 `--user-data-dir` 與 `--extensions-dir`
  - 也可改成沿用現有的環境
- 直接在此 extensions dir 中安裝 host 所需的 Dev Containers extension
  - 也可改成沿用現有的 extensions
  - 或由 `.vscode/extensions.json` 提示後手動允許安裝
- 開啟 current directory
  - 也可改成其他目錄
- 用 `vscode-remote:` 的 URI 直接開啟進入
  - 也可用一般 path 開啟, 再手動 "reopen in container"
  - 或安裝 [`devcontainer` cli](https://github.com/devcontainers/cli) 來開啟

在 `.devcontainer/devcontainer.json` 中:
- 使用 latest 的 image: `ghcr.io/lcamel/haskell-devcontainer:latest`
  - 也可以參考本 image 的 [其他 tags](https://github.com/LCamel/haskell-devcontainer)
  - 或用這邊的 script 搭配其他的 devcontainers, 如
    - [這個](https://docs.haskellstack.org/en/stable/dev_containers/)
    - 或 [這個](https://www.reddit.com/r/haskell/comments/1jfwcjg/haskelldevenv_an_opinionated_prebuilt_dev/)
- 可以在增加想要在 container 裡面安裝的 extension 和 settings

有建議可以開 PR, 或者直接 fork 來改.
