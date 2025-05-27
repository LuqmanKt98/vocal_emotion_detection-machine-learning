class EmotionResult {
  final String emotion;
  final String confidence;
  final DateTime timestamp;

  EmotionResult({
    required this.emotion,
    required this.confidence,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  factory EmotionResult.fromJson(String emotion, String confidence) {
    return EmotionResult(
      emotion: emotion,
      confidence: confidence,
    );
  }

  // For local storage (shared preferences)
  Map<String, dynamic> toJson() {
    return {
      'emotion': emotion,
      'confidence': confidence,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Create from a Map (for local storage)
  factory EmotionResult.fromMap(Map<String, dynamic> map) {
    return EmotionResult(
      emotion: map['emotion'],
      confidence: map['confidence'],
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp']),
    );
  }

  double get confidenceValue {
    // Extract numeric value from confidence string (e.g., "85.5%" -> 85.5)
    final numStr = confidence.replaceAll(RegExp(r'[^0-9.]'), '');
    return double.tryParse(numStr) ?? 0.0;
  }
}
