import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;

import '../models/usda_food_search_result.dart';

class UsdaFoodService {
  UsdaFoodService({
    http.Client? client,
    FirebaseFirestore? firestore,
    String apiKey = const String.fromEnvironment(
      'USDA_API_KEY',
      defaultValue: 'DEMO_KEY',
    ),
  }) : _client = client ?? http.Client(),
       _firestore = firestore ?? FirebaseFirestore.instance,
       _apiKey = apiKey;

  static const int defaultPageSize = 10;
  static const String _baseUrl = 'api.nal.usda.gov';

  final http.Client _client;
  final FirebaseFirestore _firestore;
  final String _apiKey;

  CollectionReference<Map<String, dynamic>> get _foodsRef {
    return _firestore.collection('usdaFoods');
  }

  CollectionReference<Map<String, dynamic>> get _searchesRef {
    return _firestore.collection('usdaFoodSearches');
  }

  Future<UsdaFoodSearchPage> searchFoods({
    required String query,
    int page = 1,
    int pageSize = defaultPageSize,
  }) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) {
      return const UsdaFoodSearchPage(
        foods: [],
        totalHits: 0,
        currentPage: 1,
        totalPages: 1,
      );
    }

    final cachedPage = await _readCachedSearch(
      query: trimmedQuery,
      page: page,
      pageSize: pageSize,
    );
    if (cachedPage != null) return cachedPage;

    final uri = Uri.https(_baseUrl, '/fdc/v1/foods/search', {
      'api_key': _apiKey,
    });

    final response = await _client.post(
      uri,
      headers: const {'Content-Type': 'application/json'},
      body: jsonEncode({
        'query': trimmedQuery,
        'pageSize': pageSize,
        'pageNumber': page,
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw UsdaFoodServiceException();
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw UsdaFoodServiceException();
    }

    final searchPage = UsdaFoodSearchPage.fromJson(decoded);
    await _cacheSearchPage(
      query: trimmedQuery,
      page: page,
      pageSize: pageSize,
      searchPage: searchPage,
    );

    return searchPage;
  }

  Future<UsdaFoodSearchPage?> _readCachedSearch({
    required String query,
    required int page,
    required int pageSize,
  }) async {
    final searchDoc = await _searchesRef
        .doc(_searchCacheKey(query: query, page: page, pageSize: pageSize))
        .get();
    final searchData = searchDoc.data();
    if (searchData == null) return null;

    final fdcIds = (searchData['fdcIds'] as List?)
        ?.whereType<num>()
        .map((id) => id.toInt())
        .toList();
    if (fdcIds == null) return null;

    final foodDocs = await Future.wait(
      fdcIds.map((fdcId) => _foodsRef.doc(fdcId.toString()).get()),
    );

    if (foodDocs.any((doc) => !doc.exists)) return null;

    final foods = foodDocs
        .map((doc) => UsdaFoodSearchResult.fromCacheMap(doc.data()!))
        .toList();

    return UsdaFoodSearchPage.fromCacheMap(searchData, foods);
  }

  Future<void> _cacheSearchPage({
    required String query,
    required int page,
    required int pageSize,
    required UsdaFoodSearchPage searchPage,
  }) async {
    final batch = _firestore.batch();
    final now = FieldValue.serverTimestamp();

    for (final food in searchPage.foods) {
      batch.set(_foodsRef.doc(food.fdcId.toString()), {
        ...food.toCacheMap(),
        'updatedAt': now,
      }, SetOptions(merge: true));
    }

    batch.set(
      _searchesRef.doc(
        _searchCacheKey(query: query, page: page, pageSize: pageSize),
      ),
      {
        'query': _normalizeQuery(query),
        'page': page,
        'pageSize': pageSize,
        'fdcIds': searchPage.foods.map((food) => food.fdcId).toList(),
        'totalHits': searchPage.totalHits,
        'currentPage': searchPage.currentPage,
        'totalPages': searchPage.totalPages,
        'updatedAt': now,
      },
    );

    await batch.commit();
  }

  String _searchCacheKey({
    required String query,
    required int page,
    required int pageSize,
  }) {
    final rawKey = '${_normalizeQuery(query)}|$page|$pageSize';
    return base64Url.encode(utf8.encode(rawKey));
  }

  String _normalizeQuery(String query) {
    return query.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
  }
}

class UsdaFoodServiceException implements Exception {}
