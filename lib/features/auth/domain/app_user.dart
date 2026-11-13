/// Minimal signed-in identity used by the app shell.
///
/// Authorization is not derived from this object. The database decides what a
/// signed-in user may read or change through RLS and restaurant memberships.
class AppUser {
  const AppUser({required this.id, this.email});

  final String id;
  final String? email;

  @override
  bool operator ==(Object other) =>
      other is AppUser && other.id == id && other.email == email;

  @override
  int get hashCode => Object.hash(id, email);
}
