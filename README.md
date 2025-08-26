# Ryoken App (Flutter)

一個可擴充的 Flutter App 專案，提供黑金主題風格、完整的登入/註冊/OAuth 流程、REST API 封裝（自動附帶 Bearer Token）、安全儲存 Token、以及可切換環境的設定機制。

---

## 📂 專案結構

```
ryoken_app/
├─ lib/
│  ├─ core/
│  │  ├─ config/env.dart                # 顏色與環境設定（local/prod 切換、BASE_URL）
│  │  ├─ network/api_service.dart       # REST API 封裝（自動帶 Bearer Token）
│  │  └─ storage/token_storage.dart     # Token 安全儲存（flutter_secure_storage）
│  ├─ features/
│  │  ├─ auth/
│  │  │  ├─ login_page.dart             # 登入頁（黑底金字、顯示密碼、記住我 UI）
│  │  │  └─ register_page.dart          # 註冊頁
│  │  ├─ home/home_page.dart            # 主頁（預留三個 Tab：首頁/市場/設定）
│  │  └─ oauth/oauth_webview_page.dart  # OAuth WebView（攔截 success?token=...）
│  └─ main.dart                         # Provider 佈線、Theme（黑金）、RootGate
├─ assets/
│  ├─ images/logo.jpg                   # Logo（若讀取失敗會顯示 Lottie 動畫）
│  └─ lottie/loading.json               # 讀取失敗時的 Lottie fallback
├─ pubspec.yaml
└─ README.md
```

---

## 🎨 主題色系

- **金色**：`#BE942A` (`0xFFBE942A`)
- **黑色**：`#0C0C0C` (`0xFF0C0C0C`)

在 `lib/core/config/env.dart` 的 `AppColors` 已統一定義，整體 `ThemeData` 也套用黑金風格（輸入框、按鈕、Checkbox 等）。

---

## ⚙️ 環境與 API 設定

環境與 API URL 由 **dart-define** 注入，程式會自動切換。

### 參數
- `ENV`：`local` 或 `prod`
- `BASE_URL`：API 根網址（例如 `http://localhost:8080` 或 `https://api.ryoken.ai`）

### 啟動方式
```bash
# 第一次解壓 zip 後需先產生平台檔
flutter create .
# 抓檔案
flutter pub get
# 本機啟動
flutter run -d emulator-5554

# 本機環境
flutter run -d emulator-5554   --dart-define=ENV=local   --dart-define=BASE_URL=http://localhost:8080

# 正式環境
flutter run -d emulator-5554   --dart-define=ENV=prod   --dart-define=BASE_URL=https://api.ryoken.ai
```

---

## 🔑 Token 儲存

- 使用 `flutter_secure_storage` 安全儲存 Token。
- App 啟動時會讀取 Token，決定是否直接進入主頁。
- 登入成功或 OAuth 完成後，會自動存入 Token。

---

## 📡 API 封裝

所有 API 都在 `ApiService` 中封裝，呼叫時會自動加上 `Authorization: Bearer <token>`。

### 已對應端點
#### Auth & User
- `register()`
- `login()`
- `profile()`
- `updateProfile()`

#### Notification
- `updateNotificationSetting()`
- `getNotificationSetting(email)`

#### Subscription
- `getPlans()`
- `getSubStatus()`
- `applyPlan(planId)`
- `cancelPlan()`

#### Admin
- `adminUsers()`
- `adminUserDetail(email)`
- `adminCreatePlan(dto)`
- `adminBroadcastPlan(dto)`

---

## 🔐 OAuth 流程（Google / LINE）

### 預設 URL
- Google: `{BASE_URL}/oauth2/authorization/google`
- LINE: `{BASE_URL}/oauth2/authorization/line`

### 流程
1. App 開啟 OAuth WebView 頁面
2. 使用者登入授權
3. 後端導回 `.../oauth2/success?token=...`
4. App 攔截成功路徑，取出 Token → 儲存 → 返回登入頁並進入主頁

> **注意**  
> - 預設攔截路徑：`/oauth2/success`  
> - 如果後端回傳格式不同，請在 `oauth_webview_page.dart` 中修改擷取邏輯

---

## 🖥️ UI 功能對齊

### 登入頁
- Logo（讀取失敗顯示 Lottie 動畫）
- Email / 密碼欄位（支援顯示密碼）
- 「記住我」UI
- 登入按鈕
- 註冊連結
- Google / LINE 登入按鈕（黑底金字，金色描邊）

### 註冊頁
- 名稱 / Email / 密碼
- 呼叫 `POST /api/auth/register`

### 主頁
- 三個 Tab 預留（首頁 / 市場 / 設定）
- 載入後自動呼叫 `/api/user/profile`

---

## 📌 開發注意事項

1. **OAuth 成功回跳 URL**  
   - 預設是 `…/oauth2/success?token=...`  
   - 若後端不同，請修改 `OAuthWebViewPage`

2. **登入回傳格式**  
   - 預設後端回傳純 Token 字串  
   - 若回 JSON `{ "token": "..." }`，需解析後再存入 TokenStorage

3. **正式機網址**  
   - 使用 `--dart-define=BASE_URL=...` 注入即可，不需修改程式碼

4. **平台檔案**  
   - Zip 包內未附 Android/iOS 平台檔，需自行在專案根目錄執行一次：
     ```bash
     flutter create .
     ```

---

## 🚀 後續擴充

- 加入方案清單頁（呼叫 `/api/sub/plans`）
- 加入通知設定頁（呼叫 `/api/notification/*`）
- 加入 Admin 後台頁（呼叫 `/api/admin/*`）

由於 API 已封裝好，只需在頁面中呼叫：
```dart
final api = context.read<ApiService>();
final plans = await api.getPlans();
```

即可完成串接。

---
