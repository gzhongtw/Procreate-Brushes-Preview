# Procreate Brushes Preview

在 Eagle 預覽 `.brush`、`.brushset` 的內建筆觸與筆刷名稱。

## 使用
安裝後開啟筆刷檔；點選筆觸可放大。既有素材可重新產生縮圖。

## 需求與限制
Eagle 4、macOS 12 以上；Apple Silicon／Intel。無須安裝 Procreate、登入或設定 API。僅顯示內建預覽，不支援試畫、ABR 轉換、加密 ZIP 或 ZIP64。

## 本機元件與資料
`bin/brush-preview` 是隨包附帶的 Universal Swift 輔助程式，讀取 ZIP／plist 與 PNG，輸出預覽資料及縮圖；不下載或安裝其他程式。不連網、不上傳、不修改原始筆刷。縮圖由 Eagle 寫入素材庫。未使用 shell 拼接指令；以 execFile 傳入固定命令與檔案路徑。
目前採 ad-hoc 簽章，尚未 Apple 公證。請使用 Eagle 內建打包並實際安裝驗證後送審。

## 聯絡
hello@zon.tw

本插件為第三方工具，非 Procreate 官方產品。
