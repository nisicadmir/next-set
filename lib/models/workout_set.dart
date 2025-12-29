class WorkoutSet {
  final String id;
  final String name;
  final int numberOfSets;
  final int secondsPerSet;
  final int breakSeconds;
  final bool shouldNotifyEndOfSet;
  final bool shouldNotifyEndOfBreak;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;

  WorkoutSet({
    required this.id,
    required this.name,
    required this.numberOfSets,
    required this.secondsPerSet,
    required this.breakSeconds,
    required this.shouldNotifyEndOfSet,
    required this.shouldNotifyEndOfBreak,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  // Create from JSON
  factory WorkoutSet.fromJson(Map<String, dynamic> json) {
    return WorkoutSet(
      id: json['id'] as String,
      name: json['name'] as String,
      numberOfSets: json['numberOfSets'] as int,
      secondsPerSet: json['secondsPerSet'] as int,
      breakSeconds: json['breakSeconds'] as int? ?? 0,
      shouldNotifyEndOfSet: json['shouldNotifyEndOfSet'] as bool? ?? false,
      shouldNotifyEndOfBreak: json['shouldNotifyEndOfBreak'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastUsedAt: json['lastUsedAt'] != null
          ? DateTime.parse(json['lastUsedAt'] as String)
          : null,
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'numberOfSets': numberOfSets,
      'secondsPerSet': secondsPerSet,
      'breakSeconds': breakSeconds,
      'shouldNotifyEndOfSet': shouldNotifyEndOfSet,
      'shouldNotifyEndOfBreak': shouldNotifyEndOfBreak,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  // Create a copy with updated fields
  WorkoutSet copyWith({
    String? id,
    String? name,
    int? numberOfSets,
    int? secondsPerSet,
    int? breakSeconds,
    bool? shouldNotifyEndOfSet,
    bool? shouldNotifyEndOfBreak,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return WorkoutSet(
      id: id ?? this.id,
      name: name ?? this.name,
      numberOfSets: numberOfSets ?? this.numberOfSets,
      secondsPerSet: secondsPerSet ?? this.secondsPerSet,
      breakSeconds: breakSeconds ?? this.breakSeconds,
      shouldNotifyEndOfSet: shouldNotifyEndOfSet ?? this.shouldNotifyEndOfSet,
      shouldNotifyEndOfBreak:
          shouldNotifyEndOfBreak ?? this.shouldNotifyEndOfBreak,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }
}
