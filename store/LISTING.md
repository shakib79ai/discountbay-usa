# Store listing — copy and paste

Everything below is ready to paste into Google Play Console and App Store Connect. Character limits are noted; every field is within them.

Images in this folder:

| File | Where it goes |
| --- | --- |
| `google-play/icon-512.png` | Play Console → Main store listing → App icon (512×512) |
| `google-play/feature-graphic-1024x500.png` | Play Console → Main store listing → Feature graphic |
| Screenshots | Take them from the running app (see "Screenshots" at the end) |

The App Store icon comes from the app build itself (generated from `assets/icon/icon.png`).

---

## Shared details

| Field | Value |
| --- | --- |
| Developer / seller | Best My Flight Inc. (DiscountBay) |
| Website | https://discountbay.com |
| Support URL | https://discountbay.com/contact-us |
| Privacy policy URL | https://discountbay.com/privacy-policy |
| Terms | https://discountbay.com/terms-and-conditions |
| Contact email | info@discountbay.com |
| Contact phone | (646) 389-3812 |
| Address | 1088 Liberty Ave, Brooklyn, NY 11208, USA |
| Category | Shopping (App Store secondary: Lifestyle) |
| Price | Free, no in-app purchases |
| Countries | United States to start |

---

## Google Play

**App name** (30): `DiscountBay: Coupons & Deals`

**Short description** (80): `Verified coupon codes and deals from 10,000+ US stores. Free, no sign-up.`

**Full description** (4,000):

```
Stop paying full price. DiscountBay tracks and re-verifies coupon codes across 10,000+ US stores every day, so the code you tap is one that works at checkout.

HOW IT WORKS
1. Find your store — search 10,000+ brands or browse by category.
2. Tap "Get Code" — the code is copied and the store opens.
3. Paste at checkout — deals with no code apply automatically.

WHAT YOU GET
• Verified codes and deals, checked daily
• Today's top deals, filtered by codes, deals or ending soon
• Store pages with every active offer, best discount and expiry dates
• Hot product deals from verified partner stores
• Save offers and follow your favorite stores — no account needed
• Browse by category: fashion, electronics, home, travel, baby, automotive and more
• Weekly email of the best codes (optional)

FREE, NO SIGN-UP
DiscountBay is free to use. We're supported by our store partners, not by charging shoppers. We never sell your personal information.

DiscountBay may earn a commission when you shop through links in the app, at no extra cost to you.
```

**Tags**: Shopping, Coupons, Deals

**App category**: Shopping · **Contains ads**: No · **In-app purchases**: No

### Data safety form

| Question | Answer |
| --- | --- |
| Does the app collect or share user data? | Yes, collects (email only, optional) |
| Data types collected | Personal info → Email address |
| Collected or shared? | Collected, not shared |
| Required or optional? | Optional (newsletter signup) |
| Purpose | Communications (newsletter) |
| Processed ephemerally? | No |
| Encrypted in transit? | Yes |
| Can users request deletion? | Yes — unsubscribe link in every email, or email info@discountbay.com |

Saved offers and followed stores stay on the device and are never sent to a server, so they are not "collected".

### Content rating (IARC questionnaire)

Category: **All other app types**. Answer **No** to every content question (violence, sexuality, language, controlled substances, gambling, user-generated content, location sharing). Expected rating: **Everyone / PEGI 3**.

### Target audience

Choose **18 and over**. (Picking under-13 groups pulls the app into the Families policy, which it doesn't need.)

---

## App Store (App Store Connect)

**Name** (30): `DiscountBay: Coupons & Deals`

**Subtitle** (30): `Verified codes, checked daily`

**Promotional text** (170): `New verified codes every day from 10,000+ US stores. Tap once to copy a code and open the store.`

**Description**: use the Google Play full description above.

**Keywords** (100, no spaces after commas, no brand names — Apple rejects other companies' trademarks):

```
coupon,coupons,promo code,discount code,deals,savings,voucher,sale,offers,save money,shopping
```

**Category**: Shopping (secondary: Lifestyle) · **Age rating**: answer "None" to every item → **4+**

### App Privacy ("nutrition label")

- Data used to track you: **None**
- Data linked to you: **Contact Info → Email Address**, purpose **Developer's Advertising or Marketing** (newsletter), only if the user subscribes
- Data not linked to you: none

### App Review notes

```
No login is required. All features work without an account.
- Tap any offer, then "Copy code & open store": the code is copied to the clipboard and the store's website opens in Safari.
- Deals without a code open the store directly.
- Saved offers and followed stores are kept on the device.
DiscountBay is an affiliate coupon service: purchases happen on the store's own website, and we may earn a commission. The app has no in-app purchases.
```

Sign-in information: **not required**.

---

## Screenshots

Take them from the app running against the live API (not demo data):

| Store | Size | How many |
| --- | --- | --- |
| App Store — iPhone 6.9" | 1320 × 2868 (iPhone 16 Pro Max simulator) | 3–10 |
| Google Play — phone | e.g. 1080 × 2400 (any modern Android emulator) | 2–8 |

Suggested set, in order: Home (hero + top deals) · Coupon sheet with a code revealed · Store page · Categories · Search results · Saved.

Simulator shortcut: run `flutter run --dart-define=DEMO=false`, then in the iOS Simulator press ⌘S to save a screenshot at full resolution.
