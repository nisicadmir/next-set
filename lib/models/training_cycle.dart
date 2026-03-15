class TrainingCycle {
  final String name;
  final int repeats;

  TrainingCycle({required this.name, required this.repeats});

  factory TrainingCycle.fromJson(Map<String, dynamic> json) {
    return TrainingCycle(
      name: json['name'] as String,
      repeats: json['repeats'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'repeats': repeats};
  }

  TrainingCycle copyWith({String? name, int? repeats}) {
    return TrainingCycle(
      name: name ?? this.name,
      repeats: repeats ?? this.repeats,
    );
  }
}
