import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class VoiceAssistantProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();

  bool _isListening = false;
  String _recognizedText = "";
  Function(String)? _onTextRecognized; // Callback to update a specific field

  bool get isListening => _isListening;
  String get recognizedText => _recognizedText;

  void startListening({required String prompt, required Function(String) onTextRecognized}) async {
    _onTextRecognized = onTextRecognized;
    
    // Speak the prompt before listening
    await _tts.speak(prompt);

    bool available = await _speech.initialize();
    if (available) {
      _isListening = true;
      notifyListeners();

      _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          notifyListeners();
        },
        onSoundLevelChange: (level) {
          if (level == 0.0) {
            stopListening();
          }
        },
        listenFor: Duration(seconds: 5),
        pauseFor: Duration(seconds: 2),
      );
    }
  }

  void stopListening() {
    if (_isListening) {
      _isListening = false;
      _speech.stop();
      notifyListeners();

      if (_onTextRecognized != null && _recognizedText.isNotEmpty) {
        _onTextRecognized!(_recognizedText); // Pass recognized text to the field
      }
    }
  }

  void resetText() {
    _recognizedText = "";
    notifyListeners();
  }
}
