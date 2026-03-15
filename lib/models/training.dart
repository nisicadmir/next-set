import 'training_cycle.dart';

class Training {
  final String id;
  final String name;
  final List<TrainingCycle> cycles;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastUsedAt;

  Training({
    required this.id,
    required this.name,
    required this.cycles,
    required this.createdAt,
    required this.updatedAt,
    this.lastUsedAt,
  });

  factory Training.fromJson(Map<String, dynamic> json) {
    return Training(
      id: json['id'] as String,
      name: json['name'] as String,
      cycles:
          (json['cycles'] as List<dynamic>)
              .map((c) => TrainingCycle.fromJson(c as Map<String, dynamic>))
              .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
      lastUsedAt:
          json['lastUsedAt'] != null
              ? DateTime.parse(json['lastUsedAt'] as String)
              : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'cycles': cycles.map((c) => c.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastUsedAt': lastUsedAt?.toIso8601String(),
    };
  }

  Training copyWith({
    String? id,
    String? name,
    List<TrainingCycle>? cycles,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastUsedAt,
  }) {
    return Training(
      id: id ?? this.id,
      name: name ?? this.name,
      cycles: cycles ?? this.cycles,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastUsedAt: lastUsedAt ?? this.lastUsedAt,
    );
  }

  int get totalRepeats => cycles.fold(0, (sum, c) => sum + c.repeats);
}
