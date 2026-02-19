# Dependency Audit — 2026-02-18

## Environment

- **Flutter:** 3.38.9 (stable)
- **Dart SDK:** 3.10.8
- **DevTools:** 2.51.1

---

## Phase 1: Safe Upgrades (`flutter pub upgrade`)

35 packages updated within existing constraints. No code changes required.

| Package | Previous | Updated To |
|---|---|---|
| crypto | 3.0.6 | 3.0.7 |
| dio | 5.8.0+1 | 5.9.1 |
| http | 1.3.0 | 1.6.0 |
| provider | 6.1.2 | 6.1.5+1 |
| shared_preferences | 2.5.2 | 2.5.4 |
| universal_html | 2.2.4 | 2.3.0 |
| url_launcher | 6.3.1 | 6.3.2 |
| flutter_timezone | 4.1.0 | 4.1.1 |
| timezone | 0.10.0 | 0.10.1 |
| *(+ 26 transitive deps)* | | |

---

## Phase 2: Major Version Upgrades

### Batch 1 — Low Risk ✅

| Package | Previous | Updated To | Breaking Changes |
|---|---|---|---|
| flutter_lints (dev) | ^5.0.0 | ^6.0.0 | Stricter lint rules only |
| email_validator | ^2.1.17 | ^3.0.0 | None observed |
| flutter_launcher_icons | ^0.13.1 | ^0.14.4 | None observed |

### Batch 2 — Low-Medium Risk ✅

| Package | Previous | Updated To | Breaking Changes |
|---|---|---|---|
| timezone | ^0.10.0 | ^0.11.0 | None observed |
| flutter_timezone | ^4.1.0 | ^5.0.1 | **Yes** — `getLocalTimezone()` returns `TimezoneInfo` instead of `String` |
| intl | ^0.17.0 | ^0.20.2 | None observed |

**Code fixes applied:**
- `board.dart` line 609: Changed to `(await FlutterTimezone.getLocalTimezone()).identifier`
- `api_service.dart` (4 occurrences): Same `.identifier` fix applied

### Batch 3 — Medium Risk ✅

| Package | Previous | Updated To | Breaking Changes |
|---|---|---|---|
| window_manager | ^0.4.3 | ^0.5.1 | None observed |
| connectivity_plus | ^5.0.2 | ^7.0.0 | **Yes** — All APIs return `List<ConnectivityResult>` instead of single `ConnectivityResult` |

**Code fixes applied:**
- `connectivity_monitor.dart`: Updated `StreamSubscription` type, `_updateConnectionStatus` parameter, and `checkConnection()` to work with `List<ConnectivityResult>`

### Batch 4 — Highest Risk ✅

| Package | Previous | Updated To | Breaking Changes |
|---|---|---|---|
| flutter_secure_storage | ^8.0.0 | ^10.0.0 | **Deprecation** — `encryptedSharedPreferences` parameter removed (auto-migration) |

**Code fixes applied:**
- `secure_storage.dart`: Removed deprecated `AndroidOptions(encryptedSharedPreferences: true)` parameter

---

## Remaining Incompatible Packages (Not Upgraded)

These are transitive dependencies or SDK-pinned packages we cannot control:

| Package | Current | Latest | Reason |
|---|---|---|---|
| fernet | 0.0.4 | 0.0.6 | Low-activity pre-1.0 package; evaluate replacing later |
| js | 0.6.7 | 0.7.2 | **Discontinued** — superseded by `dart:js_interop`. Pulled transitively. |
| characters | 1.4.0 | 1.4.1 | Pinned by Flutter SDK |
| matcher | 0.12.17 | 0.12.18 | Pinned by Flutter SDK |
| material_color_utilities | 0.11.1 | 0.13.0 | Pinned by Flutter SDK |
| meta | 1.17.0 | 1.18.1 | Pinned by Flutter SDK |
| pointycastle | 3.9.1 | 4.0.0 | Pinned by encrypt package |
| test_api | 0.7.7 | 0.7.9 | Pinned by Flutter SDK |

---

## Post-Upgrade Verification

- **`flutter analyze`**: 0 errors, 15 info items (all pre-existing style suggestions)
- **`flutter build windows`**: ✅ Success — `build\windows\x64\runner\Release\reword_game.exe` (after `flutter clean`)
- **`flutter build apk`**: ✅ Success — `build\app\outputs\flutter-apk\app-release.apk` (51.1MB)

---

## Files Modified

| File | Change |
|---|---|
| `pubspec.yaml` | 10 dependency version bumps |
| `lib/models/board.dart` | `FlutterTimezone.getLocalTimezone().identifier` |
| `lib/services/api_service.dart` | `FlutterTimezone.getLocalTimezone().identifier` (4 occurrences) |
| `lib/utils/connectivity_monitor.dart` | `List<ConnectivityResult>` migration |
| `lib/utils/secure_storage.dart` | Removed deprecated `encryptedSharedPreferences` |
| `android/settings.gradle.kts` | Android Gradle Plugin 8.7.0 → 8.9.1 (required by AndroidX deps) |
| `android/gradle/wrapper/gradle-wrapper.properties` | Gradle 8.10.2 → 8.11.1 (required by AGP 8.9.1) |
| `android/app/proguard-rules.pro` | Added `-dontwarn javax.lang.model.element.Modifier` for R8 compatibility |
