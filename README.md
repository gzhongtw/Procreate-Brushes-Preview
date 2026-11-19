# Procreate Brushes Preview

預覽 Procreate `.brush` 與 `.brushset` 的 macOS App、Quick Look 延伸功能與 Eagle 外掛。

- macOS 12 以上；目前介面為繁體中文。
- macOS App：0.2.4，已正式簽署並通過 Apple 公證。
- Eagle 外掛：1.0.0，僅支援 macOS；尚待 Eagle 內建打包與安裝驗收。
- 顯示檔案內建筆觸，不提供試畫或格式轉換。

## 專案結構

- `outputs/Source`：Swift、共用介面與建置工具。
- `outputs/BrushPreview.eagleplugin-src`：最新 Eagle 外掛專案。
- `design`：核准的 Icon Composer 原檔。
- `docs/eagle-store`：上架文案、隱私與審核說明、圖片。

## 建置

需 Xcode、Icon Composer 與 Node.js。

```sh
npm ci
mkdir -p work
node outputs/Source/ui/build.mjs
python3 outputs/Source/build.py
python3 outputs/Source/package-macos.py
```

正式簽署參考 `outputs/Source/sign-and-notarize.sh`，需自行設定本機簽署憑證與公證 Keychain profile。測試請設定 `BRUSHSET_TEST_FILE`（7 支漫畫筆刷組）與 `BRUSH_TEST_FILE`（對應單支筆刷）環境變數；測試素材未隨專案散布。

支援：hello@zon.tw。此為第三方工具，非 Procreate 官方產品。
