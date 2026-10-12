import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

/// Service to handle Reverse Geocoding (turning GPS Coordinates into human-readable addresses).
/// Uses OpenStreetMap Nominatim with graceful fallback to coordinates for offline disaster usage.
class GeocodingService {
  static final HttpClient _httpClient = HttpClient()
    ..connectionTimeout = const Duration(seconds: 4);

  /// Converts GPS coordinates into a human-readable address.
  /// Example return: "Kolonnawa Road, Wellampitiya" or "Kaduwela Road, Malabe".
  /// If offline or network unavailable, returns formatted coordinates.
  static Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng&zoom=18&addressdetails=1',
      );
      final request = await _httpClient.getUrl(uri);
      request.headers.set(
        'User-Agent',
        'WeSafeDisasterApp/1.0 (disaster-response-lk; contact: dev@wesafe.org)',
      );
      final response = await request.close().timeout(const Duration(seconds: 4));

      if (response.statusCode == 200) {
        final responseBody = await response.transform(utf8.decoder).join();
        final data = json.decode(responseBody) as Map<String, dynamic>;

        final address = data['address'] as Map<String, dynamic>?;
        if (address != null) {
          final road = (address['road'] ??
                  address['pedestrian'] ??
                  address['highway'] ??
                  address['suburb'] ??
                  address['neighbourhood']) as String?;

          final city = (address['city'] ??
                  address['town'] ??
                  address['village'] ??
                  address['municipality'] ??
                  address['county'] ??
                  address['state_district']) as String?;

          if (road != null && city != null && road.isNotEmpty && city.isNotEmpty) {
            return '$road, $city';
          } else if (city != null && city.isNotEmpty) {
            return city;
          } else if (road != null && road.isNotEmpty) {
            return road;
          }
        }

        final displayName = data['display_name'] as String?;
        if (displayName != null && displayName.isNotEmpty) {
          final parts = displayName.split(', ');
          if (parts.length >= 2) {
            return '${parts[0]}, ${parts[1]}';
          }
          return parts.first;
        }
      }
    } catch (e) {
      debugPrint('Geocoding reverse lookup error: $e');
    }

    return 'Sector (${lat.toStringAsFixed(4)}° N, ${lng.toStringAsFixed(4)}° E)';
  }
}
