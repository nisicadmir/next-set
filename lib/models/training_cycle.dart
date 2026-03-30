class TrainingCycle {
  final String name;
  final int repeats;
  final String? description;

  TrainingCycle({required this.name, required this.repeats, this.description});

  factory TrainingCycle.fromJson(Map<String, dynamic> json) {
    return TrainingCycle(
      name: json['name'] as String,
      repeats: json['repeats'] as int,
      description: json['description'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{'name': name, 'repeats': repeats};
    if (description != null && description!.isNotEmpty) {
      map['description'] = description;
    }
    return map;
  }

  TrainingCycle copyWith({String? name, int? repeats, String? description}) {
    return TrainingCycle(
      name: name ?? this.name,
      repeats: repeats ?? this.repeats,
      description: description ?? this.description,
    );
  }
}
