import 'dart:convert';
import 'package:http/http.dart' as http;

class PokemonTCGService {
  static const String _baseUrl = "https://api.pokemontcg.io/v2/cards";
  static const String _apiKey = "7e076431-71e7-431d-8390-5f8bc3b6111d"; // If required
  static List<dynamic>? _cachedCards; // Private in-memory cache

  // Fetch all Pokémon sets (for dropdown filter)
  Future<List<dynamic>> fetchSets() async {
    try {
      final response = await http.get(Uri.parse("https://api.pokemontcg.io/v2/sets"));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'];
      } else {
        throw Exception("Failed to load Pokémon sets");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Fetch all cards from a selected set
  Future<List<dynamic>> fetchCardsBySet(String setId) async {
    if (_cachedCards != null) {
      print("Using cached Pokémon cards for set $setId");
      return _cachedCards!;
    }

    try {
      final response = await http.get(
        Uri.parse("$_baseUrl?q=set.id:$setId"), // Query for selected set
        headers: {
          "X-Api-Key": _apiKey, // If API requires a key
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedCards = data['data']; // Cache results
        return _cachedCards!;
      } else {
        throw Exception("Failed to load Pokémon cards from set $setId");
      }
    } catch (e) {
      throw Exception("Error: $e");
    }
  }

  // Public method to clear cache when switching sets
  void clearCache() {
    _cachedCards = null;
    print("Cache cleared.");
  }
}
