import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:flutter/services.dart';

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
  String _assistantMessage = "Tap the mic to start voice input.";
  final List<TextEditingController> _controllers = [];
  double _totalBill = 0.0;
  bool _isSubmitEnabled = false;
  Map<int, bool> _listeningStates = {};

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

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
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
    double amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    setState(() {
      _isSubmitEnabled = _controllers.every((controller) => controller.text.isNotEmpty) &&
          amountPaid <= _totalBill; // Submit enabled only if Amount Paid ≤ Total Bill
    });
  }

  Future<void> _submitRecord() async {
  if (!_isSubmitEnabled) return;

  bool confirm = await _showConfirmationDialog();
  if (!confirm) return; // Stop if user cancels

  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  await _firestore.collection('records').add({
    'user_id': user.uid,
    'partner': widget.partner.toLowerCase(),
    'vendor': _vendorController.text.toLowerCase(),
    'item': _itemController.text.toLowerCase(),
    'kgs': double.tryParse(_kgsController.text) ?? 0.0,
    'cost_per_kg': double.tryParse(_costController.text) ?? 0.0,
    'total_bill': _totalBill,
    'amount_paid': double.tryParse(_amountPaidController.text) ?? 0.0,
    'due_amount': _totalBill - (double.tryParse(_amountPaidController.text) ?? 0.0),
    'timestamp': FieldValue.serverTimestamp(),
  });

  _clearForm();
}

/// Shows a confirmation dialog before submitting
Future<bool> _showConfirmationDialog() async {
  return await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: const Text("Confirm Submission"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Vendor: ${_vendorController.text}"),
            Text("Crop: ${_itemController.text}"),
            Text("Kgs/Items: ${_kgsController.text}"),
            Text("Cost per Kg/Item: ₹${_costController.text}"),
            Text("Total Bill: ₹${_totalBill.toStringAsFixed(2)}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            Text("Amount Paid: ₹${_amountPaidController.text}", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
            Text("Due Amount: ₹${(_totalBill - (double.tryParse(_amountPaidController.text) ?? 0.0)).toStringAsFixed(2)}",
                style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true), // Confirm
            child: const Text("Submit"),
          ),
        ],
      );
    },
  ) ?? false; // Default to false if dialog is dismissed
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

  void _toggleListening(int fieldIndex) async {
    if (_listeningStates[fieldIndex] == true) {
      _speech.stop();
      setState(() {
        _listeningStates[fieldIndex] = false;
      });
      return;
    }

    bool available = await _speech.initialize();
    if (available) {
      setState(() {
        _listeningStates[fieldIndex] = true;
      });

      _speech.listen(
        onResult: (result) {
          if (result.finalResult) {
            String recognizedText = result.recognizedWords.toLowerCase();

            // Handle numeric fields
            if (fieldIndex == 2 || fieldIndex == 3) {
              recognizedText = _extractNumbers(recognizedText);
            } else if (fieldIndex == 4) {
              // **For Amount Paid, take full spoken number without truncation**
              recognizedText = _extractFullNumber(recognizedText);
            }

            setState(() {
              _controllers[fieldIndex].text = recognizedText;
              _listeningStates[fieldIndex] = false;
            });

            _speech.stop(); // Stop listening after processing
            _validateForm();
            if (fieldIndex == 2 || fieldIndex == 3) {
              _calculateTotalBill();
            }
          }
        },
      );

      // **Auto-stop after detecting no speech (silence timeout)**
      Future.delayed(const Duration(seconds: 2), () {
        if (_speech.isListening) {
          _speech.stop();
          setState(() {
            _listeningStates[fieldIndex] = false;
          });
        }
      });
    }
  }

  String _extractNumbers(String input) {
    RegExp regex = RegExp(r'(\d+(\.\d+)?)'); // Matches integers & decimals
    Match? match = regex.firstMatch(input);
    return match != null ? match.group(0) ?? "" : "";
  }

  String _extractFullNumber(String input) {
    RegExp regex = RegExp(r'\d+(\.\d+)?'); // Matches full numbers with decimals
    Iterable<Match> matches = regex.allMatches(input);
    return matches.isNotEmpty ? matches.map((m) => m.group(0) ?? "").join('') : "";
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
                  decoration: InputDecoration(border: OutlineInputBorder()),
                  onChanged: (value) {
                    if (controller == _kgsController || controller == _costController) {
                      _calculateTotalBill();
                    }
                    _validateForm();
                  },
                ),
              ),
              IconButton(
                icon: Icon(Icons.mic, color: _listeningStates[index] == true ? Colors.red : Colors.blue),
                onPressed: () => _toggleListening(index),
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
      appBar: AppBar(title: const Text('Profit Record')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Partner: ${widget.partner}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
            Text(_assistantMessage, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue)),
            _buildTextField('Vendor Name', _vendorController, 0),
            _buildTextField('Crop Name', _itemController, 1),
            _buildTextField('Kgs/Items', _kgsController, 2, isNumeric: true),
            _buildTextField('Cost per Kg/Item', _costController, 3, isNumeric: true),
            Text('Total Bill: ₹${_totalBill.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green)),
            _buildTextField('Amount Paid', _amountPaidController, 4, isNumeric: true),
            ElevatedButton(
              onPressed: _isSubmitEnabled ? _submitRecord : null,
              style: ElevatedButton.styleFrom(backgroundColor: _isSubmitEnabled ? Colors.blue : Colors.grey),
              child: const Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }
}
