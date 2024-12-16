// api_service.dart
import 'package:http/http.dart' as http;
import 'dart:convert';

class ApiService {
  final String baseUrl = 'http://your-laravel-api.com/api';

  Future<Map<String, dynamic>> scheduleTransfer({
    required String senderId,
    required String receiverId,
    required double amount,
    required DateTime executionDate,
    required String frequency,
    required bool feesPaidBySender,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/scheduled-transfers'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'sender_id': senderId,
          'receiver_id': receiverId,
          'amount': amount,
          'execution_date': executionDate.toIso8601String(),
          'frequency': frequency,
          'fees_paid_by_sender': feesPaidBySender,
        }),
      );

      if (response.statusCode == 201) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Échec de la planification du transfert');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }

  Future<List<Map<String, dynamic>>> getScheduledTransfers(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/scheduled-transfers/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      } else {
        throw Exception('Échec de récupération des transferts planifiés');
      }
    } catch (e) {
      throw Exception('Erreur de connexion: $e');
    }
  }
}
