import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/training_template.dart';

const String kTemplateUrl =
    'https://raw.githubusercontent.com/nisicadmir/next-set/refs/heads/main/training-set-v1.json';

class TemplateService {
  Future<List<TrainingTemplate>> fetchTemplates() async {
    final response = await http.get(Uri.parse(kTemplateUrl));

    if (response.statusCode != 200) {
      throw Exception('Failed to load templates (HTTP ${response.statusCode})');
    }

    final Map<String, dynamic> body = jsonDecode(response.body);
    final List<dynamic> raw = body['templates'] as List<dynamic>;
    return raw
        .map(
          (t) => TrainingTemplate.fromJson(
            _normalizeTemplateJson(t as Map<String, dynamic>),
          ),
        )
        .toList();
  }

  Map<String, dynamic> _normalizeTemplateJson(Map<String, dynamic> template) {
    return {
      ...template,
      'cycles': (template['cycles'] as List<dynamic>).map((cycle) {
        final cycleJson = cycle as Map<String, dynamic>;
        return {
          ...cycleJson,
          'sets': cycleJson['sets'] as int? ?? 1,
          'repeats': (cycleJson['reps'] as int?) ?? cycleJson['repeats'] as int,
        };
      }).toList(),
    };
  }
}
