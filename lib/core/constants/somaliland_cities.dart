/// Somaliland cities and regions
class SomalilandCities {
  static const List<Map<String, dynamic>> cities = [
    {
      'name': 'Hargeisa',
      'region': 'Maroodi Jeex',
      'coordinates': {'lat': 9.5500, 'lng': 44.0500},
      'isCapital': true,
    },
    {
      'name': 'Berbera',
      'region': 'Sahil',
      'coordinates': {'lat': 10.4396, 'lng': 45.0143},
      'isCapital': false,
    },
    {
      'name': 'Burao',
      'region': 'Togdheer',
      'coordinates': {'lat': 9.5219, 'lng': 45.5426},
      'isCapital': false,
    },
    {
      'name': 'Borama',
      'region': 'Awdal',
      'coordinates': {'lat': 9.9381, 'lng': 43.2261},
      'isCapital': false,
    },
    {
      'name': 'Erigavo',
      'region': 'Sanaag',
      'coordinates': {'lat': 10.6167, 'lng': 47.3667},
      'isCapital': false,
    },
    {
      'name': 'Zeila',
      'region': 'Awdal',
      'coordinates': {'lat': 11.3584, 'lng': 43.4727},
      'isCapital': false,
    },
    {
      'name': 'Sheikh',
      'region': 'Sahil',
      'coordinates': {'lat': 9.9833, 'lng': 45.1667},
      'isCapital': false,
    },
    {
      'name': 'Gabiley',
      'region': 'Maroodi Jeex',
      'coordinates': {'lat': 9.5833, 'lng': 43.3333},
      'isCapital': false,
    },
    {
      'name': 'Wajaale',
      'region': 'Maroodi Jeex',
      'coordinates': {'lat': 9.6000, 'lng': 43.3500},
      'isCapital': false,
    },
    {
      'name': 'Las Anod',
      'region': 'Sool',
      'coordinates': {'lat': 8.7890, 'lng': 47.2890},
      'isCapital': false,
    },
    {
      'name': 'Ainabo',
      'region': 'Sool',
      'coordinates': {'lat': 9.1000, 'lng': 46.5000},
      'isCapital': false,
    },
    {
      'name': 'Oodweyne',
      'region': 'Togdheer',
      'coordinates': {'lat': 9.4167, 'lng': 45.0833},
      'isCapital': false,
    },
    {
      'name': 'Caynabo',
      'region': 'Sool',
      'coordinates': {'lat': 9.4000, 'lng': 46.2000},
      'isCapital': false,
    },
    {
      'name': 'Lughaya',
      'region': 'Awdal',
      'coordinates': {'lat': 10.6396, 'lng': 43.8100},
      'isCapital': false,
    },
    {
      'name': 'Badhan',
      'region': 'Sanaag',
      'coordinates': {'lat': 10.7333, 'lng': 48.5000},
      'isCapital': false,
    },
  ];

  /// Get all city names sorted alphabetically
  static List<String> getCityNames() {
    List<String> names = cities.map((city) => city['name'] as String).toList();
    names.sort();
    return names;
  }

  /// Get coordinates for a specific city
  static Map<String, double>? getCityCoordinates(String cityName) {
    final city = cities.firstWhere(
      (city) => city['name'] == cityName,
      orElse: () => {},
    );
    
    if (city.isNotEmpty) {
      final coords = city['coordinates'] as Map<String, dynamic>;
      return {
        'lat': coords['lat'].toDouble(),
        'lng': coords['lng'].toDouble(),
      };
    }
    return null;
  }

  /// Get region for a specific city
  static String? getCityRegion(String cityName) {
    final city = cities.firstWhere(
      (city) => city['name'] == cityName,
      orElse: () => {},
    );
    
    return city.isNotEmpty ? city['region'] as String : null;
  }

  /// Get default city (Hargeisa - capital)
  static String getDefaultCity() {
    return 'Hargeisa';
  }

  /// Get default coordinates (Hargeisa)
  static Map<String, double> getDefaultCoordinates() {
    return getCityCoordinates(getDefaultCity()) ?? {'lat': 9.5500, 'lng': 44.0500};
  }
}
