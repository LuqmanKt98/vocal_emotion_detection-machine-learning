import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:audio_waveforms/audio_waveforms.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../models/emotion_result.dart';
import '../services/emotion_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key, required this.title}) : super(key: key);

  final String title;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Change this to your computer's IP address
  String _backendUrl = 'http://localhost:3001';
  static const String _ipKey = 'backend_ip';

  bool isRecording = false;
  bool isProcessing = false;
  bool isServerConnected = false;
  List<EmotionResult> emotionResults = [];

  // Audio recorder controller
  late RecorderController recorderController;
  late String audioFilePath;
  late EmotionService emotionService;
  final TextEditingController _ipController = TextEditingController();

  // Web-specific implementation
  bool isWebMode = kIsWeb;
  bool useRealBackend = true; // Always use real backend
  String webDemoResponse =
      '{"happy": "85.2%", "neutral": "10.5%", "sad": "4.3%"}';

  @override
  void initState() {
    super.initState();
    _loadSavedIp();
    if (!isWebMode) {
      _initRecorder();
    }
    _requestPermission();
  }

  Future<void> _loadSavedIp() async {
    final prefs = await SharedPreferences.getInstance();
    final savedIp = prefs.getString(_ipKey);
    if (savedIp != null && savedIp.isNotEmpty) {
      setState(() {
        _backendUrl = savedIp;
        _ipController.text = savedIp;
        emotionService = EmotionService(baseUrl: _backendUrl);
      });
    } else {
      emotionService = EmotionService(baseUrl: _backendUrl);
      _ipController.text = _backendUrl;
    }

    _checkServerConnection();
  }

  Future<void> _saveIp(String ip) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_ipKey, ip);
  }

  Future<void> _checkServerConnection() async {
    setState(() {
      isServerConnected = false;
    });

    if (isWebMode && !useRealBackend) {
      // In web demo mode, we'll assume the server is connected
      setState(() {
        isServerConnected = true;
      });
      return;
    }

    final isConnected = await emotionService.checkServerHealth();

    setState(() {
      isServerConnected = isConnected;
    });
  }

  void _initRecorder() async {
    if (isWebMode) return;

    recorderController = RecorderController()
      ..androidEncoder = AndroidEncoder.aac
      ..androidOutputFormat = AndroidOutputFormat.mpeg4
      ..iosEncoder = IosEncoder.kAudioFormatMPEG4AAC
      ..sampleRate = 16000;

    final tempDir = await getTemporaryDirectory();
    audioFilePath = '${tempDir.path}/recording.wav';
  }

  Future<void> _requestPermission() async {
    if (isWebMode) return;

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      // Handle permission denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission is required')),
        );
      }
    }
  }

  Future<void> _toggleRecording() async {
    if (isWebMode) {
      _handleWebRecording();
      return;
    }

    if (isRecording) {
      setState(() {
        isRecording = false;
        isProcessing = true;
      });

      await _uploadAudioAndDetectEmotion();
    } else {
      setState(() {
        isRecording = true;
        emotionResults = [];
      });

      // Simulate recording for 5 seconds, then stop automatically
      Future.delayed(const Duration(seconds: 5), () {
        if (isRecording && mounted) {
          _toggleRecording();
        }
      });
    }
  }

  // Web implementation for recording
  void _handleWebRecording() {
    if (useRealBackend) {
      _handleWebRealBackendRecording();
      return;
    }

    if (isRecording) {
      // Stop recording simulation
      setState(() {
        isRecording = false;
        isProcessing = true;
      });

      // Simulate processing delay
      Timer(const Duration(seconds: 2), () {
        _simulateEmotionDetection();
      });
    } else {
      // Start recording simulation
      setState(() {
        isRecording = true;
        emotionResults = [];
      });
    }
  }

  // Web implementation that uses the real backend
  void _handleWebRealBackendRecording() {
    if (isRecording) {
      // Stop recording
      setState(() {
        isRecording = false;
        isProcessing = true;
      });

      // Call the API with real audio data
      _callEmotionDetectionApi();
    } else {
      // Start recording
      setState(() {
        isRecording = true;
        emotionResults = [];
      });
    }
  }

  // Call the API directly for web mode
  Future<void> _callEmotionDetectionApi() async {
    try {
      final response = await http.post(
        Uri.parse('$_backendUrl/api/detect-emotion'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'duration': 5,
          'isWebMode': false
        }), // Set isWebMode to false to force real recording
      );

      if (response.statusCode == 200) {
        final result = json.decode(response.body);
        final emotions = result['emotions'] as Map<String, dynamic>;

        final results = emotions.entries
            .map((entry) => EmotionResult.fromJson(entry.key, entry.value))
            .toList();

        setState(() {
          emotionResults = results;
          isProcessing = false;
        });
      } else {
        throw Exception('Failed to detect emotion: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _simulateEmotionDetection() {
    try {
      // Parse demo response
      final Map<String, dynamic> emotions = json.decode(webDemoResponse);

      final results = emotions.entries
          .map((entry) => EmotionResult.fromJson(entry.key, entry.value))
          .toList();

      setState(() {
        emotionResults = results;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _uploadAudioAndDetectEmotion() async {
    if (isWebMode) {
      _simulateEmotionDetection();
      return;
    }

    try {
      // For Flutter, we'll now use the direct emotion detection method
      // This lets the Python backend handle the recording
      setState(() {
        isProcessing = true;
      });

      final results = await emotionService.detectEmotionDirect(duration: 5);

      setState(() {
        emotionResults = results;
        isProcessing = false;
      });
    } catch (e) {
      setState(() {
        isProcessing = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  void _showIpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Server Configuration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter your backend server IP address and port:'),
            const SizedBox(height: 12),
            TextField(
              controller: _ipController,
              decoration: const InputDecoration(
                labelText: 'Backend URL',
                hintText: 'http://localhost:3001',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Save'),
            onPressed: () async {
              final newUrl = _ipController.text.trim();
              if (newUrl.isNotEmpty) {
                setState(() {
                  _backendUrl = newUrl;
                  emotionService = EmotionService(baseUrl: _backendUrl);
                });
                await _saveIp(newUrl);
                await _checkServerConnection();
                Navigator.of(context).pop();
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmotionCard(EmotionResult result) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            _getEmotionIcon(result.emotion),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.emotion,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'Confidence: ${result.confidence}',
                    style: const TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getEmotionIcon(String emotion) {
    IconData iconData;
    Color iconColor;

    switch (emotion.toLowerCase()) {
      case 'happy':
      case 'joy':
        iconData = Icons.sentiment_very_satisfied;
        iconColor = Colors.amber;
        break;
      case 'sad':
        iconData = Icons.sentiment_dissatisfied;
        iconColor = Colors.blue;
        break;
      case 'angry':
      case 'anger':
        iconData = Icons.sentiment_very_dissatisfied;
        iconColor = Colors.red;
        break;
      case 'fear':
      case 'scared':
        iconData = Icons.sentiment_neutral;
        iconColor = Colors.purple;
        break;
      case 'disgust':
        iconData = Icons.sick;
        iconColor = Colors.green;
        break;
      case 'surprise':
      case 'surprised':
        iconData = Icons.sentiment_satisfied_alt;
        iconColor = Colors.orange;
        break;
      case 'neutral':
        iconData = Icons.sentiment_neutral;
        iconColor = Colors.grey;
        break;
      default:
        iconData = Icons.emoji_emotions;
        iconColor = Colors.teal;
    }

    return Icon(
      iconData,
      size: 48,
      color: iconColor,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: Icon(
              isServerConnected ? Icons.cloud_done : Icons.cloud_off,
              color: isServerConnected ? Colors.green : Colors.red,
            ),
            onPressed: _checkServerConnection,
            tooltip:
                isServerConnected ? 'Server connected' : 'Server disconnected',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _showIpDialog,
            tooltip: 'Server Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Connection status
          if (!isServerConnected && !isWebMode)
            Container(
              width: double.infinity,
              color: Colors.red.shade100,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  const Text(
                    '⚠️ Server not connected',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.red, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Current URL: $_backendUrl',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.red.shade800, fontSize: 12),
                  ),
                  TextButton(
                    onPressed: _showIpDialog,
                    child: const Text('Configure Server'),
                  ),
                ],
              ),
            ),

          // Web mode notice
          if (isWebMode)
            Container(
              width: double.infinity,
              color:
                  useRealBackend ? Colors.green.shade100 : Colors.blue.shade100,
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    useRealBackend
                        ? 'Web Mode - Real Backend'
                        : 'Web Demo Mode',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color:
                          useRealBackend ? Colors.green.shade900 : Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    useRealBackend
                        ? 'Using the actual Python script through backend API'
                        : 'Running in browser with simulated responses',
                    style: const TextStyle(fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

          // Audio recorder visualization
          Container(
            height: 200,
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: isWebMode
                ? Center(
                    child: isRecording
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.mic,
                                color: Colors.red,
                                size: 60,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Recording...',
                                style: TextStyle(
                                  color: Colors.red.shade800,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          )
                        : const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.mic_none,
                                color: Colors.grey,
                                size: 60,
                              ),
                              SizedBox(height: 16),
                              Text('Ready to record'),
                            ],
                          ),
                  )
                : AudioWaveforms(
                    enableGesture: true,
                    size: Size(MediaQuery.of(context).size.width - 32, 200),
                    recorderController: recorderController,
                    waveStyle: const WaveStyle(
                      waveColor: Colors.deepPurple,
                      extendWaveform: true,
                      showMiddleLine: false,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12.0),
                      color: Colors.grey[200],
                    ),
                    padding: const EdgeInsets.only(left: 18),
                    margin: const EdgeInsets.symmetric(horizontal: 15),
                  ),
          ),

          // Status text
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              isRecording
                  ? 'Recording...'
                  : isProcessing
                      ? 'Processing...'
                      : emotionResults.isNotEmpty
                          ? 'Detected Emotions:'
                          : 'Tap the button to start recording',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          // Results
          Expanded(
            child: isProcessing
                ? const Center(child: CircularProgressIndicator())
                : emotionResults.isEmpty
                    ? Center(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.mic_none,
                                size: 80,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              const Text('No emotion detected yet'),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: (!isServerConnected && !isWebMode)
                                    ? null
                                    : _toggleRecording,
                                icon: const Icon(Icons.mic),
                                label: const Text('Start Recording'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: emotionResults.length,
                        itemBuilder: (context, index) {
                          return _buildEmotionCard(emotionResults[index]);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: isProcessing || (!isServerConnected && !isWebMode)
            ? null
            : _toggleRecording,
        tooltip: isRecording ? 'Stop Recording' : 'Start Recording',
        backgroundColor: isRecording ? Colors.red : Colors.deepPurple,
        child: Icon(
          isRecording ? Icons.stop : Icons.mic,
          color: Colors.white,
        ),
      ),
    );
  }

  @override
  void dispose() {
    if (!isWebMode) {
      recorderController.dispose();
    }
    _ipController.dispose();
    super.dispose();
  }
}
