import 'models.dart';
import 'repository.dart';

const _logo = 'https://api.discountbay.com/static/logos';
const _banner = 'https://api.discountbay.com/static/banners';

/// Sample data taken from the live homepage so the app looks real with no backend.
class DemoRepository implements Repository {
  DateTime _in(int days) => DateTime.now().add(Duration(days: days));

  late final List<Store> _stores = [
    Store(id: '2898', slug: 'amazon', name: 'Amazon', logoUrl: '$_logo/advertiser-2898-64ec421a.svg', offerCount: 6, categoryName: 'Department Stores', categorySlug: 'department-stores', websiteUrl: 'https://www.amazon.com', about: 'The everything store — electronics, home, fashion, groceries and more, with fast delivery for Prime members.'),
    Store(id: '2874', slug: 'ebay', name: 'eBay', logoUrl: '$_logo/advertiser-2874-571dd415.svg', offerCount: 6, categoryName: 'Department Stores', categorySlug: 'department-stores', websiteUrl: 'https://www.ebay.com', about: 'Marketplace for new and pre-owned everything, from collectibles to car parts.'),
    Store(id: '21', slug: 'aliexpress-global', name: 'AliExpress - Global', logoUrl: '$_logo/advertiser-21-caa12a34.svg', offerCount: 7, categoryName: 'Department Stores', categorySlug: 'department-stores', websiteUrl: 'https://www.aliexpress.com'),
    Store(id: '2673', slug: 'macy-s', name: "Macy's", logoUrl: '$_logo/advertiser-2673-4f7bf893.svg', offerCount: 518, categoryName: "Apparel - Woman's", categorySlug: 'apparel-woman-s', websiteUrl: 'https://www.macys.com', about: "America's iconic department store since 1858 — fashion, beauty, home and the famous One Day Sale."),
    Store(id: '824', slug: 'booking-com-north-america', name: 'Booking.com North America', logoUrl: '$_logo/advertiser-824-62208ebe.svg', offerCount: 5, categoryName: 'Travel', categorySlug: 'travel', websiteUrl: 'https://www.booking.com'),
    Store(id: '2440', slug: 'temu', name: 'Temu', logoUrl: '$_logo/advertiser-2440-915820ed.svg', offerCount: 4, categoryName: 'Department Stores', categorySlug: 'department-stores', websiteUrl: 'https://www.temu.com'),
    Store(id: '424', slug: 'frp-moto-affiliate', name: 'FRP Moto Affiliate', logoUrl: '$_logo/advertiser-424-bcd26cac.png', offerCount: 18, categoryName: 'Automotive', categorySlug: 'automotive'),
    Store(id: '1701', slug: 'hp-us', name: 'HP US', logoUrl: '$_logo/advertiser-1701-d33e7326.svg', offerCount: 15, categoryName: 'Computers & Electronics', categorySlug: 'computers-electronics', websiteUrl: 'https://www.hp.com'),
    Store(id: '2281', slug: 'godaddy-com', name: 'GoDaddy.com', logoUrl: '$_logo/advertiser-2281-8a058309.svg', offerCount: 54, categoryName: 'Computers & Electronics', categorySlug: 'computers-electronics', websiteUrl: 'https://www.godaddy.com'),
    Store(id: '441', slug: 'sony', name: 'Sony', logoUrl: '$_logo/advertiser-441-65eba318.svg', offerCount: 3, categoryName: 'Computers & Electronics', categorySlug: 'computers-electronics'),
    Store(id: '1265', slug: 'vaio-us', name: 'VAIO US', logoUrl: '$_logo/advertiser-1265-1099fb81.svg', offerCount: 1, categoryName: 'Computers & Electronics', categorySlug: 'computers-electronics'),
    Store(id: '746', slug: 'big-bus-tours', name: 'Big Bus Tours', logoUrl: '$_logo/advertiser-746-609b1423.svg', offerCount: 7, categoryName: 'Travel', categorySlug: 'travel'),
    Store(id: '2918', slug: 'giftcards-com', name: 'Giftcards.com', logoUrl: '$_logo/advertiser-2918-b6024dd0.svg', offerCount: 4, categoryName: 'Gifts', categorySlug: 'gifts'),
    Store(id: '1823', slug: 'nanit', name: 'Nanit', logoUrl: '$_logo/advertiser-1823-b96e0ad5.png', offerCount: 3, categoryName: 'Baby Products', categorySlug: 'baby-products'),
    Store(id: '27', slug: 'home-cook-groupe-seb-brands-all-clad-krups-rowenta-t-fal', name: 'Home & Cook Groupe SEB Brands', logoUrl: '$_logo/advertiser-27-a3dde950.svg', offerCount: 12, categoryName: 'Home & Garden', categorySlug: 'home-garden'),
  ];

