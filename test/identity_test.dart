import 'package:discountbay/data/models.dart';
import 'package:discountbay/theme/identity.dart';
import 'package:flutter_test/flutter_test.dart';

Offer _offer(String title, {String? label, String? code}) =>
    Offer(id: '1', title: title, storeName: "Macy's", storeSlug: 'macy-s', discountLabel: label, code: code);

void main() {
  test('initials use the first two words and skip filler words', () {
    expect(initials('Lighting New York'), 'LN');
    expect(initials('GARVEE'), 'G');
    expect(initials('Booking.com North America'), 'B');
    expect(initials('eBay'), 'e');
  });

  test('site category comes from the category name, with whole-word matching', () {
    expect(SiteCategory.guess(['Computers & Electronics']).key, 'electronics');
    expect(SiteCategory.guess(['Home & Garden']).key, 'home');
    expect(SiteCategory.guess(['Canada Pet Care']).key, 'pets'); // "car" must not match "Care"
    expect(SiteCategory.guess(['Giftcards.com']).key, 'gifts');
  });

  test('discount number, badge and value for cards', () {
    final o = _offer('Up to 70% off Mens Suits and Blazers');
    expect(savePercent(o), 70);
    expect(offerBadge(o), 'UP TO 70% OFF');
    expect(offerValue(o), '70% off');
    expect(savePercent(_offer('Best: up to 600% off')), 100); // capped
    expect(offerValue(_offer(r'$29.99 Aiden 8pc Comforter Set')), r'$29.99');
    expect(offerBadge(_offer('Free gift', code: 'GIFT')), 'CODE');
  });

  test('each store gets one stable look, and known stores keep their brand colour', () {
    final a = StoreLook.forName('Shelving Inc.', slug: 'shelving-inc', categoryText: 'Home & Garden');
    final b = StoreLook.forName('Shelving Inc.', slug: 'shelving-inc', categoryText: 'Home & Garden');
    expect(identical(a, b), isTrue);
    expect(a.cover, startsWith('assets/photos/'));
    expect(a.thumbs.length, 3);
    expect(StoreLook.forName("Macy's", slug: 'macy-s').brand.toARGB32(), 0xFFC8102E);
  });
}
