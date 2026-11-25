import 'package:flutter/material.dart';

import '../data/models.dart';

/// How a store (or offer) looks in the store-front design: its brand colour, initials,
/// tile style, cover photo and site category.
///
/// The API does not send brand colours, taglines or covers yet, so they are worked out
/// here from the store name and category. When the API adds `brand_color`, `tagline` and
/// `cover_url`, read them in [StoreLook.of] first and keep these as the fallback.

/// The 10 site categories used across the app (same as the website).
class SiteCategory {
  const SiteCategory(this.key, this.label, this.color, this.photos, this.keywords);

  final String key;
  final String label;
  final Color color;

  /// Bundled photos in assets/photos, first one = the category's main photo.
  final List<String> photos;

  /// Words in an API category name / store name / offer title that point here.
  final List<String> keywords;

  String get photo => photoPath(photos.first);

  static String photoPath(String name) => 'assets/photos/$name.jpg';

  static const all = <SiteCategory>[
    SiteCategory('home', 'Home & Garden', Color(0xFF8A5A2B), ['furniture', 'bedding', 'cookware', 'blender', 'roaster', 'village'],
        ['home', 'garden', 'kitchen', 'cook', 'furniture', 'bed', 'mattress', 'sofa', 'blind', 'lighting', 'shelving', 'appliance', 'all-clad', 't-fal', 'rowenta', 'krups', 'duvet', 'sleep']),
    SiteCategory('electronics', 'Computer & Electronics', Color(0xFF1E3A8A), ['electronics', 'samsung', 'camera', 'services'],
        ['computer', 'electronic', 'laptop', 'phone', 'tablet', 'headphone', 'speaker', 'camera', 'tv', 'gaming', 'monitor', 'hp', 'sony', 'samsung', 'tech']),
    SiteCategory('beauty', 'Beauty', Color(0xFF9D174D), ['beauty', 'jewelry', 'health'],
        ['beauty', 'cosmetic', 'skincare', 'makeup', 'fragrance', 'perfume', 'hair', 'wig', 'lancome', 'nail']),
    SiteCategory('fashion', 'Fashion & accessories', Color(0xFF3F3F46), ['suits', 'sweater', 'crocs', 'watch', 'jewelry'],
        ['apparel', 'fashion', 'clothing', 'shoe', 'boot', 'watch', 'jewel', 'accessor', 'men', 'woman', 'women', 'kids', 'sweater', 'suit', 'glasses']),
    SiteCategory('auto', 'Automotive', Color(0xFF374151), ['auto', 'camera', 'seasonal'],
        ['auto', 'car', 'moto', 'tire', 'truck', 'dash cam', 'off-road', 'vehicle']),
    SiteCategory('health', 'Health & Wellness', Color(0xFF166534), ['health', 'beauty', 'pets'],
        ['health', 'wellness', 'vitamin', 'supplement', 'protein', 'fitness', 'lab', 'dna', 'baby']),
    SiteCategory('pets', 'Pets', Color(0xFF92400E), ['pets', 'health', 'seasonal'], ['pet', 'dog', 'cat', 'vet', 'paws']),
    SiteCategory('travel', 'Travel & outdoor', Color(0xFF0E7490), ['travel', 'seasonal', 'auto'],
        ['travel', 'hotel', 'flight', 'tour', 'booking', 'vacation', 'camp', 'outdoor', 'getaway', 'stay']),
    SiteCategory('services', 'Software & services', Color(0xFF4338CA), ['services', 'electronics', 'samsung'],
        ['software', 'service', 'domain', 'hosting', 'website', 'online', 'internet', 'phone service', 'tax', 'credit', 'insurance', 'telecom', 'godaddy']),
    SiteCategory('gifts', 'Gifts & holiday', Color(0xFF9A3412), ['gifts', 'blackfriday', 'village'],
        ['gift', 'holiday', 'christmas', 'black friday', 'flower', 'coffee', 'department', 'deal', 'sale']),
  ];

