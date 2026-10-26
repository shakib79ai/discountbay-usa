import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'models.dart';
import 'repository.dart';

class ApiException implements Exception {
  ApiException(this.message, [this.status]);
  final String message;
  final int? status;
  @override
  String toString() => message;
}

class ApiRepository implements Repository {
  ApiRepository({http.Client? client, String? baseUrl})
      : _client = client ?? http.Client(),
        _base = baseUrl ?? ApiConfig.baseUrl;

  final http.Client _client;
  final String _base;

  // ---------------------------------------------------------------- plumbing

  Future<dynamic> _get(String path, [Map<String, String?> query = const {}]) async {
    final q = {for (final e in query.entries) if (e.value != null && e.value!.isNotEmpty) e.key: e.value!};
    final uri = Uri.parse('$_base$path').replace(queryParameters: q.isEmpty ? null : q);
    final res = await _client.get(uri, headers: const {'Accept': 'application/json'}).timeout(ApiConfig.timeout);
    if (res.statusCode == 404) throw ApiException('Not found', 404);
    if (res.statusCode >= 400) throw ApiException('Server error (${res.statusCode})', res.statusCode);
    return jsonDecode(utf8.decode(res.bodyBytes));
  }

  /// Accepts a bare list or the common envelopes {items|data|results: [...]}.
  List<Map<String, dynamic>> _list(dynamic body, [List<String> keys = const ['items', 'data', 'results']]) {
    if (body is List) return body.whereType<Map<String, dynamic>>().toList();
    if (body is Map<String, dynamic>) {
      for (final k in keys) {
        final v = body[k];
        if (v is List) return v.whereType<Map<String, dynamic>>().toList();
      }
    }
    return const [];
  }

  int? _total(dynamic body) => body is Map<String, dynamic> ? (body['total'] as num?)?.toInt() : null;

  Store _store(Map<String, dynamic> j) => Store.fromJson(j, assetBase: _base);
  Offer _offer(Map<String, dynamic> j) => Offer.fromJson(j, assetBase: _base);

  static const _pageSize = 30;

  String _sort(OfferSort s) => switch (s) {
        OfferSort.recommended => 'recommended',
        OfferSort.biggestSavings => 'savings',
        OfferSort.newest => 'newest',
        OfferSort.endingSoon => 'ending_soon',
      };

  // ---------------------------------------------------------------- stores

  @override
  Future<List<Store>> popularStores() async => _list(await _get(Endpoints.popularStores)).map(_store).toList();

  @override
  Future<Paged<Store>> stores({String? query, String? letter, int page = 1}) async {
    final body = await _get(Endpoints.stores, {
      'search': query,
      'letter': letter,
      'page': '$page',
      'limit': '$_pageSize',
    });
    final items = _list(body).map(_store).toList();
    final total = _total(body);
    return Paged(items, total: total, hasMore: total != null ? page * _pageSize < total : items.length == _pageSize);
  }

  @override
  Future<Store?> store(String slug) async {
    try {
      final body = await _get(Endpoints.store(slug));
      final j = body is Map<String, dynamic> ? (body['store'] ?? body['data'] ?? body) : null;
      return j is Map<String, dynamic> ? _store(j) : null;
    } on ApiException catch (e) {
      if (e.status == 404) return null;
      rethrow;
    }
  }

  @override
  Future<List<Offer>> storeOffers(String slug, {OfferSort sort = OfferSort.recommended}) async =>
      _list(await _get(Endpoints.storeOffers(slug), {'sort': _sort(sort)}), ['items', 'offers', 'data', 'results'])
          .map(_offer)
          .toList();

  @override
  Future<List<Store>> similarStores(String slug) async {
    try {
      return _list(await _get(Endpoints.similarStores(slug))).map(_store).toList();
    } catch (_) {
      return const []; // non-critical section
    }
  }

  // ---------------------------------------------------------------- categories

  @override
  Future<List<StoreCategory>> categories() async => _list(await _get(Endpoints.categories)).map(StoreCategory.fromJson).toList();

  @override
  Future<List<Store>> categoryStores(String slug) async =>
      _list(await _get(Endpoints.categoryStores(slug))).map(_store).toList();

  @override
  Future<List<Offer>> categoryOffers(String slug) async {
    try {
      return _list(await _get(Endpoints.categoryOffers(slug))).map(_offer).toList();
    } catch (_) {
      return const [];
    }
  }

  // ---------------------------------------------------------------- offers

  @override
  Future<Paged<Offer>> topOffers({OfferFilter filter = OfferFilter.all, int page = 1}) async {
    final body = await _get(Endpoints.topOffers, {
      'type': switch (filter) {
        OfferFilter.codes => 'code',
        OfferFilter.deals => 'deal',
        _ => null,
      },
      'ending_soon': filter == OfferFilter.endingSoon ? 'true' : null,
      'page': '$page',
      'limit': '$_pageSize',
    });
    final items = _list(body).map(_offer).toList();
    final total = _total(body);
    return Paged(items, total: total, hasMore: total != null ? page * _pageSize < total : items.length == _pageSize);
  }

  @override
  Future<List<Offer>> hotProductDeals() async => _list(await _get(Endpoints.hotDeals)).map(_offer).toList();

  // ---------------------------------------------------------------- search

  @override
  Future<({List<Store> stores, List<Offer> offers})> search(String query) async {
    final body = await _get(Endpoints.search, {'q': query});
    if (body is Map<String, dynamic>) {
      return (
        stores: _list(body, ['stores']).map(_store).toList(),
        offers: _list(body, ['offers', 'coupons']).map(_offer).toList(),
      );
    }
    return (stores: _list(body).map(_store).toList(), offers: <Offer>[]);
  }

  // ---------------------------------------------------------------- newsletter

  @override
  Future<void> subscribeNewsletter(String email) async {
    final res = await _client
        .post(
          Uri.parse('$_base${Endpoints.newsletter}'),
          headers: const {'Content-Type': 'application/json', 'Accept': 'application/json'},
          body: jsonEncode({'email': email}),
        )
        .timeout(ApiConfig.timeout);
    if (res.statusCode >= 400) throw ApiException('Could not subscribe (${res.statusCode})', res.statusCode);
  }
}
