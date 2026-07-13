/// ============================================================================
/// USER MODEL - Model nhân viên thu nước
/// ============================================================================
/// PROPERTIES: id, username, password, fullName, areaCode, areaName
/// METHODS:
/// - fromMap(): Chuyển Map → User (đọc từ DB/Firestore)
/// - toMap(): Chuyển User → Map (lưu vào DB)
/// - copyWith(): Tạo bản sao với thay đổi
/// ============================================================================

/// Model cho User (nhan vien).
class User {
  final int? id;
  final String username;
  final String password;
  final String fullName;
  final String role; // Luon la 'staff'
  final String areaCode;
  final String areaName;
  final DateTime createdAt;

  User({
    this.id,
    required this.username,
    required this.password,
    required this.fullName,
    this.role = 'staff',
    required this.areaCode,
    required this.areaName,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Chuyen tu Map (database) sang User object.
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'] as int?,
      username: map['username'] as String,
      password: map['password'] as String,
      fullName: map['fullName'] as String,
      role: map['role'] as String? ?? 'staff',
      areaCode: map['areaCode'] as String? ?? '',
      areaName: map['areaName'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }

  /// Chuyen tu User object sang Map de luu database.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'password': password,
      'fullName': fullName,
      'role': role,
      'areaCode': areaCode,
      'areaName': areaName,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Copy object voi mot so field thay doi.
  User copyWith({
    int? id,
    String? username,
    String? password,
    String? fullName,
    String? role,
    String? areaCode,
    String? areaName,
    DateTime? createdAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      areaCode: areaCode ?? this.areaCode,
      areaName: areaName ?? this.areaName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
