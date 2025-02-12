import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'text_processor.dart'; // Import the text processor

class VoiceAssistant {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _recognizedText = "";

  VoiceAssistant() {
    _speech = stt.SpeechToText();
  }

  Future<void> startListening(Function(Map<String, String>) onDataExtracted) async {
    bool available = await _speech.initialize(
      onStatus: (status) => print("Speech Status: $status"),
      onError: (error) => print("Speech Error: $error"),
    );

    if (available) {
      _speech.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          TextProcessor processor = TextProcessor();
          Map<String, String> extractedData = processor.extractFormData(_recognizedText);
          onDataExtracted(extractedData);
        },
      );
    }
  }

  void stopListening() {
    _speech.stop();
  }
}
