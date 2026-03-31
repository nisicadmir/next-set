import 'training_cycle.dart';

class TrainingTemplate {
  final String name;
  final List<TrainingCycle> cycles;

  TrainingTemplate({required this.name, required this.cycles});

  factory TrainingTemplate.fromJson(Map<String, dynamic> json) {
    return TrainingTemplate(
      name: json['name'] as String,
      cycles:
          (json['cycles'] as List<dynamic>)
              .map((c) => TrainingCycle.fromJson(c as Map<String, dynamic>))
              .toList(),
    );
  }
}
