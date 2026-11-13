/// Directions links for approved restaurant locations.
///
/// Both providers accept a free-text query, so no API key or account is needed
/// for the pilot. Coordinates can replace the query later without changing the
/// calling code.
library;

Uri googleMapsDirectionsUri(String query) =>
    Uri.https('www.google.com', '/maps/search/', {'api': '1', 'query': query});

Uri wazeDirectionsUri(String query) =>
    Uri.https('waze.com', '/ul', {'q': query});

String directionsQuery({required String name, String? address}) {
  final trimmed = address?.trim();
  if (trimmed == null || trimmed.isEmpty) return name;
  return '$name, $trimmed';
}
