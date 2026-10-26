import 'models.dart';

/// Everything the UI needs from the backend. Two implementations:
///  * [ApiRepository]  — talks to the live FastAPI backend (api.discountbay.com)
///  * [DemoRepository] — bundled sample data, so the app runs with no backend
abstract class Repository {
  Future<List<Store>> popularStores();
  Future<Paged<Store>> stores({String? query, String? letter, int page = 1});
  Future<Store?> store(String slug);
  Future<List<Offer>> storeOffers(String slug, {OfferSort sort = OfferSort.recommended});
  Future<List<Store>> similarStores(String slug);

  Future<List<StoreCategory>> categories();
  Future<List<Store>> categoryStores(String slug);
  Future<List<Offer>> categoryOffers(String slug);

  Future<Paged<Offer>> topOffers({OfferFilter filter = OfferFilter.all, int page = 1});
  Future<List<Offer>> hotProductDeals();

  Future<({List<Store> stores, List<Offer> offers})> search(String query);

  Future<void> subscribeNewsletter(String email);
}
