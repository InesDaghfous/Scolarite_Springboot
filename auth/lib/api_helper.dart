import 'dart:convert';

/// Helper polyvalent pour parser les réponses JSON Spring Boot
/// Supporte aussi bien Spring Data REST (format HATEOAS / HAL avec `_embedded`)
/// que les contrôleurs REST classiques (`@RestController` renvoyant une simple `List`).
List<dynamic> parseHalList(String responseBody, String resourceKey) {
  try {
    final decoded = jsonDecode(responseBody);
    if (decoded is List) {
      return decoded;
    }
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('_embedded')) {
        final embedded = decoded['_embedded'] as Map<String, dynamic>;
        if (embedded.containsKey(resourceKey)) {
          return embedded[resourceKey] as List<dynamic>;
        }
        // Si le nom de la clé diffère légèrement, prendre la première liste trouvée
        for (final val in embedded.values) {
          if (val is List) return val;
        }
      }
      if (decoded.containsKey('content') && decoded['content'] is List) {
        return decoded['content'] as List<dynamic>;
      }
      if (decoded.containsKey(resourceKey) && decoded[resourceKey] is List) {
        return decoded[resourceKey] as List<dynamic>;
      }
    }
  } catch (e) {
    // ignore
  }
  return [];
}

