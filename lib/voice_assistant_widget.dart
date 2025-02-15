import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'voice_assistant_provider.dart';

class VoiceAssistantWidget extends StatelessWidget {
  final String promptText; // Dynamic prompt for the field
  final Function(String) onTextCaptured; // Callback when text is recognized

  const VoiceAssistantWidget({
    Key? key,
    required this.promptText,
    required this.onTextCaptured,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final voiceAssistant = Provider.of<VoiceAssistantProvider>(context);

    return IconButton(
      icon: Icon(
        voiceAssistant.isListening ? Icons.mic : Icons.mic_none,
        color: voiceAssistant.isListening ? Colors.red : Colors.blue,
      ),
      onPressed: () {
        if (voiceAssistant.isListening) {
          voiceAssistant.stopListening();
        } else {
          voiceAssistant.startListening(
            prompt: promptText,
            onTextRecognized: onTextCaptured, // Assigns recognized text to the field
          );
        }
      },
    );
  }
}
