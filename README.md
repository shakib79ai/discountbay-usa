# DiscountBay — iOS & Android app (Flutter)

Native mobile app for [discountbay.com](https://discountbay.com), built in Flutter from one codebase and styled with the website's design system and the DiscountBay logo.

**Publishing to Google Play and the App Store:** follow [`docs/RELEASE.md`](docs/RELEASE.md). Store texts, data-safety answers and store images are in [`store/`](store/LISTING.md).

## Design system (same as the website)

| Token | Value | Used for |
| --- | --- | --- |
| ink | `#12203A` | App background, text on paper |
| paper / paper-dim | `#FBF7EE` / `#F1EBDC` | Ticket cards, light bands |
| coral | `#FF5A47` | Logo mark, codes, stamps, accents |
| mustard | `#FFC145` | Primary CTAs, active tab, newsletter band |
| mint | `#3FB88C` | Verified badges, deals |
| Fonts | Anton · Archivo · Inter · IBM Plex Mono | Display · headings · body · codes |

Logo: the official DiscountBay artwork from the brand kit, in `assets/brand/` (1×, 2×, 3×) and shown with `lib/widgets/brand_logo.dart`. The app icon, Android adaptive icon and splash screen are generated from `assets/icon/`.

Motifs carried over: **perforated dividers** between bands, **scalloped ticket cards** with side notches and a dashed tear line, **tilted dashed stamps** ("20% OFF", "DEAL"), and **barcode accents** on the coupon sheet. All live in `lib/theme/tokens.dart` and `lib/widgets/decor.dart`.

## Screens

- **Home** — hero ("Stop paying full price!"), store search, trending stores, stat tape, Popular Stores, Today's Top Verified Deals (All / Codes / Deals / Ending soon), Trending Categories, Hot Product Deals, How it works, FAQ, newsletter.
- **Stores** — search + A–Z rail + infinite list.
- **Store page** — ticket header with logo, active offers / best deal / verified stats, Visit + Follow, tabs with counts, sort, "Show more", "Missed these?" expired offers, how-to-redeem, about, similar stores, store alerts signup.
- **Categories** — tile grid → category page (stores + offers).
- **Top offers** — full list with filters and infinite scroll.
- **Search** — stores and offers as you type.
- **Saved** — saved offers and followed stores, stored on the device (no account needed).
- **Account** — sign up / log in (opens the website for now), help, legal, contact, socials, FAQ.
- **Coupon sheet** — tapping any offer opens a ticket: codes are copied with one tap and the store opens; deals open the store directly.

## Getting started

Requires **Flutter 3.27+** (Dart 3.6+), Xcode 16+ for iOS, Android Studio / SDK for Android.

```bash
bash tool/setup_platforms.sh   # one time: creates android/ & ios/, app name, permissions, signing, icons, splash
flutter run                    # runs with bundled demo data — no backend needed
```

Run against the live API:

```bash
flutter run --dart-define=DEMO=false --dart-define=API_BASE=https://api.discountbay.com
```

## Connecting the API (do this first)

The app was written without access to the API's OpenAPI schema, so the backend contract is isolated in two places:

1. **`lib/data/api_config.dart` → `Endpoints`** — every path the app calls. Check each one against the Postman collection (41 endpoints) or `GET /openapi.json` and edit only here.

   | App needs | Assumed path |
   | --- | --- |
   | Popular stores | `GET /api/stores/popular` |
   | Store list | `GET /api/stores?search=&letter=&page=&limit=` |
   | Store / its offers / similar | `GET /api/stores/{slug}`, `/offers?sort=`, `/similar` |
   | Categories / category stores / offers | `GET /api/categories`, `/{slug}/stores`, `/{slug}/offers` |
   | Top offers | `GET /api/offers/top?type=code|deal&ending_soon=true&page=` |
   | Hot product deals (banners) | `GET /api/offers/banners` |
   | Search | `GET /api/search?q=` → `{stores: [], offers: []}` |
   | Newsletter | `POST /api/newsletter/subscribe {email}` |

2. **`lib/data/models.dart`** — JSON parsing accepts several key spellings per field (e.g. `code` / `coupon_code`, `logo_url` / `logo`, `offer_count` / `offers_count`), bare lists or `{items|data|results}` envelopes, and relative `/static/...` image paths. If a field still comes through empty, add your key name to that field's list.

If an endpoint doesn't exist yet (e.g. `/similar`, `/search`), either add it to the FastAPI app or point the path at an existing one — similar stores and category offers already fail soft and just hide their section.

Once the endpoints are confirmed, flip the default in `ApiConfig.demo` to `false`.

## Release builds

```bash
bash tool/build_release.sh android   # signed .aab for Google Play (needs android/key.properties)
bash tool/build_release.sh ios       # .ipa for the App Store (macOS + Xcode)
```

Both always build against the live API with demo data off. Full store checklist: [`docs/RELEASE.md`](docs/RELEASE.md).

GitHub Actions: `CI` checks every push (analyze, test, Android build; iOS on demand), and `Release (Android)` builds the signed Play bundle from repository secrets.

Bundle id / package name: `com.discountbay.discountbay`.

## Project layout

```
lib/
  main.dart                 app entry, providers, theme
  theme/tokens.dart         colours, fonts, ThemeData
  data/
    api_config.dart         base URL, demo flag, ALL endpoint paths
    api_repository.dart     live FastAPI client
    demo_repository.dart    bundled sample data
    repository.dart         interface used by the UI
    models.dart             Store, StoreCategory, Offer (+ tolerant parsing)
    content.dart            FAQ, steps, contact, socials
  state/saved.dart          saved offers + followed stores (shared_preferences)
  widgets/                  logo, ticket, perforation, stamp, barcode, cards, coupon sheet, newsletter
  screens/                  shell (bottom tabs), home, stores, store, categories, category,
                            top offers, search, saved, account
assets/brand/               DiscountBay logo (1x / 2.0x / 3.0x)
assets/icon/                app icon, adaptive icon foreground, splash logo
assets/fonts/               bundled Archivo + Inter (SIL Open Font License)
tool/                       setup_platforms.sh, patch_platforms.py, build_release.sh
store/                      store listing texts and Play Store images
docs/RELEASE.md             step-by-step publishing guide
.github/workflows/          CI and signed Android release
test/models_test.dart       parsing tests  (flutter test)
```
