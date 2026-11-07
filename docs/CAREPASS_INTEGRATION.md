# 照護通遠端服務整合

Flutter App 與照護通網站分屬兩個 repository，兩邊開發分支皆為 `feature/caregiver`：

```text
TownPass/                      # Flutter App、入口、路由、原生 bridge
townpass2026-starter/carepass/  # 照護通網頁、規則、資料、Vercel 設定
```

TownPass 不包含照護通 HTML 或資料快照，也不需 Node.js。App 透過 WebView 載入獨立部署的 HTTPS 網址；`local://carepass` 僅是 App 內部路由識別碼，不代表載入本機網頁。

## 設定與啟動

App 預設開啟 `https://townpass2026-starter.vercel.app/#home`。於本 repository 根目錄執行：

```bash
flutter pub get
dart run build_runner build
flutter run
```

發佈建置也會使用同一個正式網址：

```bash
flutter build apk
flutter build ipa
```

依 `.fvmrc` 選用 Flutter；使用 FVM 時在 Flutter／Dart 指令前加上 `fvm`。

如需切換測試服務，可用 `flutter run --dart-define=CAREPASS_URL=https://your-project.vercel.app/#home` 覆寫；APK／IPA 建置同樣支援此參數。`CAREPASS_URL` 是編譯時設定，不是 Vercel 環境變數。未傳入時使用上述正式網址；若明確傳入空值、非 HTTPS 或夾帶帳密的網址，App 顯示服務尚未設定。載入發生主頁網路或 HTTP 錯誤時，顯示提示與「重新載入」。

開啟 App 後，從「服務 ＞ 熱門 ＞ 照護通」，或「服務 ＞ 更多 ＞ 防疫醫療」進入。網站在同一網址更新後，不需重新建置 App；更換網址才需更新 `CAREPASS_URL` 並重新建置。

## 原生 bridge 與保存

- 網頁透過 `window.flutterObject` 呼叫既有 `phone_call` 與 `open_link`，訊息格式維持 `{ name, data }`。
- 網站的問卷、分流、名錄及 localStorage 保存邏輯均由網站 repository 維護。
- 清單依網站 origin 保存在裝置的 WebView；內建版本、Preview 網域與正式網域之間不會自動移轉。
- App 不提供離線封裝備援，載入網站需要網路。

## 驗證

```bash
flutter test test/carepass_service_test.dart --no-pub
flutter analyze --no-pub lib/page/carepass/carepass_view.dart lib/page/city_service/model/my_service_model.dart lib/page/city_service/model/trending_service_model.dart lib/util/tp_route.dart lib/util/tp_web_view.dart test/carepass_service_test.dart integration_test/carepass_test.dart
flutter test integration_test/carepass_test.dart -d <測試裝置ID> --dart-define=CAREPASS_URL=https://your-project.vercel.app/ --no-pub
```

整合測試會清除該測試裝置、該 origin 的既有 CarePass 清單，請使用測試裝置與測試服務。驗證服務入口、首次申請引導、保存與關閉後重開；真實撥號與 Android／iOS 平台持續保存須另以目標裝置確認。
