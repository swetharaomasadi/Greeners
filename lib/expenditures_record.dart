import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';


class ExpendituresRecord extends StatefulWidget {
  final String partner;

  const ExpendituresRecord({super.key, required this.partner});

  @override
  _ExpendituresRecordState createState() => _ExpendituresRecordState();
}

class _ExpendituresRecordState extends State<ExpendituresRecord> {
  final FlutterTts flutterTts = FlutterTts();

  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cropController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _assistantMessage = "Tap the mic to start voice input.";
  int? _activeFieldIndex;
  final List<TextEditingController> _controllers = [];
  bool _isSubmitEnabled = false;
  bool _isDataSubmitted = false;
  Timer? _timeoutTimer;
  String? _amountError;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controllers.addAll([
      _descriptionController,
      _amountController,
      _cropController,
    ]);
    _descriptionController.addListener(_validateForm);
    _amountController.addListener(_validateForm);
    _cropController.addListener(_validateForm);
  }

  @override
  void dispose() {
    super.dispose();
    _speech.stop();
    _timeoutTimer?.cancel();
    for (var controller in _controllers) {
      controller.dispose();
    }
    _stopListening();
  }

 void _validateForm() {
  setState(() {
    _isSubmitEnabled = !_isLoading && _controllers.every((controller) => controller.text.isNotEmpty);
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
          _stopListening();
        });
      }
    },
  );

  if (!available) return;

  if (mounted) {
    setState(() {
      _isListening = true;
      _activeFieldIndex = fieldIndex;
      _assistantMessage = "Voice input active. Please speak.";
    });
  }

  _speech.listen(
    onResult: (result) {
      if (result.recognizedWords.isNotEmpty && mounted) {
        setState(() {
          if (fieldIndex == 2) {
            _getController(fieldIndex).text = _extractNumber(result.recognizedWords).toString();
          } else {
            _getController(fieldIndex).text = result.recognizedWords.toLowerCase();
          }
          _validateForm();
        });
      }
    },
    listenMode: stt.ListenMode.dictation,
    partialResults: true,
    pauseFor: Duration(seconds: 2),
    onSoundLevelChange: (level) {
      if (level < 0.1) {
        _startTimeout();
      } else {
        _cancelTimeout();
      }
    },
  );
}

void _startTimeout() {
  _timeoutTimer?.cancel();
  _timeoutTimer = Timer(Duration(seconds: 2), () {
    if (_isListening) _stopListening();
  });
}

void _cancelTimeout() {
  _timeoutTimer?.cancel();
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

double _extractNumber(String input) {
  final number = RegExp(r'[\d]+(\.[\d]+)?').stringMatch(input);
  return double.tryParse(number ?? '0') ?? 0.0;
}

Future<void> _submitExpenditure() async {
  setState(() {
    _isLoading = true; // Set loading to true
    _validateForm();
  });
  User? user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  String description = _descriptionController.text.trim().toLowerCase();
  String cropName = _cropController.text.trim().toLowerCase();
  double amountSpent = double.tryParse(_amountController.text.trim()) ?? 0.0;

  setState(() {
    _amountError = amountSpent > 0 ? null : "Enter a valid numeric amount";
  });

  if (description.isNotEmpty && cropName.isNotEmpty && _amountError == null) {
    String currentDate = DateTime.now().toIso8601String().split('T').first;

    Map<String, dynamic> recordData = {
      'date': currentDate,
      'typ': 'exp',
      'partner': widget.partner,
      'c_id': cropName,
      'desc': description,
      'amt': amountSpent,
    };

    WriteBatch batch = _firestore.batch();

    try {
      // ✅ Run updates for records and profits in parallel
      await Future.wait([
        _updateRecords(user.uid, batch, recordData), 
        _updateProfits(user.uid, batch, cropName, amountSpent)
      ]);

      // ✅ Commit the batch after parallel updates
      await batch.commit();

      _clearForm();
      setState(() {
        _isDataSubmitted = true;
        _isLoading = false; // Set loading to false after success
        _validateForm();
      });

      await flutterTts.speak("Successful completion.");  // ✅ Speak success

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isDataSubmitted = false;
        });
      });

    } catch (e, stackTrace) {
      await flutterTts.speak("Failed, failed");  // ✅ Speak failure
      _showErrorDialog('Error submitting record: $e\nStack trace: $stackTrace');
      print('Error submitting record: $e');
      print('Stack trace: $stackTrace');
      setState(() {
        _isLoading = false; // Set loading to false after failure
        _validateForm();
      });
    }
  }
}

