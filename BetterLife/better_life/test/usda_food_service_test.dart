import 'dart:convert';

import 'package:better_life/services/usda_food_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('UsdaFoodService', () {
    late FakeFirebaseFirestore firestore;

    setUp(() {
      firestore = FakeFirebaseFirestore();
    });

    test('saves USDA products and search cache on first fetch', () async {
      var requestCount = 0;
      final service = UsdaFoodService(
        firestore: firestore,
        client: MockClient((request) async {
          requestCount++;
          return http.Response('''
            {
              "totalHits": 1,
              "currentPage": 1,
              "totalPages": 1,
              "foods": [
                {
                  "fdcId": 123,
                  "description": "Cheddar cheese",
                  "servingSize": 100,
                  "servingSizeUnit": "g",
                  "foodNutrients": [
                    {
                      "nutrientId": 1008,
                      "nutrientName": "Energy",
                      "unitName": "KCAL",
                      "value": 403
                    }
                  ]
                }
              ]
            }
            ''', 200);
        }),
      );

      final page = await service.searchFoods(query: 'Cheddar cheese');

      expect(requestCount, 1);
      expect(page.foods.single.fdcId, 123);

      final product = await firestore.collection('usdaFoods').doc('123').get();
      expect(product.exists, isTrue);
      expect(product.data()!['fdcId'], 123);
      expect(product.data()!['description'], 'Cheddar cheese');

      final searches = await firestore.collection('usdaFoodSearches').get();
      expect(searches.docs, hasLength(1));
      expect(searches.docs.single.data()['fdcIds'], [123]);
    });

    test('returns cached search without calling USDA API', () async {
      final service = UsdaFoodService(
        firestore: firestore,
        client: MockClient((_) async {
          fail('USDA API should not be called when search cache exists');
        }),
      );

      await firestore.collection('usdaFoods').doc('123').set({
        'fdcId': 123,
        'description': 'Cheddar cheese',
        'calories': 403,
        'calorieBasis': 'per 100 g',
        'gramsBasis': 100,
      });
      await seedSearchCache(
        firestore,
        query: 'cheddar cheese',
        page: 1,
        pageSize: UsdaFoodService.defaultPageSize,
        fdcIds: [123],
      );

      final page = await service.searchFoods(query: '  Cheddar   Cheese  ');

      expect(page.foods, hasLength(1));
      expect(page.foods.single.fdcId, 123);
      expect(page.foods.single.calories, 403);
    });
  });
}

Future<void> seedSearchCache(
  FakeFirebaseFirestore firestore, {
  required String query,
  required int page,
  required int pageSize,
  required List<int> fdcIds,
}) async {
  final normalizedQuery = query.trim().toLowerCase().replaceAll(
    RegExp(r'\s+'),
    ' ',
  );
  final key = base64Url.encode(utf8.encode('$normalizedQuery|$page|$pageSize'));

  await firestore.collection('usdaFoodSearches').doc(key).set({
    'query': normalizedQuery,
    'page': page,
    'pageSize': pageSize,
    'fdcIds': fdcIds,
    'totalHits': fdcIds.length,
    'currentPage': page,
    'totalPages': 1,
    'updatedAt': Timestamp.fromDate(DateTime(2026, 5, 11)),
  });
}
