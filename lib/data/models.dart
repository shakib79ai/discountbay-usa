/// Data models. Parsing is deliberately tolerant: each field accepts a few
/// likely key spellings (snake_case / camelCase / nested objects) so the app keeps
/// working if the FastAPI response shape differs slightly from what's assumed here.
/// Adjust the key lists in one place if your schema uses other names.
library;

T? _pick<T>(Map<String, dynamic> j, List<String> keys) {
  for (final k in keys) {
    final v = j[k];
    if (v == null) continue;
    if (v is T) return v;
    if (T == String) return v.toString() as T;
    if (T == int) {
      if (v is num) return v.toInt() as T;
      final parsed = int.tryParse(v.toString());
      if (parsed != null) return parsed as T;
    }
    if (T == bool) {
      if (v is num) return (v != 0) as T;
      final s = v.toString().toLowerCase();
      if (s == 'true' || s == 'false') return (s == 'true') as T;
    }
  }
  return null;
}

Map<String, dynamic>? _obj(Map<String, dynamic> j, String key) {
  final v = j[key];
  return v is Map<String, dynamic> ? v : null;
}

/// Turns relative paths like `/static/logos/x.svg` into absolute URLs.
String? absoluteUrl(String? url, String base) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('http')) return url;
  if (url.startsWith('//')) return 'https:$url';
  return '${base.replaceAll(RegExp(r'/$'), '')}/${url.replaceAll(RegExp(r'^/'), '')}';
}

class Store {
  Store({
    required this.id,
    required this.slug,
    required this.name,
    this.logoUrl,
    this.offerCount = 0,
    this.about,
    this.categoryName,
    this.categorySlug,
    this.websiteUrl,
  });

  final String id;
  final String slug;
  final String name;
  final String? logoUrl;
  final int offerCount;
  final String? about;
  final String? categoryName;
  final String? categorySlug;
  final String? websiteUrl;

  factory Store.fromJson(Map<String, dynamic> j, {String assetBase = ''}) {
    final cat = _obj(j, 'category');
    return Store(
      id: _pick<String>(j, ['id', 'advertiser_id', 'advertiserId']) ?? '',
      slug: _pick<String>(j, ['slug']) ?? '',
      name: _pick<String>(j, ['name', 'advertiser_name', 'title']) ?? 'Store',
      logoUrl: absoluteUrl(_pick<String>(j, ['logo_url', 'logoUrl', 'logo', 'image']), assetBase),
      offerCount: _pick<int>(j, ['offer_count', 'offers_count', 'offerCount', 'active_offers', 'offers']) ?? 0,
      about: _pick<String>(j, ['description', 'about', 'summary']),
      categoryName: cat != null ? _pick<String>(cat, ['name']) : _pick<String>(j, ['category_name', 'primary_category']),
      categorySlug: cat != null ? _pick<String>(cat, ['slug']) : _pick<String>(j, ['category_slug']),
      websiteUrl: _pick<String>(j, ['website_url', 'website', 'url', 'program_url', 'affiliate_url']),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'slug': slug,
        'name': name,
        'logo_url': logoUrl,
        'offer_count': offerCount,
        'category_name': categoryName,
        'category_slug': categorySlug,
        'website_url': websiteUrl,
      };
}

class StoreCategory {
  StoreCategory({required this.slug, required this.name, this.storeCount = 0});

  final String slug;
  final String name;
  final int storeCount;

  factory StoreCategory.fromJson(Map<String, dynamic> j) => StoreCategory(
        slug: _pick<String>(j, ['slug']) ?? '',
        name: _pick<String>(j, ['name', 'title']) ?? '',
        storeCount: _pick<int>(j, ['store_count', 'stores_count', 'storeCount', 'count']) ?? 0,
      );
}

enum OfferKind { code, deal }

class Offer {
  Offer({
    required this.id,
    required this.title,
    required this.storeName,
    required this.storeSlug,
    this.storeLogo,
    this.description,
    this.code,
    this.url,
    this.imageUrl,
    this.discountLabel,
    this.expiresAt,
    this.verified = true,
    this.expired = false,
  });

