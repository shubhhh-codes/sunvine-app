# ⚡ Sunvine EPC — Developer & Flutter Workflow Cheat Sheet

> Complete quick-reference guide for instant app launching, live hot-reloading, CLI shortcuts, and native debugging workflows for the **Sunvine EPC Android Monorepo**.

---

## 🚀 1. Instant Quick Shortcuts (Monorepo Root)

Execute these commands directly from `E:\sunvine-apk`:

| Command | Speed | Description |
|---|---|---|
| `npm run dev` | **Instant** | Starts the app with **Auto Hot-Reload on `Ctrl+S`** (Vite / Next.js style file watcher). |
| `.\dev` | **Instant** | 1-word Windows shortcut executing the auto-reload watcher. |
| `npm run app:launch` | **< 0.3s** | Bypasses Gradle/Flutter completely — immediately opens the installed app on your phone via ADB. |
| `npm run app` | Standard | Runs `flutter run` with production gateway `--dart-define`. |
| `npm run app:clean` | ~5s | Runs `flutter clean` and reinstalls Dart packages. |
| `npm run app:analyze` | ~2s | Static analysis with Dart analyzer (0 errors, 0 warnings guarantee). |
| `npm run gateway:dev` | **Instant** | Runs the Cloudflare Worker gateway locally using Miniflare / Wrangler. |
| `npm run gateway:test`| ~3s | Runs Vitest test suite for gateway endpoints and token rotation (13/13 passing). |

---

## 📱 2. Official Flutter CLI Commands

Flutter does not use `flutter launch` or `flutter start`. Below are the canonical commands:

### Core Execution
```powershell
# NOTE: Run Flutter commands inside 'app' folder: cd app

# Standard run with production gateway URL
flutter run -d RZGYA0LA25E --dart-define=GATEWAY_BASE_URL=https://gateway.sunvine.in

# Faster startup (skips pub get dependency checks)
flutter run --no-pub

# Run already built app directly (skips Gradle build check entirely!)
flutter run --no-build

# Instant Attach (Connects to already running app in ~1 second!)
flutter attach -d RZGYA0LA25E
```

### Installation & Packaging
```powershell
# Push already compiled APK directly to device without recompiling
flutter install -d RZGYA0LA25E

# Build Debug APK
flutter build apk --debug

# Build Release APK
flutter build apk --release
```

### Diagnostics & Devices
```powershell
# List connected physical devices and emulators
flutter devices

# Diagnostic check of Flutter environment and toolchains
flutter doctor -v
```

---

## ⚡ 3. Hot Reload vs. Hot Restart (Terminal Controls)

When `flutter run` or `npm run dev` is active in your terminal:

| Key | Mode | Time | Behavior |
|:---:|:---:|:---:|---|
| <kbd>r</kbd> | **Hot Reload** | **< 200ms** | Injects updated code into the Dart VM. Preserves state (e.g. form inputs, navigation stack). |
| <kbd>R</kbd> | **Hot Restart** | **~ 1.2s** | Destroys state and restarts the Dart app fresh from `main()`. Much faster than a full rebuild. |
| <kbd>p</kbd> | **Debug Paint** | Instant | Toggles visual layout boundaries and padding on the phone screen. |
| <kbd>h</kbd> | **Help** | Instant | Prints all available interactive runtime shortcuts. |
| <kbd>d</kbd> | **Detach** | Instant | Disconnects terminal debugging while leaving the app running on your phone. |
| <kbd>q</kbd> | **Quit** | Instant | Terminates the app process and closes the debug session. |

---

## 🖥️ 4. IDE 1-Click Workflow (`F5` Run & Auto-Save)

For VS Code, Cursor, or Antigravity IDE:

1. Open `.vscode/launch.json` (already pre-configured in this repository).
2. Press <kbd>F5</kbd> on your keyboard or click the **Green Play ▶** button in the Run & Debug sidebar.
3. **Auto Hot-Reload**: Whenever you edit any `.dart` file and press <kbd>Ctrl</kbd> + <kbd>S</kbd>, Flutter automatically reloads the UI on your phone.

---

## 🔌 5. Direct ADB Shortcuts (Super Low-Level)

If you ever need direct hardware control via Android Debug Bridge:

```powershell
# Set ADB alias in PowerShell
$adb = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"

# 1. Instant Launch app on device screen (< 0.2s)
& $adb shell am start -n com.sunvine.epc/.MainActivity

# 2. Force Stop app on device
& $adb shell am force-stop com.sunvine.epc

# 3. Clean Uninstall
& $adb uninstall com.sunvine.epc

# 4. View real-time Flutter device logs
& $adb logcat -s flutter:V
```

---

## 🛠️ 6. Troubleshooting & Windows Gotchas

| Problem | Root Cause | Permanent Resolution |
|---|---|---|
| `compileSdk = 35` build failure | Plugins (`local_auth_android`, lifecycle) require Android SDK 36 | Set `compileSdk = 36` and `targetSdk = 36` in `app/android/app/build.gradle.kts`. |
| `IllegalArgumentException: different roots (C:\... and E:\...)` | Kotlin incremental compiler fails across different drive letters on Windows | Set `kotlin.incremental=false` in `app/android/gradle.properties`. |
| `Building with plugins requires symlink support` | Windows Developer Mode disabled | Run `start ms-settings:developers` and toggle Developer Mode **ON**. |
| `Daemon disappeared` / `os error 32` file lock | Orphaned Java / Gradle background process | Run `Get-Process java -ErrorAction SilentlyContinue \| Stop-Process -Force` in PowerShell. |

---

*Authored for Sunvine EPC Monorepo — Version 1.0 (Phase 0 Step B)*