  final List<StoreCategory> _categories = [
    StoreCategory(slug: 'accessories', name: 'Accessories', storeCount: 214),
    StoreCategory(slug: 'apparel-babies-kids', name: 'Apparel - Babies & Kids', storeCount: 96),
    StoreCategory(slug: 'apparel-men-s', name: "Apparel - Men's", storeCount: 188),
    StoreCategory(slug: 'apparel-woman-s', name: "Apparel - Woman's", storeCount: 341),
    StoreCategory(slug: 'art-photo-music', name: 'Art/Photo/Music', storeCount: 57),
    StoreCategory(slug: 'arts-crafts-sewing', name: 'Arts, Crafts & Sewing', storeCount: 44),
    StoreCategory(slug: 'automotive', name: 'Automotive', storeCount: 73),
    StoreCategory(slug: 'baby-products', name: 'Baby Products', storeCount: 61),
    StoreCategory(slug: 'computers-electronics', name: 'Computers & Electronics', storeCount: 402),
    StoreCategory(slug: 'department-stores', name: 'Department Stores', storeCount: 38),
    StoreCategory(slug: 'gifts', name: 'Gifts', storeCount: 82),
    StoreCategory(slug: 'home-garden', name: 'Home & Garden', storeCount: 290),
    StoreCategory(slug: 'travel', name: 'Travel', storeCount: 167),
  ];

  Store _s(String slug) => _stores.firstWhere((s) => s.slug == slug);

  Offer _o(String id, String slug, String title,
      {String? code, String? label, int days = 7, String? desc, String? image, String? url}) {
    final s = _s(slug);
    return Offer(
      id: id,
      title: title,
      description: desc,
      storeName: s.name,
      storeSlug: s.slug,
      storeLogo: s.logoUrl,
      code: code,
      discountLabel: label,
      expiresAt: _in(days),
      imageUrl: image,
      url: url ?? s.websiteUrl,
    );
  }

  late final List<Offer> _offers = [
    _o('1', 'giftcards-com', 'No Tricks. Just Treats. Get a bonus gift card free on select offers', days: 7),
    _o('2', 'home-cook-groupe-seb-brands-all-clad-krups-rowenta-t-fal', 'Rowenta selected steam stations — up to \$100 off', label: '\$100 OFF', days: 10),
    _o('3', 'nanit', '20% off Nanit smart baby monitors + free Cammies on orders \$200+', label: '20% OFF', days: 10),
    _o('4', 'macy-s', 'Hotel Collection Arcadia duvet cover sets', label: '60% OFF', days: 1),
    _o('5', 'giftcards-com', 'Buy select gift cards and get a bonus gift card free', days: 7),
    _o('6', 'home-cook-groupe-seb-brands-all-clad-krups-rowenta-t-fal', 'Rowenta selected steam irons — up to \$50 off', label: '\$50 OFF', days: 10),
    _o('7', 'godaddy-com', 'New .com domains for your first year', code: 'DEMOCOM1', label: '30% OFF', days: 3),
    _o('8', 'hp-us', 'Extra savings on select laptops & desktops', code: 'DEMOHP15', label: '15% OFF', days: 12),
    _o('9', 'amazon', "Today's deals across electronics & home", days: 2),
    _o('10', 'temu', 'New-user bundle savings on your first order', label: '40% OFF', days: 5),
    _o('11', 'booking-com-north-america', 'Getaway deals — save on stays across North America', label: '15% OFF', days: 20),
    _o('12', 'big-bus-tours', 'Hop-on hop-off city tours — book online and save', code: 'DEMOBUS10', label: '10% OFF', days: 30),
  ];

