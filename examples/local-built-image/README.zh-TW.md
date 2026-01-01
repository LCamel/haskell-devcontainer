# Local-built image

如果 prebuilt-image 不能滿足你的需求:

1. 執行 copy-example.sh, 這個 script 會從 prebuilt-image/ 複製設定檔和 script 過來. 並把 devcontainer.json 中抓取 image 的地方改成 "build".
2. 檢視 docker/ 目錄的內容看有沒有想修改的地方.
3. 執行 clean-start.sh
