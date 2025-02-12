import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'home.dart';
import 'search.dart';
import 'add.dart';
import 'settings.dart';
import 'recent_records_page.dart';
import 'edit_dues_page.dart';

class VoiceAssistantProvider extends ChangeNotifier {
  final stt.SpeechToText _speech = stt.SpeechToText();
  final FlutterTts _tts = FlutterTts();
  bool isListening = false;
  String recognizedText = "";

  VoiceAssistantProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _speech.initialize();
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.8);
    await _tts.setPitch(1.2);
  }

  void startListening(BuildContext context) async {
    if (!isListening) {
      isListening = true;
      recognizedText = "Listening...";
      notifyListeners();

      await _tts.speak("Hello! How can I help you?");
      await Future.delayed(Duration(seconds: 20));

      _speech.listen(
        onResult: (result) {
          if (result.recognizedWords.isNotEmpty) {
            recognizedText = result.recognizedWords;
            notifyListeners();
            _handleVoiceCommand(context, recognizedText);
          }
        },
      );
    }
  }

  void stopListening() {
    if (isListening) {
      isListening = false;
      recognizedText = "Turning off. Goodbye!";
      notifyListeners();
      _speech.stop();
      _tts.speak("Turning off. Goodbye!");
    }
  }

  void _handleVoiceCommand(BuildContext context, String command) async {
    command = command.toLowerCase();
    String response = "Navigating...";
    Widget? page;

    if (command.contains("home")) {
      page = HomeScreen();
      response = "Navigated to Home page.";
    } else if (command.contains("search")) {
      page = SearchScreen();
      response = "Navigated to Search";
    } else if (command.contains("add record")) {
      page = AddPage();
      response = "Navigated to Add";
    } else if (command.contains("recent records")) {
      page = RecentRecordsPage();
      response = "Navigated to see Recent Records.";
      
      
    } else if (command.contains("edit due")) {
      response = "Navigated to Edit Dues.";
      page = EditDuesPage();
    } else {
      response = "Sorry, I didn't understand the command.";
      await _tts.speak(response);
      return;
    }

    recognizedText = response;
    notifyListeners();
    await _tts.speak(response);

    // **Navigation Logic**
    Future.delayed(Duration(seconds: 2), () {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => page!),
      );
    });
  }
}

/// **Reusable Voice Assistant Widget**
class VoiceAssistantWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final voiceAssistant = Provider.of<VoiceAssistantProvider>(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: Icon(
            voiceAssistant.isListening ? Icons.mic_off : Icons.mic,
            size: 50,
            color: voiceAssistant.isListening ? Colors.red : Colors.blue,
          ),
          onPressed: () {
            if (voiceAssistant.isListening) {
              voiceAssistant.stopListening();
            } else {
              voiceAssistant.startListening(context); // Pass context for navigation
            }
          },
        ),
        SizedBox(height: 20),
        Text(
          voiceAssistant.recognizedText,
          style: TextStyle(fontSize: 18),
        ),
      ],
    );
  }
}
