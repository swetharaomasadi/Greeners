import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpendituresRecord extends StatefulWidget {
  final String partner; // Accept a single partner name

  const ExpendituresRecord({super.key, required this.partner});

  @override
  _ExpendituresRecordState createState() => _ExpendituresRecordState();
}

class _ExpendituresRecordState extends State<ExpendituresRecord> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _cropController = TextEditingController(); // New Crop Name Field
  User? user = FirebaseAuth.instance.currentUser;

  String? amountError;

  bool isValidNumber(String value) {
    return RegExp(r'^[0-9]+(\.[0-9]*)?$').hasMatch(value); // Allows integers & decimals
  }

  void _submitExpenditure() async {
    String description = _descriptionController.text.trim();
    String amountText = _amountController.text.trim();
    String cropName = _cropController.text.trim();

    setState(() {
      amountError = isValidNumber(amountText) ? null : "Enter a valid numeric amount";
    });

    if (description.isNotEmpty && cropName.isNotEmpty && amountError == null && user != null) {
      try {
        await FirebaseFirestore.instance.collection('expenditures').add({
          'user_id': user!.uid,
          'description': description,
          'amount': double.tryParse(amountText) ?? 0.0,
          'partner': widget.partner, // Assigning partner name
          'crop_name': cropName, // Storing Crop Name
          'timestamp': FieldValue.serverTimestamp(),
        });

        _descriptionController.clear();
        _amountController.clear();
        _cropController.clear();
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
        SnackBar(content: Text('Please enter valid details before submitting.')),
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
            Text(
              "Partner Name: ${widget.partner}", // Display partner name
              style: TextStyle(
                color: Colors.blueAccent,
                fontSize: 18,
                fontWeight: FontWeight.bold, // Bold text
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _cropController,
              decoration: InputDecoration(
                labelText: 'Crop Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
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
                labelText: 'Amount Spent',
                border: OutlineInputBorder(),
                errorText: amountError, // Show error message if invalid input
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
