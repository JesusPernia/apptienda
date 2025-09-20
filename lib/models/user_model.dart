class User {
  final String id;
  final String email;
  final String name;
  final String? avatar;
  final String provider;
  final String? firebaseUid;
  final UserLevel level;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.avatar,
    required this.provider,
    this.firebaseUid,
    required this.level,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      email: json['email'],
      name: json['name'],
      avatar: json['avatar'],
      provider: json['provider'] ?? 'local',
      firebaseUid: json['firebaseUid'],
      level: UserLevel.fromString(json['level'] ?? 'user'),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'avatar': avatar,
      'provider': provider,
      'firebaseUid': firebaseUid,
      'level': level.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

enum UserLevel {
  admin('admin'),
  moderator('moderator'),
  user('user'),
  guest('guest');

  final String value;
  const UserLevel(this.value);

  factory UserLevel.fromString(String value) {
    switch (value) {
      case 'admin':
        return UserLevel.admin;
      case 'moderator':
        return UserLevel.moderator;
      case 'user':
        return UserLevel.user;
      case 'guest':
        return UserLevel.guest;
      default:
        return UserLevel.user;
    }
  }

  bool get isAdmin => this == UserLevel.admin;
  bool get isModerator => this == UserLevel.moderator || isAdmin;
  bool get isUser => this == UserLevel.user || isModerator;
  bool get isGuest => this == UserLevel.guest;

  String get displayName {
    switch (this) {
      case UserLevel.admin:
        return 'Administrador';
      case UserLevel.moderator:
        return 'Moderador';
      case UserLevel.user:
        return 'Usuario';
      case UserLevel.guest:
        return 'Invitado';
    }
  }

  // 🔥 NUEVO: Método para icono
  String get icon {
    switch (this) {
      case UserLevel.admin:
        return '👑';
      case UserLevel.moderator:
        return '⚙️';
      case UserLevel.user:
        return '👤';
      case UserLevel.guest:
        return '👋';
    }
  }
}
