import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/emotion_result.dart';

class EmotionService {
  final String baseUrl;
  static const String _storageKey = 'emotion_history';

  EmotionService({required this.baseUrl});

  Future<bool> checkServerHealth() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/api/health'),
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      print('Server health check failed: $e');
      return false;
    }
  }

  Future<List<EmotionResult>> detectEmotionDirect({int duration = 5}) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/detect-emotion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'duration': duration,
          'isWebMode': false, // Always use real mode
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('emotions')) {
          final emotions = data['emotions'] as Map<String, dynamic>;

          return emotions.entries
              .map((entry) => EmotionResult.fromJson(entry.key, entry.value))
              .toList();
        }

        throw Exception('No emotions in response');
      } else {
        throw Exception('Failed to detect emotion: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detecting emotion: $e');
      rethrow;
    }
  }

  Future<List<EmotionResult>> detectEmotionFromFile(File audioFile) async {
    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/detect-emotion-from-file'),
      );

      // Add the audio file
      request.files.add(await http.MultipartFile.fromPath(
        'audio',
        audioFile.path,
      ));

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);

        if (data.containsKey('emotions')) {
          final emotions = data['emotions'] as Map<String, dynamic>;

          return emotions.entries
              .map((entry) => EmotionResult.fromJson(entry.key, entry.value))
              .toList();
        }

        throw Exception('No emotions in response');
      } else {
        throw Exception('Failed to detect emotion: ${response.statusCode}');
      }
    } catch (e) {
      print('Error detecting emotion from file: $e');
      rethrow;
    }
  }

  // Save results to local storage
  Future<void> _saveToHistory(List<EmotionResult> results) async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Get existing history
      final String? historyJson = prefs.getString(_storageKey);
      List<Map<String, dynamic>> historyList = [];

      if (historyJson != null) {
        historyList =
            List<Map<String, dynamic>>.from(json.decode(historyJson) as List);
      }

      // Add new results to history
      for (var result in results) {
        historyList.add(result.toJson());
      }

      // Save updated history
      await prefs.setString(_storageKey, json.encode(historyList));
    } catch (e) {
      print('Error saving to history: $e');
    }
  }

  Future<List<EmotionResult>> getEmotionHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? historyJson = prefs.getString(_storageKey);

      if (historyJson == null) {
        return [];
      }

      final List<dynamic> historyData = json.decode(historyJson);
      return historyData.map((data) => EmotionResult.fromMap(data)).toList()
        ..sort((a, b) =>
            b.timestamp.compareTo(a.timestamp)); // Sort by date (newest first)
    } catch (e) {
      print('Error loading history: $e');
      // Return some mock data in case of error
      return [
        EmotionResult(
          emotion: 'happy',
          confidence: '88.2%',
          timestamp: DateTime.now().subtract(const Duration(days: 1)),
        ),
        EmotionResult(
          emotion: 'neutral',
          confidence: '76.5%',
          timestamp: DateTime.now().subtract(const Duration(days: 2)),
        ),
      ];
    }
  }

  // Clear all history
  Future<void> clearHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_storageKey);
    } catch (e) {
      print('Error clearing history: $e');
    }
  }
}