Future<void> _updateRecords(String userId, WriteBatch batch, Map<String, dynamic> recordData) async {
  DocumentReference recordDocRef = await _getOrCreateDoc('records', userId, 'r');
  DocumentSnapshot recordSnapshot = await recordDocRef.get();
  Map<String, dynamic>? recordDataMap = recordSnapshot.data() as Map<String, dynamic>?; 
  List<dynamic> records = List.from(recordDataMap?['r'] ?? []);
        
  records.add(recordData);
  batch.set(recordDocRef, {'r': records}, SetOptions(merge: true));
}

  Future<void> _updateProfits(String userId, WriteBatch batch, String cropName, double amountSpent) async {
  QuerySnapshot existingDocs = await _firestore.collection('partners')
      .where('u_id', isEqualTo: userId)
      .orderBy('created_at', descending: false)
      .get();

  bool profitUpdated = false;

  for (var doc in existingDocs.docs) {
    DocumentReference profitDocRef = doc.reference;
    DocumentSnapshot profitSnapshot = await profitDocRef.get();
    Map<String, dynamic>? data = profitSnapshot.data() as Map<String, dynamic>? ?? {};
    Map<String, dynamic> profits = data['profits'] ?? {};

    // Check if partner exists in profits
    Map<String, dynamic> partnerProfits = (profits[widget.partner] as Map<String, dynamic>?) ?? {'crops': {}};
    Map<String, dynamic> cropProfits = (partnerProfits['crops'][cropName] as Map<String, dynamic>?) ?? {};

    cropProfits['texp'] = FieldValue.increment(amountSpent);
    cropProfits['tp'] = FieldValue.increment(-amountSpent);
    cropProfits['tear'] = cropProfits['tear'] ?? 0; // Ensure tear is 0 if not present
    cropProfits['tw'] = cropProfits['tw'] ?? 0; // Ensure tw is 0 if not present
    partnerProfits['tear'] = partnerProfits['tear'] ?? 0;
    partnerProfits['texp'] = FieldValue.increment(amountSpent);
    partnerProfits['tp'] = FieldValue.increment(-amountSpent);
    partnerProfits['crops'][cropName] = cropProfits;
    profits[widget.partner] = partnerProfits;

    batch.set(profitDocRef, {'profits': profits}, SetOptions(merge: true));
    profitUpdated = true;
    break;
  }

  if (!profitUpdated) {
    // Create a new document if needed
    DocumentReference newProfitDocRef = await _getOrCreateDoc('partners', userId, 'profits');
    batch.set(newProfitDocRef, {
      'profits': {
        widget.partner: {
          'crops': {
            cropName: {
              'texp': FieldValue.increment(amountSpent),
              'tp': FieldValue.increment(-amountSpent),
              'tear': 0,
              'tw': 0,
            }
          },
          'texp': FieldValue.increment(amountSpent),
          'tp': FieldValue.increment(-amountSpent),
          'tear': 0,
        }
      }
    }, SetOptions(merge: true));
  }
}

  Future<DocumentReference> _getOrCreateDoc(String collection, String userId, String field) async {
  try {
    QuerySnapshot userDocs = await FirebaseFirestore.instance
        .collection(collection)
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: userId)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${userId}\uf8ff")
        .orderBy(FieldPath.documentId, descending: false)
        .get();

    for (var doc in userDocs.docs) {
      DocumentSnapshot existingDocSnapshot = await doc.reference.get();
      if (existingDocSnapshot.exists) {
        int docSize = existingDocSnapshot.data()?.toString().length ?? 0;
        if (docSize < 0.8 * 1024) {
          return doc.reference;
        }
      }
    }

    // Create a new document if no suitable document found
    String newDocId = userDocs.docs.isEmpty ? userId : '${userId}_${userDocs.docs.length + 1}';
    DocumentReference newDocRef = _firestore.collection(collection).doc(newDocId);
    await newDocRef.set({
      'created_at': FieldValue.serverTimestamp(),
      'u_id': userId,
      field: []
    }, SetOptions(merge: true));
    return newDocRef;
  } catch (e) {
    print('Error getting or creating document: $e');
    rethrow;
  }
}
  
  void _clearForm() {
    for (var controller in _controllers) {
      controller.clear();
    }
    setState(() {
      _isSubmitEnabled = false;
    });
  }

  void _showErrorDialog(String message) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Error"),
        content: Text(message),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text("Retry"),
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _isSubmitEnabled = false; // Disable the submit button
              });
              _submitExpenditure();
            },
          ),
        ],
      );
    },
  );
}


  void _showConfirmationDialog() {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text("Confirm Submission"),
        content: SingleChildScrollView( // Enables scrolling if content is too long
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Crop Name:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _cropController.text,
                softWrap: true,
              ),
              SizedBox(height: 8), // Adds spacing

              Text(
                'Description:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _descriptionController.text,
                softWrap: true,
              ),
              SizedBox(height: 8),

              Text(
                'Amount:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                _amountController.text,
                softWrap: true,
              ),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Cancel"),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          ElevatedButton(
            child: Text("Confirm"),
            onPressed: () {
              Navigator.of(context).pop();
              _submitExpenditure();
            },
          ),
        ],
      );
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
        _assistantMessage = "Tap the mic to start voice input.";
      });
    }
  }
}

