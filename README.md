# DiscountBay — iOS & Android app (Flutter)

Native mobile app for [discountbay.com](https://discountbay.com), built in Flutter from one codebase and styled with the website's design system and the DiscountBay logo.

**Publishing to Google Play and the App Store:** follow [`docs/RELEASE.md`](docs/RELEASE.md). Store texts, data-safety answers and store images are in [`store/`](store/LISTING.md).

## Design (2026 store-front redesign — same as the website)

Light pages, photo cards, and every store in its own brand colour, so each store page feels like the store's own little shop.

| Token | Value | Used for |
| --- | --- | --- |
| ink | `#12203A` | Text, navy headers, default buttons |
| bg | `#F4F6F9` | Page background |
| border | `#E1E7EF` | Cards, inputs |
| orange | `#E25F12` | DiscountBay accent, links |
| sale | `#E2453C` | "UP TO 70% OFF" badges |
| price | `#B42318` | Discount / price text |
| verified | `#1F7A57` | "✓ Verified" |
| Fonts | Archivo Black · Archivo · Inter | Headlines · headings · body |

- **Tokens:** `lib/theme/tokens.dart`.
- **Store identity:** `lib/theme/identity.dart` gives every store a brand colour (real colours for Amazon, Macy's, eBay; a 24-colour palette for the rest), two-letter initials, a tile style, a cover photo and one of 10 site categories. When the API adds `brand_color`, `tagline` and `cover_url`, read them in `StoreLook.of` first.
- **Building blocks:** `lib/widgets/shop.dart` — deal card, deal row, store cards, category tiles, navy header, search box, pills, buttons.
- **Photos:** offers use `image_url` from the API; when it is empty, a category photo from `assets/photos/` is shown. These bundled photos are small previews — replace them with full-size images (same file names) before release.

Logo: the official DiscountBay artwork in `assets/brand/`, shown with `lib/widgets/brand_logo.dart`. App icon and splash are generated from `assets/icon/`.

## Screens

- **Home** — navy header with logo and search, hero slider of the biggest current offers (each in its store's colours), category photos, featured stores, Today's top deals (All / Codes / Deals / Ending soon) as photo cards, hot product deals, FAQ, deal alerts.
- **Stores** — search, A–Z letters, featured stores, then every store as a store card (cover, tile, offer count), infinite list.
- **Store page** — brand-colour cover with photo, logo tile, offer count, Follow + Visit store, search inside the store, **filter sheet** (offer type, discount, ends within 7 days, sort), offers as product cards with Load more, recently expired, how it works, about, similar stores.
- **Categories** — photo tile per category with search → **category page** (photo hero in the category colour, top deals, every store in it with search).
- **Top deals** — search, type pills, sort toggle, photo cards, infinite scroll.
- **Search** — stores and deals as you type.
- **Saved** — Deals and Stores tabs; saved deals as photo cards with an "ends today" banner, followed stores as store cards. Kept on the phone.
- **Account** — sign up / log in (website for now), counts, stores you follow, links, contact, socials, FAQ.
- **Deal sheet** — photo, store, title, value, facts (verified · code/deal · end date); codes are copied with one tap and the store opens, deals open the store directly, in the store's own button colour.

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

## Images from the image pack

The app reads photo URLs from the API and falls back to the bundled photos in `assets/photos/`
when a field is empty, so new images need no app release:

| API field | Used for |
|---|---|
| store `cover_image_url` | store page cover; cards use the `-card.webp` version |
| category `image_url` | category circles, category tiles and the category page header |
| offer `image_url` | deal cards and the deal sheet |

The images, their manifest and the offer-matching script are delivered separately as the
DiscountBay image pack (see its README).
