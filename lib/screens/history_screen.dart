import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/emotion_result.dart';
import '../services/emotion_service.dart';

class HistoryScreen extends StatefulWidget {
  final String backendUrl;

  const HistoryScreen({Key? key, required this.backendUrl}) : super(key: key);

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  late EmotionService emotionService;
  List<EmotionResult> historyResults = [];
  bool isLoading = true;
  bool isWebMode = kIsWeb;

  @override
  void initState() {
    super.initState();
    emotionService = EmotionService(baseUrl: widget.backendUrl);
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Get emotion history
      final results = await emotionService.getEmotionHistory();

      setState(() {
        historyResults = results;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _clearHistory() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Clear History'),
          content:
              const Text('Are you sure you want to clear all emotion history?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await emotionService.clearHistory();
                await _loadHistory();

                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('History cleared successfully')),
                );
              },
              child: const Text('Clear', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Color _getEmotionColor(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Colors.amber;
      case 'sad':
        return Colors.blue;
      case 'angry':
      case 'anger':
        return Colors.red;
      case 'fear':
      case 'scared':
        return Colors.purple;
      case 'disgust':
        return Colors.green;
      case 'surprise':
      case 'surprised':
        return Colors.orange;
      case 'neutral':
        return Colors.grey;
      default:
        return Colors.teal;
    }
  }

  IconData _getEmotionIcon(String emotion) {
    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        return Icons.sentiment_very_satisfied;
      case 'sad':
        return Icons.sentiment_dissatisfied;
      case 'angry':
      case 'anger':
        return Icons.sentiment_very_dissatisfied;
      case 'fear':
      case 'scared':
        return Icons.sentiment_neutral;
      case 'disgust':
        return Icons.sick;
      case 'surprise':
      case 'surprised':
        return Icons.sentiment_satisfied_alt;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.emoji_emotions;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emotion History'),
        actions: [
          if (historyResults.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _clearHistory,
              tooltip: 'Clear History',
            ),
        ],
      ),
      body: Column(
        children: [
          // Web mode notice
          if (isWebMode)
            Container(
              width: double.infinity,
              color: Colors.blue.shade100,
              padding: const EdgeInsets.all(8),
              child: const Column(
                children: [
                  Text(
                    'Web Demo Mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'History is stored locally in your browser',
                    style: TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : historyResults.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.history,
                              size: 80,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 16),
                            Text(
                              'No emotion history available',
                              style: TextStyle(fontSize: 16),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Record your first emotion to see it here',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: historyResults.length,
                        itemBuilder: (context, index) {
                          final result = historyResults[index];
                          final dateFormat = DateFormat('MMM d, yyyy - h:mm a');

                          return Card(
                            margin: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 16,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    _getEmotionColor(result.emotion)
                                        .withOpacity(0.2),
                                child: Icon(
                                  _getEmotionIcon(result.emotion),
                                  color: _getEmotionColor(result.emotion),
                                ),
                              ),
                              title: Text(
                                result.emotion,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: _getEmotionColor(result.emotion),
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Confidence: ${result.confidence}'),
                                  Text(
                                    'Date: ${dateFormat.format(result.timestamp)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                              isThreeLine: true,
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _loadHistory,
        tooltip: 'Refresh',
        child: const Icon(Icons.refresh),
      ),
    );
  }
}
