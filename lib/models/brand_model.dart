class Brand {
  final String id;
  final String name;
  final String? imageUrl;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Brand({
    required this.id,
    required this.name,
    this.imageUrl,
    this.createdAt,
    this.updatedAt,
  });

  factory Brand.fromMap(Map<String, dynamic> map) {
    return Brand(
      id: map['id'],
      name: map['name'],
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null ? DateTime.parse(map['createdAt']) : null,
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Brand copyWith({
    String? id,
    String? name,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Brand(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Brand &&
        other.id == id &&
        other.name == name &&
        other.imageUrl == imageUrl;
  }

  @override
  int get hashCode => Object.hash(id, name, imageUrl);
}
