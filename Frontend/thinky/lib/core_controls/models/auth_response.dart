class AuthResponse {
  final String accessToken;
  final String tokenType;
  final int userId;
  final String? username;
  final String? email;
  final bool isGuest;
  final String? guestName;
  final bool isAdmin;

  AuthResponse({
    required this.accessToken,
    required this.tokenType,
    required this.userId,
    this.username,
    this.email,
    required this.isGuest,
    this.guestName,
    this.isAdmin = false,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      userId: json['user_id'] as int,
      username: json['username'] as String?,
      email: json['email'] as String?,
      isGuest: json['is_guest'] as bool? ?? false,
      guestName: json['guest_name'] as String?,
      isAdmin: json['is_admin'] as bool? ?? false,
    );
  }
}

class AuthError {
  final String message;
  final int? statusCode;

  AuthError({required this.message, this.statusCode});

  factory AuthError.fromJson(Map<String, dynamic> json) {
    return AuthError(
      message: json['detail'] as String? ?? 'An error occurred',
      statusCode: null,
    );
  }

  static AuthError fromString(String message) {
    return AuthError(message: message);
  }
}

