import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProfitRecord extends StatefulWidget {
  final List<String> partners;

  // Accept the partners list in the constructor
  const ProfitRecord({super.key, required this.partners});

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

  double _totalBill = 0.0;
  bool _isSubmitEnabled = false;

  void _calculateTotalBill() {
    final kgs = double.tryParse(_kgsController.text) ?? 0.0;
    final costPerKg = double.tryParse(_costController.text) ?? 0.0;

    setState(() {
      _totalBill = kgs * costPerKg;
    });

    _validateForm();
  }

  void _validateForm() {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? -1.0;

    setState(() {
      _isSubmitEnabled = _vendorController.text.isNotEmpty &&
          _itemController.text.isNotEmpty &&
          (_kgsController.text.isNotEmpty &&
              double.tryParse(_kgsController.text) != null) &&
          (_costController.text.isNotEmpty &&
              double.tryParse(_costController.text) != null) &&
          (_amountPaidController.text.isNotEmpty &&
              double.tryParse(_amountPaidController.text) != null &&
              amountPaid <= _totalBill);
    });
  }

  Future<void> _submitRecord() async {
    final double amountPaid = double.parse(_amountPaidController.text);
    final double dueAmount = _totalBill - amountPaid;

    User? user = FirebaseAuth.instance.currentUser; // Get the logged-in user

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    try {
      await _firestore.collection('records').add({
        'user_id': user.uid, // Store the user's ID
        'vendor': _vendorController.text,
        'item': _itemController.text,
        'kgs': double.parse(_kgsController.text),
        'cost_per_kg': double.parse(_costController.text),
        'total_bill': _totalBill,
        'amount_paid': amountPaid,
        'partners': widget.partners,
        'due_amount': dueAmount, // Store the due amount in Firestore
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Record added successfully!')),
      );

      _clearForm();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding record: $e')),
      );
    }
  }

  void _clearForm() {
    _vendorController.clear();
    _itemController.clear();
    _kgsController.clear();
    _costController.clear();
    _amountPaidController.clear();
    setState(() {
      _totalBill = 0.0;
      _isSubmitEnabled = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text('Profit Record'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _kgsController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'No. of Kgs/Items',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateTotalBill(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _costController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cost of 1 Kg/Item',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateTotalBill(),
              ),
              SizedBox(height: 16),
              Text(
                'Total Bill: ₹${_totalBill.toStringAsFixed(2)}',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountPaidController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitEnabled ? _submitRecord : null,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
                child: Text('SUBMIT'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _itemController.dispose();
    _kgsController.dispose();
    _costController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }
}
