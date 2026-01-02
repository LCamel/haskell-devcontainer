# Local-built Image

請先閱讀 [prebuilt-image 的 README](../prebuilt-image/README.zh-TW.md).

如果 prebuilt-image 不能滿足你的需求:
- 閱讀並執行 [copy-example.sh](copy-example.sh). 這個 script 會從 prebuilt-image/ 複製設定檔和 script 過來, 並把 devcontainer.json 中抓取 image 的地方改成 "build".
- 修改 [docker/](../../docker/) 目錄的內容.
- 執行 `clean-start.sh`

如果要 push image, 請參考 [.github/](../../.github/) 中維護 image 的 workflows 與 scripts.
