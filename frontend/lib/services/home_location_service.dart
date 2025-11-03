// lib/services/home_location_service.dart
import 'dart:convert';
import 'package:food_recipe_app/common/api_client.dart';

class HomeLocationService {
  final ApiClient _api = ApiClient();

  Future<Map<String, dynamic>?> fetchHome() async {
    final resp = await _api.get('/api/location/home');
    if (resp.statusCode == 200) {
      return jsonDecode(utf8.decode(resp.bodyBytes)) as Map<String, dynamic>;
    }
    return null; // 204 or error → treat as unset
  }

  Future<bool> saveHome(double lat, double lng, {int? radiusMeters}) async {
    final body = {
      'latitude': lat,
      'longitude': lng,
      if (radiusMeters != null) 'radiusMeters': radiusMeters,
    };
    final resp = await _api.put('/api/location/home', body: body);
    return resp.statusCode == 200;
  }
}