Widget _buildTextField(String label, TextEditingController controller, int index, {bool isNumeric = false}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 12.0),
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
                    ? [FilteringTextInputFormatter.digitsOnly]
                    : [],
                decoration: InputDecoration(
                  border: OutlineInputBorder(),
                  errorText: isNumeric && _amountError != null ? _amountError : null,
                ),
                onChanged: (value) {
                  _validateForm();
                },
                enabled: !_isLoading, // Disable the text field when loading
              ),
            ),
            IconButton(
              icon: Icon(Icons.mic, color: (_isListening && _activeFieldIndex == index) ? Colors.red : Colors.blue),
              onPressed: _isLoading
                ? null // Disable the microphone button when loading
                : () {
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

  Widget _buildVoiceAssistantDisplay() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Text(
        _assistantMessage,
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blue),
      ),
    );
  }

  Widget _buildConfirmationMessage() {
    return _isDataSubmitted
        ? Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.0),
            child: Text(
              'Data submitted successfully!',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
            ),
          )
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, TextEditingController> textFields = {
      "Crop Name": _cropController,
      "Description": _descriptionController,
      "Amount": _amountController,
    };

    return Scaffold(
    appBar: AppBar(title: Text("Enter Expenditures"),
    backgroundColor: const Color.fromARGB(255, 203, 161, 232),),
    body: Stack(
      children: [
        Padding(
          padding: EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Partner: ${widget.partner}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
                _buildVoiceAssistantDisplay(),
                _buildConfirmationMessage(),
                ...textFields.entries.map((entry) {
                  int index = textFields.keys.toList().indexOf(entry.key);
                  return _buildTextField(entry.key, entry.value, index, isNumeric: entry.key == "Amount");
                }).toList(),
                SizedBox(height: 20),
                ElevatedButton(
                  onPressed: (_isSubmitEnabled && !_isLoading) ? _showConfirmationDialog : null,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(
                      (_isSubmitEnabled && !_isLoading) ? Colors.blue : Colors.grey,
                    ),
                  ),
                  child: Text("Submit"),
                ),
              ],
            ),
          ),
        ),
        if (_isLoading)
          Center(
            child: CircularProgressIndicator(),
          ),
      ],
    ),
  );
}
}
