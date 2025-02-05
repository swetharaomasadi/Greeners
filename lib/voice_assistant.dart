import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class VoiceAssistant extends StatefulWidget {
  @override
  _VoiceAssistantState createState() => _VoiceAssistantState();
}

class _VoiceAssistantState extends State<VoiceAssistant> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool _isListening = false;
  Timer? _autoTurnOffTimer;

  @override
  void initState() {
    super.initState();
    initialize();
  }

  Future<void> initialize() async {
    await _speech.initialize();
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.8);
    await _tts.setPitch(1.5);

  }

  void resetAutoTurnOffTimer() {
    _autoTurnOffTimer?.cancel();
    _autoTurnOffTimer = Timer(Duration(minutes: 3), stopListening);
  }

  void startListening() async {
    if (!_isListening) {
      setState(() => _isListening = true);
      await _tts.speak("Hello! How can I help you?");
      
      _speech.listen(
        onResult: (result) {
          print("Recognized: ${result.recognizedWords}");
          resetAutoTurnOffTimer(); // Now, it is correctly declared before use
        },
      );
      
      resetAutoTurnOffTimer(); // Now, it is correctly declared before use
    }
  }

  void stopListening() {
    if (_isListening) {
      setState(() => _isListening = false);
      _speech.stop();
      _tts.speak("Turning off. Goodbye!");
      _autoTurnOffTimer?.cancel();
    }
  }

  @override
  Widget build(BuildContext context) {
  return Center(
    child: IconButton(
      icon: Icon(
        _isListening ? Icons.voice_chat : Icons.record_voice_over,
        size: 90, // Medium size
        color: _isListening ? Colors.red : Colors.blue,
      ),
      onPressed: () {
        if (_isListening) {
          stopListening();
        } else {
          startListening();
        }
      },
    ),
  );
}
}