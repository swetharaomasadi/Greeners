import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpendituresRecord extends StatefulWidget {
  final List<String> partners;

  // Accept the partners list in the constructor
  const ExpendituresRecord({super.key, required this.partners});

  @override
  _ExpendituresRecordState createState() => _ExpendituresRecordState();
}

class _ExpendituresRecordState extends State<ExpendituresRecord> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  User? user = FirebaseAuth.instance.currentUser; // Moved user here

  void _submitExpenditure() async {
    String description = _descriptionController.text.trim();
    String amount = _amountController.text.trim();

    if (description.isNotEmpty && amount.isNotEmpty && user != null) {
      // Ensure user is not null
      try {
        await FirebaseFirestore.instance.collection('expenditures').add({
          'user_id': user!.uid, // Now user is defined correctly
          'description': description,
          'amount': double.tryParse(amount) ?? 0.0,
          'partners': widget.partners,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _descriptionController.clear();
        _amountController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expenditure added successfully!')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to add expenditure: $e')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please log in before submitting.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text("Expenditure Record"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _descriptionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Amount Spend',
                border: OutlineInputBorder(),
              ),
            ),
            Spacer(),
            ElevatedButton(
              onPressed: _submitExpenditure,
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
              ),
              child: Text('SUBMIT'),
            ),
          ],
        ),
      ),
    );
  }
}
