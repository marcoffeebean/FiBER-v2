enum UserRole { teacher, student, admin }

class AppUser {
  final String id;
  final String email;
  final UserRole role;
  final String username;
  final String name;
  final String password;
  final String? photoUrl;

  AppUser({
    required this.id,
    required this.email,
    required this.role,
    required this.username,
    required this.name,
    required this.password,
    this.photoUrl,
  });
}
