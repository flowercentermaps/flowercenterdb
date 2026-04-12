/// Typed entity for a row in the `profiles` table.
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String role; // 'admin' | 'sales' | 'viewer' | 'accountant'
  final bool isActive;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.isActive,
  });

  bool get isAdmin => role == 'admin';
  bool get isSales => role == 'sales';
  bool get isViewer => role == 'viewer';
  bool get isAccountant => role == 'accountant';
  bool get canEdit => isAdmin || isSales;
  bool get isReadOnly => isViewer || isAccountant;

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: (map['id'] ?? '').toString(),
        email: (map['email'] ?? '').toString(),
        name: (map['full_name'] ?? map['name'] ?? '').toString().trim(),
        role: (map['role'] ?? '').toString().trim().toLowerCase(),
        isActive: map['is_active'] == true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'email': email,
        'full_name': name,
        'role': role,
        'is_active': isActive,
      };

  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? role,
    bool? isActive,
  }) =>
      UserProfile(
        id: id ?? this.id,
        email: email ?? this.email,
        name: name ?? this.name,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
      );
}
