import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/place_model.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';

class ApiService {
  static const String baseUrl = 'https://web-production-9293a.up.railway.app/api';

  // Singleton
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  String? _token;

  void setToken(String token) => _token = token;
  void clearToken() => _token = null;
  bool get isLoggedIn => _token != null;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      };

  // ── AUTH ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: _headers,
      body: jsonEncode({'email': email, 'password': password}),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode == 200) {
      // Coba berbagai kemungkinan field token dari API
      final token = body['token'] ??
          body['access_token'] ??
          body['data']?['token'] ??
          body['data']?['access_token'];
      if (token != null) {
        _token = token.toString();
      }
    }
    return body;
  }

  Future<Map<String, dynamic>> register(
      String name, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: _headers,
      body: jsonEncode({'name': name, 'email': email, 'password': password}),
    );
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>?> getMe() async {
    if (_token == null) return null;
    final res =
        await http.get(Uri.parse('$baseUrl/auth/me'), headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body) as Map<String, dynamic>)['data'];
    }
    return null;
  }

  // ── CATEGORIES ────────────────────────────────────────────────────────────

  Future<List<CategoryModel>> getCategories() async {
    final res =
        await http.get(Uri.parse('$baseUrl/categories'), headers: _headers);
    if (res.statusCode == 200) {
      final data = (jsonDecode(res.body)['data'] as List);
      return data.map((e) => CategoryModel.fromJson(e)).toList();
    }
    throw Exception('Gagal memuat kategori');
  }

  // ── PLACES ────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getPlaces({
    int? categoryId,
    String? search,
    double? lat,
    double? lng,
    int page = 1,
    int limit = 20,
  }) async {
    final params = {
      'page': page.toString(),
      'limit': limit.toString(),
      if (categoryId != null) 'category': categoryId.toString(),
      if (search != null && search.isNotEmpty) 'search': search,
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
    };
    final uri =
        Uri.parse('$baseUrl/places').replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      final body = jsonDecode(res.body);
      return {
        'places': (body['data'] as List)
            .map((e) => PlaceModel.fromJson(e))
            .toList(),
        'meta': body['meta'],
      };
    }
    throw Exception('Gagal memuat tempat');
  }

  Future<List<PlaceModel>> getNearby({
    required double lat,
    required double lng,
    int? categoryId,
    int limit = 20,
  }) async {
    final params = {
      'lat': lat.toString(),
      'lng': lng.toString(),
      'limit': limit.toString(),
      if (categoryId != null) 'category': categoryId.toString(),
    };
    final uri = Uri.parse('$baseUrl/places/nearby')
        .replace(queryParameters: params);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['data'] as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat tempat terdekat');
  }

  Future<PlaceModel> getPlaceDetail(int id, {double? lat, double? lng}) async {
    final params = {
      if (lat != null) 'lat': lat.toString(),
      if (lng != null) 'lng': lng.toString(),
    };
    final uri = Uri.parse('$baseUrl/places/$id')
        .replace(queryParameters: params.isNotEmpty ? params : null);
    final res = await http.get(uri, headers: _headers);
    if (res.statusCode == 200) {
      return PlaceModel.fromJson(jsonDecode(res.body)['data']);
    }
    throw Exception('Gagal memuat detail tempat');
  }

  // ── REVIEWS ───────────────────────────────────────────────────────────────

  Future<List<ReviewModel>> getReviews(int placeId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/places/$placeId/reviews'),
        headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['data'] as List)
          .map((e) => ReviewModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat ulasan');
  }

  Future<Map<String, dynamic>> getReviewSummary(int placeId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/places/$placeId/reviews/summary'),
        headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data'] as Map<String, dynamic>;
    }
    return {};
  }

  Future<bool> postReview(int placeId, int rating, String comment) async {
    final res = await http.post(
      Uri.parse('$baseUrl/places/$placeId/reviews'),
      headers: _headers,
      body: jsonEncode({'rating': rating, 'comment': comment}),
    );
    return res.statusCode == 201;
  }

  // ── FAVORITES ─────────────────────────────────────────────────────────────

  Future<List<PlaceModel>> getFavorites() async {
    final res = await http.get(Uri.parse('$baseUrl/favorites'),
        headers: _headers);
    if (res.statusCode == 200) {
      return (jsonDecode(res.body)['data'] as List)
          .map((e) => PlaceModel.fromJson(e))
          .toList();
    }
    throw Exception('Gagal memuat favorit');
  }

  Future<bool> addFavorite(int placeId) async {
    final res = await http.post(
        Uri.parse('$baseUrl/favorites/$placeId'),
        headers: _headers);
    return res.statusCode == 201;
  }

  Future<bool> removeFavorite(int placeId) async {
    final res = await http.delete(
        Uri.parse('$baseUrl/favorites/$placeId'),
        headers: _headers);
    return res.statusCode == 200;
  }

  Future<bool> checkFavorite(int placeId) async {
    final res = await http.get(
        Uri.parse('$baseUrl/favorites/check/$placeId'),
        headers: _headers);
    if (res.statusCode == 200) {
      return jsonDecode(res.body)['data']['is_favorite'] == true;
    }
    return false;
  }
}
