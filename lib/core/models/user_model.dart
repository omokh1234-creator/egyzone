class User {
  final String? id; // Often API returns id as string or int depending on setup, swagger shows string-like usually for Identity but could be int. We'll use dynamic or string. Swagger says userId. Let's use dynamic.
  final String? fullName;
  final String? email;
  final String? phoneNumber;
  final String? role;
  final String? profilePicture;

  User({
    this.id,
    this.fullName,
    this.email,
    this.phoneNumber,
    this.role,
    this.profilePicture,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['userId']?.toString(), // Safely convert to string
      fullName: json['fullName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String?,
      profilePicture: json['profilePicture'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': id,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
      'role': role,
      'profilePicture': profilePicture,
    };
  }
}
