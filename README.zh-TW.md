# haskell-devcontainer

這是一個隨開即用的 GHC + Stackage + HLS 的環境.


## 常見的使用方式

### 簡單: GitHub Codespaces + prebuilt image

適合教學與測試. 有 browser 就能使用. 不需要懂 Docker.

請參考 [HaskellSpace](https://github.com/LCamel/HaskellSpace).

### 進階: VS Code + prebuilt image

可作為專案的開發環境基礎. 團隊的新人也可以很快就有和大家一致的開發環境.

在單獨的環境裡開發測試, 不怕內外互相影響. 就算 AI 出錯也不會把整個硬碟刪掉.

請參考 [這裡](./examples/prebuilt-image/README.zh-TW.md).

### 進階: VS Code + local-built image

喜歡自己 build image? 只要 review 幾個簡單的檔案就可以自己 build.

請參考 [這裡](./examples/local-built-image/README.zh-TW.md).


## 支援的平台

`amd64` 與 `arm64`.


## Tags

- `latest`: 推薦使用的最新版本
- `ghc-m.n.p`: 使用特定 GHC 的最新版本, 如 `ghc-9.10.2`
- `stackage-lts-m.n`: 使用特定 Stackage snapshot 的最新版本, 如 `stackage-lts-24.11`
- `GHC__STACKAGE__HLS__TIMESTAMP`: 固定不動的版本, 如 `9.10.2__lts-24.11__2.11.0.0__20251229-1435`

詳細列表請看[這裡](https://github.com/LCamel/haskell-devcontainer/pkgs/container/haskell-devcontainer).

