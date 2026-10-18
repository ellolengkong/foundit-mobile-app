/// Contact details from DATA_MODEL.md §4.2 (`user_contacts`).
class UserContact {
  const UserContact({
    required this.userId,
    this.whatsappNumber,
    this.allowWhatsappContact = false,
    required this.updatedAt,
  });

  /// Maps to `user_contacts.user_id` (FK to auth.users.id).
  final String userId;

  /// Indonesian phone number for WhatsApp verification.
  final String? whatsappNumber;

  /// Explicit user opt-in required by PRD §4.7.
  final bool allowWhatsappContact;

  final DateTime updatedAt;

  UserContact copyWith({
    String? userId,
    String? whatsappNumber,
    bool? allowWhatsappContact,
    DateTime? updatedAt,
  }) {
    return UserContact(
      userId: userId ?? this.userId,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      allowWhatsappContact: allowWhatsappContact ?? this.allowWhatsappContact,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// User profile from DATA_MODEL.md §4.1 (`profiles`).
///
/// Mirrors the `profiles` table. Role is always `user` for normal accounts
/// and can only be changed to `admin` through trusted server-side operations.
class UserProfile {
  const UserProfile({
    required this.id,
    required this.fullName,
    this.email,
    this.role = 'user',
    this.contact,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Maps to `auth.users.id`.
  final String id;

  /// Display name, 2–80 characters recommended.
  final String fullName;

  /// User email from auth session.
  final String? email;

  /// `user` or `admin`. Default `user`; never set by the client.
  final String role;

  /// Optional private contact details from `user_contacts`.
  final UserContact? contact;

  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == 'admin';

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? role,
    UserContact? contact,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      role: role ?? this.role,
      contact: contact ?? this.contact,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
