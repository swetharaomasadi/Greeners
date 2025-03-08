import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:flutter/services.dart';

class ProfitRecord extends StatefulWidget {
  final String partner;
  const ProfitRecord({super.key, required this.partner});

  @override
  ProfitRecordScreenState createState() => ProfitRecordScreenState();
}

class ProfitRecordScreenState extends State<ProfitRecord> {
  final _vendorController = TextEditingController();
  final _itemController = TextEditingController();
  final _kgsController = TextEditingController();
  final _costController = TextEditingController();
  final _amountPaidController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _assistantMessage = "Tap the mic to start voice input.";
  int? _activeFieldIndex;
  final List<TextEditingController> _controllers = [];
  double _totalBill = 0.0;
  bool _isSubmitEnabled = false;
  bool _isDataSubmitted = false;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    _controllers.addAll([
      _vendorController,
      _itemController,
      _kgsController,
      _costController,
      _amountPaidController
    ]);

    _kgsController.addListener(_calculateTotalBill);
    _costController.addListener(_calculateTotalBill);
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
      _isSubmitEnabled = _controllers.every((controller) => controller.text.isNotEmpty) &&
          (double.tryParse(_amountPaidController.text) ?? 0.0) <= _totalBill;
    });
  }

  Future<void> _submitRecord() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    double amountPaid = double.tryParse(_amountPaidController.text) ?? 0.0;
    double weight = double.tryParse(_kgsController.text) ?? 0.0;
    
    amountPaid = double.parse(amountPaid.toStringAsFixed(2));
    weight = double.parse(weight.toStringAsFixed(2));
    double totalDue = _totalBill - amountPaid;

    String currentDate = DateTime.now().toIso8601String().split('T').first;

    Map<String, dynamic> recordData = {
      't': 'sale',
      'v_id': _vendorController.text,
      'c_id': _itemController.text,
      'w': weight,
      'tb': _totalBill,
      'partner': widget.partner,
      'date': currentDate,
    };

    WriteBatch batch = _firestore.batch();
    try {
      // Update records
      DocumentReference recordDocRef = await _getOrCreateDoc('records', user.uid, 'r');
      DocumentSnapshot recordSnapshot = await recordDocRef.get();
      Map<String, dynamic>? recordDataMap = recordSnapshot.data() as Map<String, dynamic>?; 
      List<dynamic> records = List.from(recordDataMap?['r'] ?? []);
      bool recordUpdated = false;
      for (var record in records) {
        if (record is Map<String, dynamic> &&
            record['v_id'] == _vendorController.text &&
            record['c_id'] == _itemController.text &&
            record['date'] == currentDate) {
          record['w'] += weight;
          record['tb'] += _totalBill;
          recordUpdated = true;
          break;
        }
      }

      if (!recordUpdated) {
        records.add(recordData);
      }

      batch.set(recordDocRef, {'r': records}, SetOptions(merge: true));

      // Update profit data and today_sales
      await _updateProfits(user.uid, batch);

      // Update dues if totalDue is greater than 0
      if (totalDue > 0) {
        await _updateDues(user.uid, batch, amountPaid, weight, totalDue, currentDate);
      }

      await batch.commit();

      _clearForm();
      setState(() {
        _isDataSubmitted = true;
      });

      Future.delayed(const Duration(seconds: 3), () {
        setState(() {
          _isDataSubmitted = false;
        });
      });
    } catch (e, stackTrace) {
      _showErrorDialog('Error submitting record: $e\nStack trace: $stackTrace');
      print('Error submitting record: $e');
      print('Stack trace: $stackTrace');
    }
  }

  Future<void> _updateProfits(String userId, WriteBatch batch) async {
    DocumentReference? profitDocRef = await _getFirstDoc('partners', userId);
    bool profitUpdated = false;
    DateTime today = DateTime.now();
    String todayStr = "${today.year}-${today.month}-${today.day}";

    while (profitDocRef != null) {
      DocumentSnapshot profitSnapshot = await profitDocRef.get();
      Map<String, dynamic>? data = profitSnapshot.data() as Map<String, dynamic>? ?? {};
      Map<String, dynamic> profits = data['profits'] ?? {};
      Map<String, dynamic> todaySales = data['today_sales'] ?? {};

      // Check if partner exists in profits
      Map<String, dynamic> partnerProfits = (profits[widget.partner] as Map<String, dynamic>?) ?? {'crops': {}};
      Map<String, dynamic> cropProfits = (partnerProfits['crops'][_itemController.text] as Map<String, dynamic>?) ?? {};

      cropProfits['tear'] = (cropProfits['tear'] ?? 0) + _totalBill;
      cropProfits['texp'] = (cropProfits['texp'] ?? 0) + 0;
      cropProfits['tp'] = (cropProfits['tp'] ?? 0) + _totalBill;
      cropProfits['tw'] = (cropProfits['tw'] ?? 0) + (double.tryParse(_kgsController.text) ?? 0.0);

      partnerProfits['crops'][_itemController.text] = cropProfits;
      partnerProfits['tear'] = (partnerProfits['tear'] ?? 0) + _totalBill;
      partnerProfits['texp'] = (partnerProfits['texp'] ?? 0) + 0;
      partnerProfits['tp'] = (partnerProfits['tp'] ?? 0) + _totalBill;
      profits[widget.partner] = partnerProfits;

      // Update today_sales with date check
      if (todaySales['date'] != todayStr) {
        todaySales = {'date': todayStr}; // Reset todaySales for new date
      }

      Map<String, dynamic> salesData = todaySales[_itemController.text] ?? {};
      salesData['weight'] = (salesData['weight'] ?? 0.0) + (double.tryParse(_kgsController.text) ?? 0.0);
      salesData['total_bill'] = (salesData['total_bill'] ?? 0.0) + _totalBill;
      todaySales[_itemController.text] = salesData;

      batch.set(profitDocRef, {
        'profits': profits,
        'today_sales': todaySales
      }, SetOptions(merge: true));
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
              _itemController.text: {
                'tear': _totalBill,
                'texp': 0,
                'tp': _totalBill,
                'tw': double.tryParse(_kgsController.text) ?? 0.0
              }
            },
            'tear': _totalBill,
            'texp': 0,
            'tp': _totalBill
          }
        },
        'today_sales': {
          'date': todayStr,
          _itemController.text: {
            'weight': double.tryParse(_kgsController.text) ?? 0.0,
            'total_bill': _totalBill
          }
        }
      }, SetOptions(merge: true));
    }
  }

  Future<void> _updateDues(String userId, WriteBatch batch, double amountPaid, double weight, double totalDue, String currentDate) async {
    bool dueUpdated = false;
    DocumentReference? dueDocRef = await _getFirstDoc('dues', userId);
    while (dueDocRef != null) {
      DocumentSnapshot dueSnapshot = await dueDocRef.get();
      Map<String, dynamic>? dueDataMap = dueSnapshot.data() as Map<String, dynamic>?;
      List<dynamic> dues = List.from(dueDataMap?['d'] ?? []);
      for (var due in dues) {
        if (due is Map<String, dynamic> &&
            due['vendor_id'] == _vendorController.text &&
            due['crop_id'] == _itemController.text) {
          due['total_bill'] += _totalBill;
          due['amount_paid'] += amountPaid;
          due['total_due'] += totalDue;
          due['weight'] += weight;
          dueUpdated = true;
          break;
        }
      }

      if (dueUpdated) {
        batch.set(dueDocRef, {'d': dues}, SetOptions(merge: true));
        break;
      }

      dueDocRef = await _getNextDoc(dueDocRef);
    }

    if (!dueUpdated) {
      DocumentReference newDueDocRef = await _getOrCreateDoc('dues', userId, 'd');
      DocumentSnapshot dueSnapshot = await newDueDocRef.get();
      Map<String, dynamic>? dueDataMap = dueSnapshot.data() as Map<String, dynamic>?;
      List<dynamic> updatedDues = List.from(dueDataMap?['d'] ?? []);

      updatedDues.add({
        'vendor_id': _vendorController.text,
        'crop_id': _itemController.text,
        'date': currentDate,
        'total_bill': _totalBill,
        'amount_paid': amountPaid,
        'total_due': totalDue,
        'weight': weight,
      });

      batch.set(newDueDocRef, {'d': updatedDues}, SetOptions(merge: true));
    }
  }

  Future<DocumentReference> _getOrCreateDoc(String collection, String userId, String field) async {
    try {
      QuerySnapshot existingDocs = await _firestore.collection(collection)
          .where('u_id', isEqualTo: userId)
          .orderBy('created_at', descending: true)
          .limit(1)
          .get();

      if (existingDocs.docs.isNotEmpty) {
        DocumentReference existingDocRef = existingDocs.docs.first.reference;
        DocumentSnapshot existingDocSnapshot = await existingDocRef.get();

        if (existingDocSnapshot.exists) {
          int docSize = existingDocSnapshot.data()?.toString().length ?? 0;
          if (docSize < 0.8 * 1024) {
            return existingDocRef;
          } else {
            String newDocId = '${userId}_${existingDocs.docs.length + 1}';
            await existingDocRef.update({'next_doc_id': newDocId});
            DocumentReference newDocRef = _firestore.collection(collection).doc(newDocId);
            await newDocRef.set({
              'created_at': FieldValue.serverTimestamp(),
              'u_id': userId,
              field: []
            }, SetOptions(merge: true));
            return newDocRef;
          }
        }
      }

      String newDocId = existingDocs.docs.isEmpty ? userId : '${userId}_${existingDocs.docs.length + 1}';
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

  Future<DocumentReference?> _getFirstDoc(String collection, String userId) async {
    QuerySnapshot existingDocs = await _firestore.collection(collection)
        .where('u_id', isEqualTo: userId)
        .orderBy('created_at', descending: true)
        .limit(1)
        .get();

    if (existingDocs.docs.isNotEmpty) {
      return existingDocs.docs.first.reference;
    }
    return null;
  }

  Future<DocumentReference?> _getNextDoc(DocumentReference currentDocRef) async {
    DocumentSnapshot currentDoc = await currentDocRef.get();
    String? nextDocId = (currentDoc.data() as Map<String, dynamic>?)?['next_doc_id'];
    if (nextDocId != null) {
      return _firestore.collection(currentDocRef.parent.id).doc(nextDocId);
    }
    return null;
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
        _assistantMessage = "Voice input active. Please speak.";
      });
    }

    _speech.listen(
      onResult: (result) {
        if (result.recognizedWords.isNotEmpty && mounted) {
          setState(() {
            if (fieldIndex == 2 || fieldIndex == 3 || fieldIndex == 4) {
              _getController(fieldIndex).text = _extractNumber(result.recognizedWords).toString();
            } else {
              _getController(fieldIndex).text = result.recognizedWords.toLowerCase();
            }
            if (fieldIndex == 2 || fieldIndex == 3) {
              _calculateTotalBill();
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

  TextEditingController _getController(int fieldIndex) {
    switch (fieldIndex) {
      case 0:
        return _vendorController;
      case 1:
        return _itemController;
      case 2:
        return _kgsController;
      case 3:
        return _costController;
      case 4:
        return _amountPaidController;
      default:
        throw Exception("Invalid field index");
    }
  }

  double _extractNumber(String input) {
    final number = RegExp(r'[\d]+(\.[\d]+)?').stringMatch(input);
    return double.tryParse(number ?? '0') ?? 0.0;
  }

  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Submission"),
          content: Text(
            'Vendor Name: ${_vendorController.text}\n'
            'Crop Name: ${_itemController.text}\n'
            'Kgs/Items: ${_kgsController.text}\n'
            'Cost per Kg/Item: ${_costController.text}\n'
            'Amount Paid: ${_amountPaidController.text}\n'
            'Total Bill: $_totalBill',
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
                _submitRecord();
              },
            ),
          ],
        );
      },
    );
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
                _submitRecord();
              },
            ),
          ],
        );
      },
    );
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
                      ? [FilteringTextInputFormatter.allow(RegExp(r'^[0-9]*\.?[0-9]*'))]
                      : [],
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    if (controller == _kgsController || controller == _costController) {
                      _calculateTotalBill();
                    }
                    _validateForm();
                  },
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Record'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Partner: ${widget.partner}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue)),
              _buildVoiceAssistantDisplay(),
              _buildConfirmationMessage(),
              _buildTextField('Vendor Name', _vendorController, 0),
              _buildTextField('Crop Name', _itemController, 1),
              _buildTextField('Kgs/Items', _kgsController, 2, isNumeric: true),
              _buildTextField('Cost per Kg/Item', _costController, 3, isNumeric: true),
              Text('Total Bill: ₹${_totalBill.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              _buildTextField('Amount Paid', _amountPaidController, 4, isNumeric: true),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _isSubmitEnabled ? _showConfirmationDialog : null,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(
                    _isSubmitEnabled ? Colors.blue : Colors.grey,
                  ),
                ),
                child: Text('Submit'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}