  static final _re = <String, RegExp>{};

  /// Short keywords must match a whole word ("car" not "card"); longer ones match a word start.
  static RegExp _word(String k) => _re.putIfAbsent(
      k, () => RegExp(k.length <= 3 ? '\\b${RegExp.escape(k)}\\b' : '\\b${RegExp.escape(k)}'));

  static SiteCategory byKey(String key) => all.firstWhere((c) => c.key == key, orElse: () => all.last);

  /// Best guess from any text (API category name, store name, offer title).
  static SiteCategory guess(Iterable<String?> texts) {
    final t = texts.whereType<String>().join(' ').toLowerCase();
    if (t.isEmpty) return byKey('gifts');
    var best = all.last;
    var bestHits = 0;
    for (final c in all) {
      final hits = c.keywords.where((k) => _word(k).hasMatch(t)).length;
      if (hits > bestHits) {
        best = c;
        bestHits = hits;
      }
    }
    return best;
  }
}

/// 24 well-separated brand colours, so stores side by side never match.
const _palette = <Color>[
  Color(0xFFB91C1C), Color(0xFF0369A1), Color(0xFF15803D), Color(0xFF7E22CE), Color(0xFFC2410C), Color(0xFF0F766E),
  Color(0xFFBE185D), Color(0xFF1D4ED8), Color(0xFFA16207), Color(0xFF4338CA), Color(0xFF047857), Color(0xFF9F1239),
  Color(0xFF0E7490), Color(0xFF6D28D9), Color(0xFFB45309), Color(0xFF334155), Color(0xFFA21CAF), Color(0xFF4D7C0F),
  Color(0xFF1E40AF), Color(0xFF7C2D12), Color(0xFF0B5563), Color(0xFF5B21B6), Color(0xFF065F46), Color(0xFF92400E),
];

/// Real brand colours for the best-known stores (slug → colour, button text colour, photo).
const _known = <String, (Color, Color, String)>{
  'amazon': (Color(0xFF232F3E), Color(0xFF12203A), 'store_cover'),
  'macy-s': (Color(0xFFC8102E), Colors.white, 'blackfriday'),
  'ebay': (Color(0xFF0654BA), Colors.white, 'samsung'),
};

/// Amazon's buttons are orange with dark text; everyone else uses their brand colour.
const _knownButton = <String, Color>{'amazon': Color(0xFFFFA41C)};

int _hash(String s) {
  var h = 7;
  for (final c in s.codeUnits) {
    h = (h * 31 + c) & 0x7fffffff;
  }
  return h;
}

Color shade(Color c, double f) => Color.fromARGB(
    255, ((c.r * 255) * f).round().clamp(0, 255), ((c.g * 255) * f).round().clamp(0, 255), ((c.b * 255) * f).round().clamp(0, 255));

/// Two-letter initials: "Lighting New York" → "LN", "GARVEE" → "G".
String initials(String name) {
  if (name.toLowerCase() == 'ebay') return 'e';
  const skip = {'the', 'and', 'of', 'com', 'us', 'na', 'global', 'inc', 'limited', 'north', 'america'};
  final words = name
      .replaceAll(RegExp(r"[’'.]"), '')
      .split(RegExp(r'[^A-Za-z0-9]+'))
      .where((w) => w.isNotEmpty && !skip.contains(w.toLowerCase()))
      .toList();
  if (words.isEmpty) return name.isEmpty ? '?' : name[0].toUpperCase();
  if (words.length == 1) return words.first[0].toUpperCase();
  return (words[0][0] + words[1][0]).toUpperCase();
}

class StoreLook {
  StoreLook._({
    required this.brand,
    required this.button,
    required this.buttonText,
    required this.initials,
    required this.category,
    required this.cover,
    required this.thumbs,
    required this.roundTile,
    required this.filledTile,
  });

