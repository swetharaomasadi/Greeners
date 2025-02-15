import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

class ExpendituresRecord extends StatefulWidget {
  final String partner;

  const ExpendituresRecord({super.key, required this.partner});

  @override
  _ExpendituresRecordState createState() => _ExpendituresRecordState();
}

class _ExpendituresRecordState extends State<ExpendituresRecord> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  int? _activeFieldIndex;
  String? _amountError;
  bool _isButtonEnabled = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();

    _descriptionController.addListener(_validateFields);
    _amountController.addListener(_validateFields);
    _cropController.addListener(_validateFields);
  }

  @override
  void dispose() {
    _speech.stop();
    _descriptionController.dispose();
    _amountController.dispose();
    _cropController.dispose();
    super.dispose();
  }

  void _validateFields() {
    setState(() {
      _isButtonEnabled = _descriptionController.text.isNotEmpty &&
          _amountController.text.isNotEmpty &&
          _cropController.text.isNotEmpty &&
          isValidNumber(_amountController.text);
    });
  }

  bool isValidNumber(String value) {
    return RegExp(r'^[0-9]+(\.[0-9]*)?$').hasMatch(value);
  }

  Future<void> _startListening(int fieldIndex) async {
    if (_isListening) return;

    bool available = await _speech.initialize(
      onError: (error) {
        if (mounted) {
          setState(() => _isListening = false);
        }
      },
      onStatus: (status) {
        if (status == "notListening" && mounted) {
          setState(() {
            _isListening = false;
            _activeFieldIndex = null;
          });
        }
      },
    );

    if (!available) return;

    if (mounted) {
      setState(() {
        _isListening = true;
        _activeFieldIndex = fieldIndex;
      });
    }

    _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty && mounted) {
          setState(() {
            _getController(fieldIndex).text = result.recognizedWords.toLowerCase();
          });
        }
      },
      listenMode: stt.ListenMode.dictation,
      partialResults: false,
      pauseFor: Duration(seconds: 2),
      onSoundLevelChange: (level) {
        if (level < 0.1) {
          Future.delayed(Duration(seconds: 2), () {
            if (_isListening) _stopListening();
          });
        }
      },
    );
  }

  void _stopListening() async {
    if (_isListening) {
      await _speech.stop();
      if (mounted) {
        setState(() {
          _isListening = false;
          _activeFieldIndex = null;
        });
      }
    }
  }

  TextEditingController _getController(int fieldIndex) {
    switch (fieldIndex) {
      case 0:
        return _cropController;
      case 1:
        return _descriptionController;
      case 2:
        return _amountController;
      default:
        throw Exception("Invalid field index");
    }
  }

  void _submitExpenditure() {
    if (!_isButtonEnabled) return;

    String description = _descriptionController.text.trim().toLowerCase();
    String amountText = _amountController.text.trim();
    String cropName = _cropController.text.trim().toLowerCase();

    setState(() {
      _amountError = isValidNumber(amountText) ? null : "Enter a valid numeric amount";
    });

    if (description.isNotEmpty && cropName.isNotEmpty && _amountError == null && user != null) {
      _showConfirmationDialog(description, amountText, cropName);
    }
  }

  void _showConfirmationDialog(String description, String amount, String cropName) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Confirm Submission'),
          content: Text(
            'Crop Name: $cropName\n'
            'Description: $description\n'
            'Amount: $amount',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.of(context).pop();

                try {
                  await FirebaseFirestore.instance.collection('expenditures').add({
                    'user_id': user!.uid,
                    'description': description,
                    'amount': double.tryParse(amount) ?? 0.0,
                    'partner': widget.partner,
                    'crop_name': cropName,
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  _descriptionController.clear();
                  _amountController.clear();
                  _cropController.clear();

                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Expenditure added successfully!')),
                    );
                  }

                  setState(() {
                    _isButtonEnabled = false;
                  });
                } catch (e) {
                  if (mounted) {
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error adding expenditure: $e')),
                    );
                  }
                }
              },
              child: Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, int index, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
                  inputFormatters: isNumeric
                      ? [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))]
                      : [],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                    errorText: isNumeric && _amountError != null ? _amountError : null,
                  ),
                ),
              ),
              IconButton(
                icon: Icon(Icons.mic, color: (_isListening && _activeFieldIndex == index) ? Colors.red : Colors.blue),
                onPressed: () {
                  if (_isListening && _activeFieldIndex == index) {
                    _stopListening();
                  } else {
                    _startListening(index);
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Enter Expenditures")),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildTextField("Crop Name", _cropController, 0),
            _buildTextField("Description", _descriptionController, 1),
            _buildTextField("Amount", _amountController, 2, isNumeric: true),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isButtonEnabled ? _submitExpenditure : null,
              child: Text("Submit"),
            ),
          ],
        ),
      ),
    );
  }
}
