# Publishing DiscountBay to Google Play and the App Store

A checklist for the developer, in order. Listing text, data-safety answers and store images are in `store/LISTING.md` and `store/google-play/`.

## 0. Before the first store build (blocking)

- [ ] **Confirm the API endpoints.** All paths the app calls are in `lib/data/api_config.dart` (`Endpoints`). Check each one against the API's Postman collection or `https://api.discountbay.com/openapi.json`, and fix any path that differs. Then run the app on live data and click through every screen:
  ```bash
  flutter run --dart-define=DEMO=false
  ```
  If a field shows up empty (logo, code, expiry), add the API's key name to that field's list in `lib/data/models.dart`.
- [ ] **Never ship demo data.** Store builds made with `tool/build_release.sh` always set `DEMO=false`. Don't upload a build made with plain `flutter build`.
- [ ] Bundle id / application id is `com.discountbay.discountbay`. If you want a different one, change it **before** the first upload (it can never change afterwards).

## 1. One-time project setup

Requirements: Flutter 3.27+ (stable), Xcode 16+ on a Mac for iOS, Android Studio with SDK 35.

```bash
bash tool/setup_platforms.sh   # creates android/ and ios/, app name, link permissions, release signing, icons, splash
flutter analyze
flutter test
flutter run                    # demo data, no backend needed
```

You can commit the generated `android/` and `ios/` folders after this step, or keep regenerating them with the script (CI does the latter).

## 2. Google Play

**A1. Developer account.** Create it at play.google.com/console as an **Organization** (Best My Flight Inc.), which needs a D-U-N-S number. New *personal* accounts must run a closed test with at least 12 testers for 14 days before they can publish to production; organization accounts skip that.

**A2. Upload key** (once, keep it safe — losing it means contacting Google to reset it):
```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```
Create `android/key.properties` (git-ignored):
```
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/Users/you/upload-keystore.jks
```

**A3. Build:**
```bash
bash tool/build_release.sh android
# → build/app/outputs/bundle/release/app-release.aab
```
Or from GitHub: add the four `ANDROID_*` secrets listed at the top of `.github/workflows/release-android.yml`, then run **Actions → Release (Android) → Run workflow** (or push a tag like `v1.0.0`) and download the `.aab` from the run's Artifacts.

**A4. Play Console:**
1. Create app → name "DiscountBay: Coupons & Deals", Free, App.
2. Fill **App content**: privacy policy URL, ads = No, content rating, target audience 18+, data safety (answers in `store/LISTING.md`).
3. **Main store listing**: paste the texts, upload `icon-512.png`, the feature graphic and phone screenshots.
4. **Testing → Internal testing** → create release → upload the `.aab` (accept Play App Signing) → add your testers → install from the opt-in link and check it.
5. **Production** → create release → promote the same build → send for review (usually 1–7 days for a new app).

## 3. Apple App Store

**B1. Developer account.** Enroll at developer.apple.com as an **Organization** (needs D-U-N-S), $99/year.

**B2. App record.** In App Store Connect → Apps → + → New App: platform iOS, name "DiscountBay: Coupons & Deals", bundle id `com.discountbay.discountbay` (register it first under Certificates, Identifiers & Profiles if it isn't listed), SKU `discountbay-ios`.

**B3. Signing.** Open `ios/Runner.xcworkspace` in Xcode → Runner target → Signing & Capabilities → tick "Automatically manage signing" and choose the team.

**B4. Build and upload:**
```bash
bash tool/build_release.sh ios
# → build/ios/ipa/*.ipa
```
Upload with the **Transporter** app (drag the .ipa in), or in Xcode: Product → Archive → Distribute App → App Store Connect.

**B5. TestFlight**: the build appears after processing (10–30 min). Add internal testers and install via the TestFlight app.

**B6. Submit**: fill the listing, App Privacy and App Review notes from `store/LISTING.md`, add 6.9" iPhone screenshots, pick the build, Submit for Review (usually 1–3 days).

Apple sometimes rejects apps that feel like a copy of a website (guideline 4.2). The native features to point to if asked: one-tap copy-and-open coupons, saved offers and followed stores on the device, and native search and browsing.

## 4. Every update

1. Bump the version in `pubspec.yaml`: `version: 1.0.1+2` — the number after `+` must go up on every upload to either store.
2. `bash tool/build_release.sh android` and `bash tool/build_release.sh ios`.
3. Upload; keep `build/symbols/` for each version (needed to read crash reports from obfuscated builds).

## Known follow-ups (not needed for 1.0)

- In-app sign-in: Log in / Sign up currently open the website. If accounts are added inside the app later, Apple also requires an in-app "Delete account" option.
- Push notifications for followed stores (needs a Firebase project and an APNs key).
- Bundle the Anton and IBM Plex Mono fonts as assets (today they download on first launch and are then cached; Archivo and Inter are already bundled).