  final Color brand;
  final Color button;
  final Color buttonText;
  final String initials;
  final SiteCategory category;

  /// Asset path of the cover photo (used when the store has no banner from the API).
  final String cover;

  /// Three asset paths for the small photo row on store cards.
  final List<String> thumbs;

  final bool roundTile;
  final bool filledTile;

  LinearGradient get gradient => LinearGradient(colors: [shade(brand, 0.45), brand]);

  Color get tileBg => filledTile ? brand : Colors.white;
  Color get tileFg => filledTile ? Colors.white : brand;

  static final _cache = <String, StoreLook>{};

  static StoreLook of(Store s) => forName(s.name, slug: s.slug, categoryText: s.categoryName);

  static StoreLook forOffer(Offer o) => forName(o.storeName, slug: o.storeSlug, categoryText: o.title);

  static StoreLook forName(String name, {String slug = '', String? categoryText}) {
    final key = slug.isNotEmpty ? slug : name;
    return _cache.putIfAbsent(key, () {
      final h = _hash(name);
      final cat = SiteCategory.guess([categoryText, name]);
      final known = _known[slug];
      final brand = known?.$1 ?? _palette[h % _palette.length];
      final pool = cat.photos;
      final coverName = known?.$3 ?? pool[(h >> 3) % pool.length];
      final rest = [...pool, ...SiteCategory.all.expand((c) => c.photos)].toSet().where((p) => p != coverName).toList();
      final k = h % rest.length;
      return StoreLook._(
        brand: brand,
        button: _knownButton[slug] ?? brand,
        buttonText: known?.$2 ?? Colors.white,
        initials: initials(name),
        category: cat,
        cover: SiteCategory.photoPath(coverName),
        thumbs: [rest[k], rest[(k + 2) % rest.length], rest[(k + 5) % rest.length]].map(SiteCategory.photoPath).toList(),
        roundTile: (h >> 5) % 2 == 0,
        filledTile: known == null && (h >> 6) % 2 == 0,
      );
    });
  }
}

/// Discount as a number (for filters / sorting): "70% OFF" → 70, otherwise 0.
int savePercent(Offer o) {
  final m = RegExp(r'(\d{1,3})\s*%').firstMatch('${o.discountLabel ?? ''} ${o.title}');
  final v = m == null ? 0 : int.parse(m.group(1)!);
  return v > 100 ? 100 : v;
}

/// Short badge for photo cards: "UP TO 70% OFF", "$50 OFF", "CODE", "DEAL".
String offerBadge(Offer o) {
  final l = (o.discountLabel ?? '').trim().toUpperCase();
  if (l.isNotEmpty) return RegExp(r'^\d').hasMatch(l) && o.title.toLowerCase().contains('up to') ? 'UP TO $l' : l;
  final p = savePercent(o);
  if (p > 0) return o.title.toLowerCase().contains('up to') ? 'UP TO $p% OFF' : '$p% OFF';
  return o.kind == OfferKind.code ? 'CODE' : 'DEAL';
}

/// Big red value on cards: "70% off", "$29.99", "Deal".
String offerValue(Offer o) {
  final price = RegExp(r'\$\d[\d,]*(\.\d{2})?').firstMatch(o.title);
  final p = savePercent(o);
  if (p > 0) return '$p% off';
  final l = (o.discountLabel ?? '').trim();
  if (l.isNotEmpty) return l.toLowerCase();
  if (price != null) return price.group(0)!;
  return o.kind == OfferKind.code ? 'Code' : 'Deal';
}

/// Fallback photo for an offer that has no image from the feed.
String offerPhoto(Offer o) {
  final cat = SiteCategory.guess([o.title, o.description, o.storeName]);
  final h = _hash(o.id.isEmpty ? o.title : o.id);
  return SiteCategory.photoPath(cat.photos[h % cat.photos.length]);
}