  late final List<Offer> _hot = [
    _o('h1', 'frp-moto-affiliate', 'GMB100 Frame', image: '$_banner/banner-17319772-3d42786e.jpg', desc: 'Mini bike frame for custom builds — fits Predator 212 and 99–212cc engine swaps.', days: 365),
    _o('h2', 'nanit', 'Smart monitor bundle', label: '20% OFF', image: '$_banner/banner-17285767-b08e2331.jpg', desc: 'Bundle a Nanit camera with accessories and save.', days: 365),
    _o('h3', 'hp-us', 'Home office upgrade', code: 'DEMOHP15', label: '15% OFF', image: '$_banner/banner-17342274-73b805a2.jpg', desc: 'Desks, monitors and storage for a productive home office.', days: 365),
  ];

  Future<T> _delay<T>(T v) => Future.delayed(const Duration(milliseconds: 350), () => v);

  @override
  Future<List<Store>> popularStores() => _delay(_stores.take(12).toList());

  @override
  Future<Paged<Store>> stores({String? query, String? letter, int page = 1}) {
    var list = [..._stores]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    if (query != null && query.isNotEmpty) {
      list = list.where((s) => s.name.toLowerCase().contains(query.toLowerCase())).toList();
    }
    if (letter != null && letter.isNotEmpty) {
      list = letter == '#'
          ? list.where((s) => !RegExp(r'^[a-z]', caseSensitive: false).hasMatch(s.name)).toList()
          : list.where((s) => s.name.toUpperCase().startsWith(letter)).toList();
    }
    return _delay(Paged(page == 1 ? list : list.take(0).toList(), total: list.length));
  }

  @override
  Future<Store?> store(String slug) => _delay(_stores.where((s) => s.slug == slug).firstOrNull);

  @override
  Future<List<Offer>> storeOffers(String slug, {OfferSort sort = OfferSort.recommended}) {
    final list = [..._offers, ..._hot].where((o) => o.storeSlug == slug).toList();
    if (list.isEmpty) {
      final s = _s(slug);
      list.add(_o('g-$slug', slug, 'Shop current sale prices at ${s.name}', days: 14));
    }
    if (sort == OfferSort.endingSoon) {
      list.sort((a, b) => (a.expiresAt ?? DateTime(9999)).compareTo(b.expiresAt ?? DateTime(9999)));
    }
    return _delay(list);
  }

  @override
  Future<List<Store>> similarStores(String slug) {
    final me = _stores.where((s) => s.slug == slug).firstOrNull;
    final same = _stores.where((s) => s.slug != slug && s.categorySlug == me?.categorySlug).toList();
    final rest = _stores.where((s) => s.slug != slug && !same.contains(s));
    return _delay([...same, ...rest].take(6).toList());
  }

  @override
  Future<List<StoreCategory>> categories() => _delay(_categories);

  @override
  Future<List<Store>> categoryStores(String slug) => _delay(_stores.where((s) => s.categorySlug == slug).toList());

  @override
  Future<List<Offer>> categoryOffers(String slug) {
    final slugs = _stores.where((s) => s.categorySlug == slug).map((s) => s.slug).toSet();
    return _delay(_offers.where((o) => slugs.contains(o.storeSlug)).toList());
  }

  @override
  Future<Paged<Offer>> topOffers({OfferFilter filter = OfferFilter.all, int page = 1}) {
    var list = [..._offers];
    switch (filter) {
      case OfferFilter.codes:
        list = list.where((o) => o.kind == OfferKind.code).toList();
      case OfferFilter.deals:
        list = list.where((o) => o.kind == OfferKind.deal).toList();
      case OfferFilter.endingSoon:
        list.sort((a, b) => a.expiresAt!.compareTo(b.expiresAt!));
        list = list.take(6).toList();
      case OfferFilter.all:
        break;
    }
    return _delay(Paged(page == 1 ? list : list.take(0).toList(), total: list.length));
  }

  @override
  Future<List<Offer>> hotProductDeals() => _delay(_hot);

  @override
  Future<({List<Store> stores, List<Offer> offers})> search(String query) {
    final q = query.toLowerCase();
    return _delay((
      stores: _stores.where((s) => s.name.toLowerCase().contains(q)).toList(),
      offers: _offers
          .where((o) => o.title.toLowerCase().contains(q) || o.storeName.toLowerCase().contains(q))
          .toList(),
    ));
  }

  @override
  Future<void> subscribeNewsletter(String email) => _delay(null);
}
