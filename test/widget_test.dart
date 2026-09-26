import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:quick/core/utils/formatters.dart';
import 'package:quick/core/utils/jwt.dart';
import 'package:quick/core/utils/validators.dart';
import 'package:quick/models/cart.dart';
import 'package:quick/models/page_response.dart';
import 'package:quick/models/product.dart';
import 'package:quick/providers/settings_provider.dart';

void main() {
  group('formatters', () {
    test('formats prices with Indian digit grouping', () {
      expect(formatPrice(109999), '₹1,09,999');
      expect(formatPrice(12.5), '₹12.50');
      expect(formatPrice(null), '₹ --');
    });

    test('computes discount like the website', () {
      expect(discountPercent(90, 100), 10);
      expect(discountPercent(100, 90), 0);
      expect(discountPercent(null, 100), 0);
    });

    test('prettyCategory', () => expect(prettyCategory('home-and-living'), 'Home And Living'));
  });

  group('validators (same rules as website signup)', () {
    test('mobile must be 10 digits', () {
      expect(Validators.mobile('9876543210'), isNull);
      expect(Validators.mobile('12345'), isNotNull);
    });
    test('email', () {
      expect(Validators.email('a@b.co'), isNull);
      expect(Validators.email('nope'), isNotNull);
    });
    test('password >= 6 and name >= 3', () {
      expect(Validators.password('12345'), isNotNull);
      expect(Validators.password('123456'), isNull);
      expect(Validators.name('Al'), isNotNull);
    });
  });

  group('models', () {
    test('parses a classic Spring Page of ProductsDto', () {
      final page = PageResponse.fromJson({
        'content': [
          {'id': 'p1', 'name': 'Phone', 'brand': 'X', 'image': 'https://img', 'price': 100, 'originalPrice': 125},
        ],
        'number': 0,
        'totalPages': 3,
        'totalElements': 30,
        'last': false,
      }, ProductSummary.fromJson);
      expect(page.content.single.discount, 20);
      expect(page.totalElements, 30);
      expect(page.last, isFalse);
    });

    test('parses the Spring Data VIA_DTO page format', () {
      final page = PageResponse.fromJson({
        'content': [
          {'id': 'p1', 'name': 'Phone'},
        ],
        'page': {'number': 2, 'size': 12, 'totalPages': 3, 'totalElements': 25},
      }, ProductSummary.fromJson);
      expect(page.number, 2);
      expect(page.last, isTrue);
    });

    test('cart summary falls back to backend formula (18% GST)', () {
      final cart = Cart.fromJson({
        'id': 'c1',
        'items': [
          {'productId': 'p1', 'quantity': 2, 'price': 100.0},
        ],
        'summary': {'currency': 'INR'},
      });
      expect(cart.itemCount, 2);
      expect(cart.effectiveSummary.tax, closeTo(36, 0.001));
      expect(cart.effectiveSummary.totalAmount, closeTo(236, 0.001));
    });
  });

  test('reads JWT claims and expiry', () {
    String b64(Map<String, dynamic> m) => base64Url.encode(utf8.encode(jsonEncode(m))).replaceAll('=', '');
    final exp = DateTime.now().add(const Duration(days: 7)).millisecondsSinceEpoch ~/ 1000;
    final token = '${b64({'alg': 'RS256'})}.${b64({'sub': 'a@b.co', 'roles': ['ROLE_USER'], 'exp': exp})}.sig';
    expect(decodeJwtPayload(token)?['sub'], 'a@b.co');
    expect(isJwtExpired(token), isFalse);
  });

  test('normalises server URLs typed in Server settings', () {
    expect(SettingsProvider.normalizeUrl('192.168.1.5:8085/'), 'http://192.168.1.5:8085');
    expect(SettingsProvider.normalizeUrl('https://api.x.in'), 'https://api.x.in');
  });
}
