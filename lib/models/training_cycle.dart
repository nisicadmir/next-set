class TrainingCycle {
  final String name;
  final int sets;
  final int repeats;
  final String? description;

  TrainingCycle({
    required this.name,
    this.sets = 1,
    required this.repeats,
    this.description,
  });

  factory TrainingCycle.fromJson(Map<String, dynamic> json) {
    return TrainingCycle(
      name: json['name'] as String,
      sets: json['sets'] as int? ?? 1,
      repeats: (json['reps'] as int?) ?? json['repeats'] as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'name': name,
      'sets': sets,
      'repeats': repeats,
    };
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    return map;
  }

  TrainingCycle copyWith({
    String? name,
    int? sets,
    int? repeats,
    String? description,
  }) {
    return TrainingCycle(
      name: name ?? this.name,
      sets: sets ?? this.sets,
      repeats: repeats ?? this.repeats,
      description: description ?? this.description,
    );
  }
}
