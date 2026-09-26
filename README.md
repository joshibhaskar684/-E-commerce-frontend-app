# 🛍️ Quick — Flutter E-commerce App

The Android app for **Quick** (quicksin.in). It uses **the same backend and the same APIs** as the
Next.js website (`frontend/website/E-commerece-frontend`), so a user can log in, browse, and use
the same cart on both.

This README covers everything needed to set it up and run it **on a real Android phone over USB**
(no emulator), including how each request travels from the phone to the backend on your PC.

---

## 📑 Contents

1. [Features](#-features)
2. [Tech stack](#-tech-stack)
3. [Project structure](#-project-structure)
4. [How a request travels: phone → USB → PC → backend](#-how-a-request-travels-phone--usb--pc--backend)
5. [One-time setup (tools)](#-one-time-setup-tools)
6. [One-time setup (phone)](#-one-time-setup-phone)
7. [Start the backend](#-start-the-backend)
8. [Run the app on the phone (step by step)](#-run-the-app-on-the-phone-step-by-step)
9. [Alternative: connect over Wi-Fi instead of USB](#-alternative-connect-over-wi-fi-instead-of-usb)
10. [Where to configure what](#-where-to-configure-what)
11. [API reference (same as the website)](#-api-reference-same-as-the-website)
12. [Build a release APK](#-build-a-release-apk)
13. [Troubleshooting](#-troubleshooting)
14. [Known backend gaps](#-known-backend-gaps)
15. [Command cheat-sheet](#-command-cheat-sheet)

---

## ✨ Features

| Area | What the app does | Backend call |
|---|---|---|
| **Home** | Brand header + search, auto-playing banners, category shortcuts, "Top in Electronics" / "Trending in Fashion" rows, infinite "Explore all products" grid, AI promo | `GET /products/page`, `GET /products/page/category/main` |
| **Categories** | Category tree with a left rail and sub-category chips; falls back to the website's featured categories if the tree is empty | `GET /products/category/tree` |
| **Search** | Live suggestions (400 ms debounce like the website), recent searches, popular searches | `GET /products/suggestions`, `GET /products/page/query/main` |
| **Product list** | 2-column grid, infinite scroll, pull-to-refresh, sort (price / discount), skeleton loaders | `/products/page*` |
| **Product details** | Swipeable image gallery with pinch-zoom, price & discount, stock, offers, delivery/returns, colour, seller, description, specifications, ratings, **Add to cart / Buy now** | `GET /products/{id}`, `POST /cart/item/add` |
| **Cart** | Quantity stepper, remove, clear cart, price details (subtotal, discount, delivery, GST 18%, total) | `GET /cart`, `PUT /cart/item`, `DELETE /cart/item/{id}`, `DELETE /cart/clear` |
| **Checkout** | Delivery address (saved on phone), order summary, pay online via Razorpay link | `POST /api/payments/{id}` |
| **Auth** | Login and sign up with the website's validation rules; JWT kept in encrypted storage; auto-logout when the token expires | `POST /auth/login`, `POST /auth/signup` |
| **Account** | Profile (name, email, mobile, role), orders, wishlist, theme (system/light/dark), **Server settings**, policies, logout | `GET /auth/profile` |
| **Wishlist** | Heart button on every product; saved on the phone | – (local) |
| **Ayira AI** | Streaming shopping-assistant chat (same AI endpoint as the website) | `POST https://ai.vhbuyio.in/api/chat` |
| **Look & feel** | Brand yellow `#FBBB02` + navy `#17283C` from the logo, Jost font (same as the website), dark mode, logo launcher icon and splash screen | – |

---

## 🧰 Tech stack

| Website (Next.js) | App (Flutter) | Why |
|---|---|---|
| `axios` | [`dio`](https://pub.dev/packages/dio) | HTTP client with interceptors |
| Redux Toolkit (actions + reducers) | [`provider`](https://pub.dev/packages/provider) (`ChangeNotifier`) | App state |
| `usertoken` cookie (`js-cookie`) | [`flutter_secure_storage`](https://pub.dev/packages/flutter_secure_storage) | Keeps the JWT encrypted (Android Keystore) |
| `localStorage` | [`shared_preferences`](https://pub.dev/packages/shared_preferences) | Server URL, theme, wishlist, recent searches, address |
| `<img>` | [`cached_network_image`](https://pub.dev/packages/cached_network_image) | Product images with disk cache |
| Jost font | [`google_fonts`](https://pub.dev/packages/google_fonts) | Same font as the website |
| Skeleton cards | [`shimmer`](https://pub.dev/packages/shimmer) | Loading placeholders |
| `router.push(payment_link_url)` | [`url_launcher`](https://pub.dev/packages/url_launcher) | Opens Razorpay/policy pages |
| – | [`intl`](https://pub.dev/packages/intl) | ₹1,09,999 formatting |
| – | `flutter_launcher_icons`, `flutter_native_splash` (dev) | Generate icon + splash from the logo |

Versions installed on this PC: **Flutter 3.47.5 (stable) / Dart 3.13.4**, Android SDK 36, Android Studio JDK 21.

---

## 📂 Project structure

```
app/
├── lib/
│   ├── main.dart                     ← entry point: loads settings + saved login, then runApp()
│   ├── app.dart                      ← MaterialApp, themes, all Providers
│   ├── config/
│   │   ├── app_config.dart           ← ⚙️ BACKEND URL, AI URL, timeouts, page size   (edit me)
│   │   └── api_endpoints.dart        ← every backend path (/auth/login, /cart, …)
│   ├── core/
│   │   ├── network/api_client.dart   ← Dio client: base URL, Bearer token, logging, error messages
│   │   ├── network/api_exception.dart
│   │   ├── storage/token_storage.dart← JWT in secure storage ("usertoken")
│   │   ├── theme/app_colors.dart     ← 🎨 brand colours                              (edit me)
│   │   ├── theme/app_theme.dart      ← light/dark theme, font
│   │   └── utils/                    ← ₹ formatting, form validators, JWT decoding
│   ├── models/                       ← ProductSummary, ProductDetail, Cart, CategoryNode, Page, Profile
│   │   └── home_data.dart            ← 🏠 home banners, categories, popular searches (edit me)
│   ├── services/                     ← one class per backend service (mirror of website redux actions)
│   │   ├── auth_service.dart         ←   LoginUser / RegisterUser / GetUser
│   │   ├── product_service.dart      ←   getProducts / …withCategory / …withQuery / details / tree
│   │   ├── cart_service.dart         ←   GET/POST/PUT/DELETE /cart…
│   │   ├── payment_service.dart      ←   CreatePayment / VerifyPayment
│   │   └── ai_chat_service.dart      ←   streaming AI chat (SSE)
│   ├── providers/                    ← app state (mirror of website reducers)
│   │   ├── auth_provider.dart        ←   login state, profile, logout
│   │   ├── cart_provider.dart        ←   cart, auto-reload on login
│   │   ├── wishlist_provider.dart    ←   local wishlist
│   │   ├── settings_provider.dart    ←   server URL + theme (saved on phone)
│   │   ├── paged_products.dart       ←   infinite-scroll helper
│   │   └── shell_controller.dart     ←   bottom-tab switching
│   ├── screens/                      ← UI pages (home, categories, search, products, cart,
│   │                                     checkout, auth, account, ai, shell) + routes.dart
│   └── widgets/                      ← reusable UI (ProductCard, NetImage, PriceRow, skeletons, …)
├── assets/
│   ├── images/logo.jpg, logo_mark.png, logo_symbol.png   ← logo (from "shared image.jpg")
│   └── icon/app_icon*.png, splash*.png                   ← sources for launcher icon & splash
├── android/
│   └── app/
│       ├── build.gradle.kts          ← applicationId, minSdk, signing
│       └── src/main/
│           ├── AndroidManifest.xml   ← app name "Quick", INTERNET permission
│           └── res/xml/network_security_config.xml  ← allows http:// to your PC
├── test/widget_test.dart             ← unit tests (formatting, validators, models, JWT)
└── pubspec.yaml                      ← dependencies, assets, icon & splash config
```

**Website ↔ App mapping**

| Website file | App file |
|---|---|
| `.env` → `NEXT_PUBLIC_BACKEND_URL` | `lib/config/app_config.dart` → `defaultApiBaseUrl` |
| `src/redux-store/user/action.js` | `lib/services/auth_service.dart` + `lib/providers/auth_provider.dart` |
| `src/redux-store/products/action.js` | `lib/services/product_service.dart` |
| `src/redux-store/Categories/action.js` | `ProductService.getCategoryTree()` |
| `src/redux-store/cart/action.js` | `lib/services/cart_service.dart` + `lib/providers/cart_provider.dart` |
| `src/redux-store/checkout/action.js` | `lib/services/payment_service.dart` |
| `src/components/ModalAi/AiModal.jsx` | `lib/services/ai_chat_service.dart` + `lib/screens/ai/ai_chat_screen.dart` |
| `src/proxy.js` (protect `/account`) | `AppRoutes.ensureLoggedIn()` in `lib/screens/routes.dart` |
| `components/Home/...CategoryData.js`, `Carsoule.js` | `lib/models/home_data.dart` |

---

## 🔌 How a request travels: phone → USB → PC → backend

The backend runs on **your PC**. The app runs on **your phone**. On the phone, `localhost` means
*the phone itself*, not your PC. So we need a tunnel.
**`adb reverse`** creates that tunnel **through the USB cable**.

```
 ┌─────────────────────────── ANDROID PHONE ───────────────────────────┐
 │  Quick app                                                          │
 │   Screen (e.g. ProductListScreen)                                   │
 │     → Provider / Service  (ProductService.getProducts)              │
 │     → ApiClient (Dio)                                               │
 │         GET http://localhost:8085/products/page?pageno=0&pagesize=12│
 │         Authorization: Bearer <JWT>        (only when logged in)    │
 │                           │                                         │
 │   phone's localhost:8085  ◄── opened by `adb reverse`, owned by adbd│
 └───────────────────────────┼─────────────────────────────────────────┘
                             │  USB cable (ADB protocol)
 ┌───────────────────────────┼──────────────── WINDOWS PC ─────────────┐
 │   adb server  ──────────► PC's localhost:8085                       │
 │                              │                                      │
 │                   Spring Cloud API Gateway  (port 8085)             │
 │                   routes by path (CorsGlobalConfig.java):           │
 │                     /auth/**     → lb://AUTH-SERVICE      (8080)    │
 │                     /products/** → lb://PRODUCTS-SERVICE  (8081)    │
 │                     /cart/**     → lb://CART-SERVICE      (8083)    │
 │                              │  asks Eureka (8761) where it runs    │
 │                              ▼                                      │
 │                   Microservice → MySQL / MongoDB / Kafka            │
 │                              │                                      │
 │   JSON response ◄────────────┘ back through Gateway → adb → USB     │
 └─────────────────────────────────────────────────────────────────────┘
```

Step by step:

1. **The app builds the URL.** `ApiClient` joins the base URL (`http://localhost:8085` by default,
   see [Where to configure what](#-where-to-configure-what)) with the path from `api_endpoints.dart`.
2. **The token is attached.** If you are logged in, `ApiClient` adds
   `Authorization: Bearer <token>` (the token from `POST /auth/login`). The website sends the same
   header, reading the token from its `usertoken` cookie instead.
3. **The phone's `localhost:8085` is a tunnel.** After you run `adb reverse tcp:8085 tcp:8085`,
   the ADB daemon on the phone (`adbd`) listens on the phone's port 8085. Every connection to it
   is carried over the USB cable to the adb server on the PC, which opens a connection to the
   PC's `localhost:8085`. No Wi-Fi, no IP addresses and no firewall rules are involved.
4. **The Gateway routes it.** The Spring Cloud Gateway (port 8085) matches the path (`/products/**`),
   asks Eureka (8761) where `PRODUCTS-SERVICE` is running (`127.0.0.1:8081`), and forwards the
   request with the same headers.
5. **The microservice answers.** For example, ProductService reads MongoDB and returns a Spring
   `Page` JSON. CartService and AuthService verify the JWT (RS256 public key) on protected routes.
6. **The response goes back** the same way: Gateway → adb server → USB → phone → Dio → the model
   classes (`ProductSummary.fromJson` …) → Provider → the screen rebuilds.

You can **watch this live**: when you run `flutter run`, every request is printed in the terminal:

```
[API] → GET http://localhost:8085/products/page?pageno=0&pagesize=12
[API] ← 200 GET http://localhost:8085/products/page?pageno=0&pagesize=12 84ms
[API] → GET http://localhost:8085/cart  (with Bearer token)
[API] ← 200 GET http://localhost:8085/cart 41ms
```

Things that matter for the website but **not** for the app:

* **CORS**: the Gateway only allows `http://localhost:3000`. CORS is enforced by browsers only;
  a native app is not a browser, so the app doesn't need a CORS change.
* **Cookies**: `/auth/login` sets a `usertoken` cookie (`Secure; SameSite=None`) for the website.
  The same response also returns `{ "token": "…" }` in the body; the app stores that token
  in encrypted storage and sends it as a header.
* **Plain HTTP**: Android 9+ blocks `http://` by default. The app allows it through
  `android/app/src/main/res/xml/network_security_config.xml` so it can reach your PC.

---

## 🛠️ One-time setup (tools)

> ✅ Already done on this PC (Sept 2026). Repeat these steps on a teammate's PC.

### 1. Flutter SDK
Installed at **`C:\Users\joshi\develop\flutter`** (Flutter 3.47.5 stable). Flutter must be in a
path **without spaces**.

On a new PC:
1. Download the Windows zip from <https://docs.flutter.dev/install/archive> (stable channel).
2. Extract to e.g. `C:\Users\<you>\develop\flutter`.
3. Add `C:\Users\<you>\develop\flutter\bin` to the **user** `Path`
   (Start → "Edit environment variables for your account" → Path → New).
   *(This was already added on this PC. Open a **new** terminal so it takes effect.)*
4. Check:
   ```bash
   flutter --version
   ```

### 2. Android Studio + Android SDK
Already installed: Android Studio, SDK at `C:\Users\joshi\AppData\Local\Android\Sdk`
(platform android-36, build-tools 35/36, platform-tools = `adb`). Flutter uses the JDK bundled
with Android Studio (`C:\Program Files\Android\Android Studio\jbr`, Java 21).

On a new PC: install Android Studio → open **More Actions → SDK Manager** and install
*Android SDK Platform (latest)*, *Android SDK Build-Tools*, *Android SDK Platform-Tools* and
*Android SDK Command-line Tools (latest)*.

### 3. Accept the Android SDK licenses (do this yourself once)
`flutter doctor` currently says *"Some Android licenses not accepted"*. Read and accept them with:
```bash
flutter doctor --android-licenses
```
Press `y` for each license. (The main SDK license is already accepted, so builds work, but
accepting the rest avoids surprises when Gradle downloads new components.)

### 4. Git
Flutter needs Git (already installed: `C:\Program Files\Git`).

### 5. Check everything
```bash
flutter doctor -v
```
You need ✓ for **Flutter** and **Android toolchain**. The *Visual Studio* warning only matters for
Windows desktop apps and can be ignored.

### 6. Editor (optional)
VS Code with the **Flutter** extension, or Android Studio with the **Flutter** plugin.
Open the folder `frontend/Apps/app`.

---

## 📱 One-time setup (phone)

1. **Enable Developer options**: *Settings → About phone →* tap **Build number** 7 times
   (on Xiaomi/Redmi/POCO: *MIUI/HyperOS version*; on Samsung: *Software information → Build number*).
2. **Enable USB debugging**: *Settings → System → Developer options → USB debugging* = ON.
   - Xiaomi/Redmi/POCO: also turn on **Install via USB** and **USB debugging (Security settings)**
     (needs a SIM + Mi account sign-in).
   - Oppo/Realme/Vivo: also turn on **Disable permission monitoring** if the install is blocked.
3. Connect the phone with a **data** USB cable (some cheap cables only charge).
4. On the phone, pick USB mode **File transfer / MTP** if asked.
5. Accept the **"Allow USB debugging?"** prompt (tick *Always allow from this computer*).
6. Check that the PC sees it:
   ```bash
   adb devices
   ```
   You should see `XXXXXXXX    device`. If it says `unauthorized`, unlock the phone and accept
   the prompt. If nothing shows up, see [Troubleshooting](#-troubleshooting).
   ```bash
   flutter devices
   ```
   should list your phone (e.g. `Redmi Note 12 (mobile) • XXXXXXXX • android-arm64`).

---

## 🖥️ Start the backend

The app needs the same backend as the website (folder `Sem 6 Project/backend`). Start the services
**in this order** (from IntelliJ, or `mvnw spring-boot:run` in each project folder):

| # | Service | Folder | Port | Needs |
|---|---|---|---|---|
| 0 | Kafka / Redis / Elasticsearch | `backend/AuthService/service/docker-compose.yml` → `docker compose up -d` | 9092 / 6379 / 9200 | Docker Desktop |
| 1 | **Eureka** (service registry) | `backend/ServiceDiscover/registry.discoveryserver` | **8761** | – |
| 2 | **AuthService** | `backend/AuthService/service` | 8080 | MySQL + env vars `JDBC_DB_URL`, `JDBC_DB_USERNAME`, `JDBC_DB_PASSWORD`, `JWT_SECRET_KEY`, `RS256_PUBLIC_KEY`, `RS256_PRIVATE_KEY`, `MAIL_*`, `RAZORPAY_*`, `GOOGLE_CLIENT_*`, `FRONTEND_URL`, `FRONTEND_REDIRECT_URL` |
| 3 | **ProductService** | `backend/ProductService/ProductServiceApp` | 8081 | `MANGO_DB_URI`, `RS256_PUBLIC_KEY`, `KAFKA_SERVER_PORT` (e.g. `localhost:9092`) |
| 4 | **CartService** | `backend/CartService/CartServiceApp` | 8083 | `MANGO_DB_URI`, `RS256_PUBLIC_KEY`, `KAFKA_SERVER_PORT` |
| 5 | **API Gateway** | `backend/ApiGateway/v2/gateway` | **8085** | – |

Check that it works **on the PC** before touching the phone:

1. Open <http://localhost:8761>. `AUTH-SERVICE`, `PRODUCTS-SERVICE`, `CART-SERVICE` and
   `APIGATEWAY` must be listed (it can take ~30 s after start-up).
2. Call the gateway:
   ```bash
   curl "http://localhost:8085/products/page?pageno=0&pagesize=1"
   ```
   You should get JSON with `"content": [...]`. If this fails on the PC, it will fail on the phone too.

---

## ▶️ Run the app on the phone (step by step)

Open a **new** terminal (PowerShell, cmd or the VS Code terminal) and:

**1. Go to the project**
```bash
cd "C:\Users\joshi\OneDrive\Desktop\Sem 6 Project\frontend\Apps\app"
```

**2. Download the Dart packages** (first time, and after changing `pubspec.yaml`)
```bash
flutter pub get
```

**3. Check the phone is connected**
```bash
adb devices
```

**4. Create the USB tunnel for the backend port** (repeat after every re-plug or phone reboot)
```bash
adb reverse tcp:8085 tcp:8085
```
Check it:
```bash
adb reverse --list
```
→ a line ending in `tcp:8085 tcp:8085` (e.g. `UsbFfs tcp:8085 tcp:8085`)

**5. Run the app**
```bash
flutter run
```
The first build takes a few minutes (Gradle downloads its dependencies); later builds are much
faster. The app installs and opens on the phone. In the terminal:

| Key | Action |
|---|---|
| `r` | Hot reload (apply code changes instantly, keeps state) |
| `R` | Hot restart (restart the app) |
| `q` | Quit |

If more than one device is connected, pick one with `flutter run -d <device-id>`
(IDs come from `flutter devices`).

**6. Try it**
- Home loads products → the phone reaches the gateway ✅
- **Account → Server settings → Test** shows *"Connected to http://localhost:8085 in XX ms"*.
- Sign up, log in, open a product, add to cart.

> If you see **"Cannot reach the server at http://localhost:8085"**, either the backend isn't
> running or the `adb reverse` tunnel is gone. Run step 4 again and pull down to refresh.

---

## 📶 Alternative: connect over Wi-Fi instead of USB

Use this if you want to unplug the phone after installing the app.

1. Connect the **phone and the PC to the same Wi-Fi** (hotspots with "client isolation", such as
   many college/office networks, block device-to-device traffic).
2. Find the PC's IP:
   ```bash
   ipconfig
   ```
   → *Wireless LAN adapter Wi-Fi → IPv4 Address*, e.g. `192.168.1.5`.
3. Allow port 8085 through Windows Firewall (run PowerShell **as Administrator**, once):
   ```bash
   netsh advfirewall firewall add rule name="Quick API Gateway 8085" dir=in action=allow protocol=TCP localport=8085
   ```
   Also make sure the Wi-Fi is set to a **Private** network profile.
4. Test from the **phone's browser**: `http://192.168.1.5:8085/products/page?pageno=0&pagesize=1`.
5. Point the app at it, either way:
   - **No rebuild:** in the app go to *Account → Server settings*, enter `http://192.168.1.5:8085`,
     tap **Test**, then **Save**.
   - **At build time:**
     ```bash
     flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8085
     ```

Spring Boot listens on all network interfaces (`0.0.0.0`) by default, so the gateway is reachable
at the PC's IP. Only the gateway port (8085) needs to be open; the gateway talks to the other
services on `127.0.0.1` inside the PC.

---

## ⚙️ Where to configure what

| What | Where | Notes |
|---|---|---|
| **Backend (API Gateway) URL (default)** | `lib/config/app_config.dart` → `defaultApiBaseUrl` | Default `http://localhost:8085` (works with `adb reverse`) |
| Backend URL at build time | `flutter run --dart-define=API_BASE_URL=http://IP:8085` | Overrides the default without editing code |
| Backend URL at runtime | App → **Account → Server settings** | Saved on the phone; takes priority over both above. "Reset to default" removes it |
| AI chat URL | `lib/config/app_config.dart` → `aiChatUrl` or `--dart-define=AI_CHAT_URL=…` | Same URL as the website AI modal |
| API paths (`/auth/login`, `/cart`, …) | `lib/config/api_endpoints.dart` | Change here if a backend route changes |
| Request timeouts | `lib/config/app_config.dart` → `connectTimeout`, `receiveTimeout` | |
| Products per page | `lib/config/app_config.dart` → `pageSize` | Website uses 12 |
| Website / policy links | `lib/config/app_config.dart` → `websiteUrl`, `policyUrl` | |
| Request logging (`[API] → …`) | `lib/core/network/api_client.dart` | Only printed in debug builds |
| Error messages shown to users | `lib/core/network/api_client.dart` → `_defaultMessage` | |
| Brand colours | `lib/core/theme/app_colors.dart` | Sampled from the logo |
| Theme (buttons, inputs, font) | `lib/core/theme/app_theme.dart` | Font: `GoogleFonts.jostTextTheme` |
| Home banners, category shortcuts, popular searches | `lib/models/home_data.dart` | Copied from the website data files |
| Home product rows (which categories) | `lib/screens/home/home_screen.dart` → `ProductRowSection(category: 'electronics')` | Value must match a product's `categoryPath` entry |
| Form rules (name ≥ 3, 10-digit mobile, …) | `lib/core/utils/validators.dart` | Same as website signup |
| App name on the phone | `android/app/src/main/AndroidManifest.xml` → `android:label="Quick"` | |
| Application ID / package | `android/app/build.gradle.kts` → `applicationId`, `namespace` (`com.quicksin.quick`) | Changing it also means moving `MainActivity.kt` |
| App version | `pubspec.yaml` → `version: 1.0.0+1` | `versionName+versionCode` |
| Min / target Android version | `android/app/build.gradle.kts` → `minSdk`, `targetSdk` | Defaults come from Flutter |
| Allow `http://` (cleartext) | `android/app/src/main/res/xml/network_security_config.xml` | Set to `false` once the API is on HTTPS |
| Internet permission | `android/app/src/main/AndroidManifest.xml` | Already added |
| Launcher icon | `assets/icon/app_icon.png`, `app_icon_foreground.png` + `flutter_launcher_icons:` in `pubspec.yaml` | Regenerate: `dart run flutter_launcher_icons` |
| Splash screen | `assets/icon/splash_*.png` + `flutter_native_splash:` in `pubspec.yaml` | Regenerate: `dart run flutter_native_splash:create` |
| Logo inside the app | `assets/images/logo_mark.png` (full), `logo_symbol.png` (bag) | Made from `Downloads/shared image.jpg` |
| Release signing key | `android/app/build.gradle.kts` → `buildTypes.release.signingConfig` | Uses the debug key for now |
| Backend port | `backend/ApiGateway/v2/gateway/src/main/resources/application.properties` → `server.port=8085` | If you change it, also change the `adb reverse` port and the app URL |

---

## 📡 API reference (same as the website)

All paths go to the API Gateway (`<baseUrl>` = `http://localhost:8085`). 🔒 = needs
`Authorization: Bearer <token>`; the app adds it automatically after login.

| Method & path | Auth | Request | Response | Used in |
|---|---|---|---|---|
| `POST /auth/login` | – | `{email, password}` | `{token, message}` (+ `usertoken` cookie for the web) | Login |
| `POST /auth/signup` | – | `{name, mobileno, email, password}` | `201 {token:"", message}` / `409` if the email exists | Sign up |
| `GET /auth/profile` | 🔒 | – | `{name, mobileno, email}` | Account |
| `GET /products/page?pageno&pagesize` | – | `pageno` is **0-based** (app sends page − 1, like the website) | Spring `Page<ProductsDto>` | Home, All products |
| `GET /products/page/category/main?category&pageno&pagesize` | – | `category` must be in the product's `categoryPath` | `Page<ProductsDto>` | Category lists, home rows |
| `GET /products/page/query/main?query&pageno&pagesize` | – | name contains `query` (case-insensitive) | `Page<ProductsDto>` | Search results |
| `GET /products/suggestions?q` | – | – | list of names/objects | Search suggestions |
| `GET /products/category/tree` | – | – | `[{id, name, children:[…]}]` | Categories |
| `GET /products/{id}` | – | – | full `Product` document | Product details |
| `GET /cart` | 🔒 | – | `{id, userId, items:[…], summary:{subTotal, discount, deliveryFee, tax, totalAmount}}` | Cart |
| `POST /cart/item/add` | 🔒 | `{productId, quantity, productName, productImage, price}` | Cart | Add to cart / Buy now |
| `PUT /cart/item` | 🔒 | `{productId, quantity}` | Cart | Quantity stepper |
| `DELETE /cart/item/{productId}` | 🔒 | – | Cart | Remove item |
| `DELETE /cart/clear` | 🔒 | – | Cart | Clear cart |
| `POST /api/payments/{id}` | 🔒 | – | `{payment_link_url, …}` | Checkout |
| `GET /api/payments?razorpay_payment_id&razorpay_payment_link_id&razorpay_payment_link_status&purchase_id` | 🔒 | – | verification result | `PaymentService.verifyPayment` (for the payment callback) |
| `POST https://ai.vhbuyio.in/api/chat` | – | `{messages:[{role, content}]}`, `Accept: text/event-stream` | SSE `data: {"type":"delta","text":"…"}` | Ayira AI |

---

## 📦 Build a release APK

```bash
flutter build apk --release
```
The APK is at `build\app\outputs\flutter-apk\app-release.apk`. Install it on the connected phone with:
```bash
adb install -r build\app\outputs\flutter-apk\app-release.apk
```
A release build keeps the saved **Server settings** URL, so set it in the app (or build with
`--dart-define=API_BASE_URL=…`). It is signed with the debug key for now; create an upload
keystore before publishing to the Play Store (<https://docs.flutter.dev/deployment/android>).

---

## 🩺 Troubleshooting

| Problem | Fix |
|---|---|
| `flutter` is not recognized | Open a **new** terminal (PATH was updated), or add `C:\Users\joshi\develop\flutter\bin` to your user Path. |
| `adb devices` shows nothing | Use a data cable, try another USB port, set USB mode to *File transfer*, install the phone maker's USB driver (Samsung/Xiaomi) or the *Google USB Driver* (SDK Manager → SDK Tools). Then `adb kill-server` and `adb devices`. |
| `adb devices` shows `unauthorized` | Unlock the phone and accept "Allow USB debugging". If no prompt appears: Developer options → *Revoke USB debugging authorizations*, re-plug. |
| App says **"Cannot reach the server at http://localhost:8085"** | 1) Check `curl http://localhost:8085/products/page?pageno=0&pagesize=1` works on the PC. 2) Run `adb reverse tcp:8085 tcp:8085` again (the tunnel is lost on re-plug/reboot). 3) In the app, *Account → Server settings → Test*. |
| Works over USB but not Wi-Fi | Same network? Firewall rule for 8085? Network profile *Private*? Test the URL in the phone's browser first. Some college Wi-Fi networks block device-to-device traffic, so use USB or a phone hotspot. |
| `503 Service Unavailable` | The gateway is up but the target service isn't registered in Eureka yet. Check <http://localhost:8761> and wait ~30 s. |
| Login says **Invalid email or password** | Wrong credentials, or the user doesn't exist in this database. Sign up first (the very first user becomes ADMIN, per `MyUserServices.createUser`). |
| Logged out automatically | The JWT expires after 7 days (`JwtUtil`). The app logs out when it expires; log in again. |
| **Add to cart fails with "Product not found" / server error** | Backend bug, see [Known backend gaps](#-known-backend-gaps) #1. |
| Checkout says **Payment unavailable** | PaymentService isn't implemented yet, see [Known backend gaps](#-known-backend-gaps) #2. |
| No search suggestions | `/products/suggestions` doesn't exist in ProductService yet; search itself still works. |
| Product images don't show | Image URLs must be full `http(s)://` URLs the **phone** can reach. A URL like `http://localhost:9000/...` points to the phone itself. Use public URLs (S3/CDN), or `adb reverse` that port too. |
| Xiaomi: `INSTALL_FAILED_USER_RESTRICTED` | Developer options → enable **Install via USB** (and accept the prompt on the phone during install). |
| First build is very slow / Gradle errors | The first build downloads Gradle and dependencies (needs internet). Retry; if it keeps failing run `flutter clean`, then `flutter pub get`, then `flutter run`. |
| "Some Android licenses not accepted" | `flutter doctor --android-licenses` and accept them. |
| Font looks different offline | Jost is downloaded by `google_fonts` on first launch (needs internet once), then cached. |

---

## 🧱 Known backend gaps

These are backend issues (not in this app) that affect both the app and the website:

1. **Add to cart always fails.** In
   `backend/CartService/.../Service/CartService.java → addItem()`:
   ```java
   if(!newItem.getProductId().equals(productsdataSnapshotRepository.findByProductId(newItem.getProductId()))){
       throw new RuntimeException("Product not found");
   }
   ```
   `findByProductId` returns an `Optional<ProductsdataSnapshot>`, and a `String` never equals an
   `Optional`, so this always throws. The intended check is:
   ```java
   if (!productsdataSnapshotRepository.existsByProductId(newItem.getProductId())) {
       throw new RuntimeException("Product not found");
   }
   ```
   (The snapshot is filled by `ProductEventConsumer` through Kafka, so Kafka must be running when
   products are created.) The website's `AddToCartRequest` calls a non-existent
   `GET /cart/getuser`; the app calls the real `POST /cart/item/add` endpoint.
2. **Payments / orders.** `backend/PaymentService` and `backend/OrderService` are empty, and the
   gateway has no route for `/api/**`. The app already calls `POST /api/payments/{id}` exactly
   like the website and opens `payment_link_url`. It will work once the service exists and a
   gateway route for `/api/payments/**` is added. Until then checkout shows a clear
   "Payment unavailable" message, and **My Orders** stays empty.
3. **Search suggestions**: `GET /products/suggestions` isn't implemented in ProductService yet.
4. **Wishlist & addresses** have no backend API yet, so the app saves them on the phone.
5. **Profile role**: `/auth/profile` doesn't return `role`; the app reads it from the JWT `roles`
   claim instead.

---

## 🧾 Command cheat-sheet

```bash
# every time you start working
cd "C:\Users\joshi\OneDrive\Desktop\Sem 6 Project\frontend\Apps\app"
adb devices
adb reverse tcp:8085 tcp:8085
flutter run

# useful extras
flutter devices                       # list connected phones
adb reverse --list                    # show active tunnels
adb reverse --remove-all              # remove tunnels
flutter run --dart-define=API_BASE_URL=http://192.168.1.5:8085   # Wi-Fi mode
flutter analyze                       # static checks
flutter test                          # unit tests
flutter clean; flutter pub get        # fix odd build problems
flutter build apk --release           # release APK
adb logcat -s flutter                 # app logs without flutter run
dart run flutter_launcher_icons       # regenerate app icon
dart run flutter_native_splash:create # regenerate splash
```

---

👤 **Author:** Bhaskar Joshi · [@joshibhaskar684](https://github.com/joshibhaskar684) · Website: <https://www.quicksin.in>
