/// One restaurant a signed-in staff member belongs to.
///
/// `role` and `publicationStatus` come from the database. The app uses them for
/// display only; every read and write is still checked by RLS.
class StaffRestaurant {
  const StaffRestaurant({
    required this.name,
    required this.slug,
    required this.role,
    required this.publicationStatus,
    this.isActive = true,
  });

  final String name;
  final String slug;
  final String role;
  final String publicationStatus;
  final bool isActive;

  String get roleLabel => switch (role) {
    'owner' => 'Owner',
    'manager' => 'Manager',
    'kitchen' => 'Kitchen',
    'cashier' => 'Cashier',
    'server' => 'Server',
    _ => role,
  };

  String get publicationLabel => switch (publicationStatus) {
    'published' => 'Published',
    'pending_review' => 'In review',
    'suspended' => 'Suspended',
    _ => 'Not published yet',
  };

  static StaffRestaurant? fromJson(Map<String, Object?> json) {
    final role = _string(json['role']);
    if (role == null) return null;

    final restaurant = json['restaurants'];
    if (restaurant is! Map<String, Object?>) return null;

    final name = _string(restaurant['name']);
    final slug = _string(restaurant['slug']);
    if (name == null || slug == null) return null;

    return StaffRestaurant(
      name: name,
      slug: slug,
      role: role,
      publicationStatus: _string(restaurant['publication_status']) ?? 'draft',
      isActive: json['is_active'] != false,
    );
  }
}

String? _string(Object? value) {
  if (value is! String) return null;
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}