  final String id;
  final String title;
  final String? description;
  final String storeName;
  final String storeSlug;
  final String? storeLogo;

  /// Coupon code; null/empty means "no code needed" (a deal).
  final String? code;

  /// Affiliate / click-through URL.
  final String? url;

  /// Banner image for product deals.
  final String? imageUrl;

  /// e.g. "20% OFF", "$10 OFF". Null renders as "DEAL".
  final String? discountLabel;
  final DateTime? expiresAt;
  final bool verified;
  final bool expired;

  OfferKind get kind => (code != null && code!.trim().isNotEmpty) ? OfferKind.code : OfferKind.deal;

  /// Splits "20% OFF" into ("20%", "OFF") for the stamp widget.
  (String, String) get stampParts {
    final l = (discountLabel ?? '').trim();
    if (l.isEmpty) return ('DEAL', '');
    final m = RegExp(r'^(.*?)\s*(OFF)$', caseSensitive: false).firstMatch(l);
    if (m != null) return (m.group(1)!, 'OFF');
    return (l, '');
  }

  factory Offer.fromJson(Map<String, dynamic> j, {String assetBase = ''}) {
    final store = _obj(j, 'store') ?? _obj(j, 'advertiser') ?? const {};
    final exp = _pick<String>(j, ['end_date', 'expires_at', 'expiry', 'expiration_date', 'endDate']);
    final pct = _pick<int>(j, ['discount_percent', 'percent_off', 'pct']);
    final amt = _pick<String>(j, ['discount_amount', 'amount_off']);
    String? label = _pick<String>(j, ['discount_label', 'discount', 'badge', 'label']);
    if (label == null && pct != null && pct > 0) label = '$pct% OFF';
    if (label == null && amt != null && amt.isNotEmpty) label = '\$$amt OFF';
    final expiresAt = exp == null ? null : DateTime.tryParse(exp);
    return Offer(
      id: _pick<String>(j, ['id', 'link_id', 'linkId']) ?? '',
      title: _pick<String>(j, ['title', 'name', 'link_name']) ?? '',
      description: _pick<String>(j, ['description', 'details']),
      storeName: _pick<String>(store, ['name', 'advertiser_name']) ??
          _pick<String>(j, ['store_name', 'advertiser_name', 'storeName']) ??
          '',
      storeSlug: _pick<String>(store, ['slug']) ?? _pick<String>(j, ['store_slug', 'storeSlug']) ?? '',
      storeLogo: absoluteUrl(
        _pick<String>(store, ['logo_url', 'logo']) ?? _pick<String>(j, ['store_logo', 'logo_url']),
        assetBase,
      ),
      code: _pick<String>(j, ['code', 'coupon_code', 'couponCode']),
      url: _pick<String>(j, ['click_url', 'affiliate_url', 'url', 'link', 'tracking_url']),
      imageUrl: absoluteUrl(_pick<String>(j, ['image_url', 'banner_url', 'image', 'imageUrl']), assetBase),
      discountLabel: label,
      expiresAt: expiresAt,
      verified: _pick<bool>(j, ['verified', 'is_verified']) ?? true,
      expired: _pick<bool>(j, ['expired', 'is_expired']) ??
          (expiresAt != null && expiresAt.isBefore(DateTime.now())),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'store_name': storeName,
        'store_slug': storeSlug,
        'store_logo': storeLogo,
        'code': code,
        'url': url,
        'image_url': imageUrl,
        'discount_label': discountLabel,
        'end_date': expiresAt?.toIso8601String(),
        'verified': verified,
      };
}

/// A page of results.
class Paged<T> {
  Paged(this.items, {this.total, this.hasMore = false});
  final List<T> items;
  final int? total;
  final bool hasMore;
}

enum OfferFilter { all, codes, deals, endingSoon }

enum OfferSort { recommended, biggestSavings, newest, endingSoon }
