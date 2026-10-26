/// Backend configuration. Override at build time, e.g.
///   flutter run --dart-define=API_BASE=https://api.discountbay.com --dart-define=DEMO=false
class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment('API_BASE', defaultValue: 'https://api.discountbay.com');

  /// Website, used for legal pages, account and sharing links.
  static const siteUrl = String.fromEnvironment('SITE_URL', defaultValue: 'https://discountbay.com');

  /// true = bundled sample data (no network). Default is true until the
  /// endpoint paths below are confirmed against the API's Postman collection.
  static const demo = bool.fromEnvironment('DEMO', defaultValue: true);

  static const timeout = Duration(seconds: 15);
}

/// ALL endpoint paths live here. They follow the FastAPI conventions used by the
/// website; confirm each against the Postman collection / `GET /openapi.json`
/// and edit here only — nothing else in the app hard-codes a path.
class Endpoints {
  Endpoints._();

  static const prefix = '/api';

  static const stores = '$prefix/stores'; // ?search=&letter=&page=&limit=
  static const popularStores = '$prefix/stores/popular';
  static String store(String slug) => '$prefix/stores/$slug';
  static String storeOffers(String slug) => '$prefix/stores/$slug/offers'; // ?sort=
  static String similarStores(String slug) => '$prefix/stores/$slug/similar';

  static const categories = '$prefix/categories';
  static String categoryStores(String slug) => '$prefix/categories/$slug/stores';
  static String categoryOffers(String slug) => '$prefix/categories/$slug/offers';

  static const topOffers = '$prefix/offers/top'; // ?type=code|deal&ending_soon=true&page=
  static const hotDeals = '$prefix/offers/banners';

  static const search = '$prefix/search'; // ?q=
  static const newsletter = '$prefix/newsletter/subscribe'; // POST {email}
}
