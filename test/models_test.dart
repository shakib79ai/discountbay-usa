import 'package:discountbay/data/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Offer parses snake_case API payload and relative logo URLs', () {
    final o = Offer.fromJson({
      'id': 42,
      'title': 'Extra 20% off sitewide',
      'coupon_code': 'SAVE20',
      'discount_percent': 20,
      'end_date': '2099-01-01T00:00:00Z',
      'store': {'name': "Macy's", 'slug': 'macy-s', 'logo_url': '/static/logos/m.svg'},
    }, assetBase: 'https://api.discountbay.com');

    expect(o.id, '42');
    expect(o.kind, OfferKind.code);
    expect(o.discountLabel, '20% OFF');
    expect(o.stampParts, ('20%', 'OFF'));
    expect(o.storeLogo, 'https://api.discountbay.com/static/logos/m.svg');
    expect(o.expired, isFalse);
  });

  test('Offer without code is a deal with a DEAL stamp', () {
    final o = Offer.fromJson({'title': 'Free shipping', 'store_name': 'Temu', 'store_slug': 'temu'});
    expect(o.kind, OfferKind.deal);
    expect(o.stampParts, ('DEAL', ''));
  });

  test('Store tolerates alternate key names', () {
    final s = Store.fromJson({'advertiser_id': 7, 'slug': 'hp-us', 'advertiser_name': 'HP US', 'offers_count': '15'});
    expect(s.id, '7');
    expect(s.name, 'HP US');
    expect(s.offerCount, 15);
  });
}
