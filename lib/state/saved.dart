import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/models.dart';

/// Saved offers + followed stores, kept on-device (no account needed — same as the website's "Saved").
class SavedState extends ChangeNotifier {
  static const _offersKey = 'saved_offers_v1';
  static const _storesKey = 'followed_stores_v1';

  final Map<String, Offer> _offers = {};
  final Map<String, Store> _stores = {};
  SharedPreferences? _prefs;

  List<Offer> get offers => _offers.values.toList().reversed.toList();
  List<Store> get stores => _stores.values.toList().reversed.toList();

  bool isSaved(Offer o) => _offers.containsKey(_offerKey(o));
  bool isFollowing(String storeSlug) => _stores.containsKey(storeSlug);

  String _offerKey(Offer o) => o.id.isNotEmpty ? o.id : '${o.storeSlug}|${o.title}';

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    try {
      for (final s in _prefs!.getStringList(_offersKey) ?? const <String>[]) {
        final o = Offer.fromJson(jsonDecode(s) as Map<String, dynamic>);
        _offers[_offerKey(o)] = o;
      }
      for (final s in _prefs!.getStringList(_storesKey) ?? const <String>[]) {
        final st = Store.fromJson(jsonDecode(s) as Map<String, dynamic>);
        _stores[st.slug] = st;
      }
    } catch (_) {
      // Corrupt prefs — start clean rather than crash.
      _offers.clear();
      _stores.clear();
    }
    notifyListeners();
  }

  void toggleOffer(Offer o) {
    final k = _offerKey(o);
    if (_offers.remove(k) == null) _offers[k] = o;
    _persist();
  }

  void toggleStore(Store s) {
    if (_stores.remove(s.slug) == null) _stores[s.slug] = s;
    _persist();
  }

  void _persist() {
    notifyListeners();
    _prefs?.setStringList(_offersKey, _offers.values.map((o) => jsonEncode(o.toJson())).toList());
    _prefs?.setStringList(_storesKey, _stores.values.map((s) => jsonEncode(s.toJson())).toList());
  }
}
