import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/health_log_model.dart';
import '../models/cycle_model.dart';

class AiService {
  final String baseUrl;

  AiService({this.baseUrl = 'http://localhost:8001'});

  Future<String> generateInsights(List<HealthLogModel> logs, List<CycleModel> cycles) async {
    final url = Uri.parse('$baseUrl/ai/insights');
    final body = {
      'logs': logs.map((l) => l.toJson()).toList(),
      'cycles': cycles.map((c) => c.toJson()).toList(),
    };

    final resp = await http.post(url, headers: {'Content-Type': 'application/json'}, body: jsonEncode(body));
    if (resp.statusCode != 200) throw Exception('AI server error: ${resp.body}');
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    return data['insights'] as String? ?? '';
  }
}
