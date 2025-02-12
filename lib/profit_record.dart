import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';

class ProfitRecord extends StatefulWidget {
  final String partner;
  const ProfitRecord({super.key, required this.partner});

  @override
  _ProfitRecordScreenState createState() => _ProfitRecordScreenState();
}

class _ProfitRecordScreenState extends State<ProfitRecord> {
  final _vendorController = TextEditingController();
  final _itemController = TextEditingController();
  final _kgsController = TextEditingController();
  final _costController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late stt.SpeechToText _speech;
  late FlutterTts _tts;
  bool _isListening = false;
  String _assistantMessage = "Tap the mic to start voice input.";
  int _currentFieldIndex = 0;

  final List<String> _fieldPrompts = [
    "Please say the vendor name.",
    "Please say the crop name.",
    "Please say the quantity in kgs or items.",
    "Please say the cost per kg or item.",
    "Please say the amount paid."
  ];
  final List<TextEditingController> _controllers = [];
  double _totalBill = 0.0;
  bool _isSubmitEnabled = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _tts = FlutterTts();
    _controllers.addAll([
      _vendorController,
      _itemController,
      _kgsController,
      _costController,
      _amountPaidController
    ]);
  }

  void _calculateTotalBill() {
    final kgs = double.tryParse(_kgsController.text) ?? 0.0;
    final costPerKg = double.tryParse(_costController.text) ?? 0.0;
    setState(() {
      _totalBill = kgs * costPerKg;
    });
    _validateForm();
  }

  void _validateForm() {
    setState(() {
      _isSubmitEnabled = _controllers.every((controller) => controller.text.isNotEmpty);
    });
  }

  Future<void> _submitRecord() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    await _firestore.collection('records').add({
      'user_id': user.uid,
      'partner': widget.partner,
      'vendor': _vendorController.text,
      'item': _itemController.text,
      'kgs': double.tryParse(_kgsController.text) ?? 0.0,
      'cost_per_kg': double.tryParse(_costController.text) ?? 0.0,
      'total_bill': _totalBill,
      'amount_paid': double.tryParse(_amountPaidController.text) ?? 0.0,
      'due_amount': _totalBill - (double.tryParse(_amountPaidController.text) ?? 0.0),
      'timestamp': FieldValue.serverTimestamp(),
    });
    _clearForm();
  }

  void _clearForm() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _totalBill = 0.0;
      _isSubmitEnabled = false;
    });
  }

  void _startVoiceAssistant() async {
    if (_isListening) return;

    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
        _currentFieldIndex = 0;
      });
      _askNextField();
    }
  }

  void _askNextField() async {
    if (_currentFieldIndex < _fieldPrompts.length) {
      setState(() {
        _assistantMessage = _fieldPrompts[_currentFieldIndex];
      });
      await _speak(_fieldPrompts[_currentFieldIndex]);
    } else {
      setState(() {
        _isListening = false;
        _assistantMessage = "Voice input complete!";
      });
      _calculateTotalBill();
      _validateForm();
    }
  }

  Future<void> _speak(String text) async {
    await _tts.speak(text);
    await Future.delayed(const Duration(seconds: 2));
    _startListening();
  }

  void _startListening() async {
    if (!_speech.isAvailable || _isListening) return;

    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _isListening = true;
      });

      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            setState(() {
              _controllers[_currentFieldIndex].text = result.recognizedWords;
            });
            _moveToNextField();
          }
        },
        listenFor: Duration(seconds: 10), // Increased listening time
        pauseFor: Duration(seconds: 3), // Wait for 3s of silence
        cancelOnError: true,
        partialResults: false,
      );
    } else {
      setState(() {
        _assistantMessage = "Speech recognition is not available.";
      });
    }
  }

  void _moveToNextField() {
    _speech.stop();
    setState(() {
      _currentFieldIndex++;
    });

    if (_currentFieldIndex < _fieldPrompts.length) {
      _askNextField();
    } else {
      setState(() {
        _isListening = false;
        _assistantMessage = "Voice input complete!";
      });
    }
  }

  Widget _buildTextField(String label, TextEditingController controller, {bool isNumeric = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: TextField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(),
        ),
        onChanged: (value) {
          if (controller == _kgsController || controller == _costController) {
            _calculateTotalBill();
          }
          _validateForm();
        },
      ),
    );
  }

  Widget _buildVoiceAssistantDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        _assistantMessage,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Record'),
        actions: [
          IconButton(
            icon: Icon(_isListening ? Icons.mic_off : Icons.mic, color: Colors.blue),
            onPressed: () {
              if (_isListening) {
                _speech.stop();
                setState(() {
                  _isListening = false;
                  _assistantMessage = "Voice input stopped manually.";
                });
              } else {
                _startVoiceAssistant();
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partner: ${widget.partner}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            _buildVoiceAssistantDisplay(),
            _buildTextField('Vendor Name', _vendorController),
            _buildTextField('Crop Name', _itemController),
            _buildTextField('Kgs/Items', _kgsController, isNumeric: true),
            _buildTextField('Cost per Kg/Item', _costController, isNumeric: true),
            Text('Total Bill: ₹${_totalBill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            _buildTextField('Amount Paid', _amountPaidController, isNumeric: true),
            ElevatedButton(onPressed: _isSubmitEnabled ? _submitRecord : null, child: const Text('SUBMIT')),
          ],
        ),
      ),
    );
  }
}
