class AppUser {
  final String userId;
  final String name;
  final String email;
  final String phone;
  final String profilePicture;

  AppUser({
    required this.userId,
    required this.name,
    required this.email,
    required this.phone,
    required this.profilePicture,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'name': name,
      'email': email,
      'phone': phone,
      'profile_Picture': profilePicture,
    };
  }

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      userId: map['userId'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profilePicture: map['profile_Picture'] ?? '',
    );
  }
}
