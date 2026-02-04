class ContactModel {
  final String? id;
  final String name;
  final String phone;
  final String relation;
  final bool trusted;
  final DateTime createdAt;

  ContactModel({
    this.id,
    required this.name,
    required this.phone,
    this.relation = '',
    this.trusted = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'relation': relation,
        'trusted': trusted,
        'createdAt': createdAt.toIso8601String(),
      };

  factory ContactModel.fromJson(Map<String, dynamic> json) {
    return ContactModel(
      id: json['id'] as String?,
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
      trusted: (json['trusted'] ?? false) as bool,
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
    );
  }
}
