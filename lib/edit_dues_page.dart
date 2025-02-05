import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditDuesPage extends StatefulWidget {
  const EditDuesPage({super.key});

  @override
  _EditDuesPageState createState() => _EditDuesPageState();
}

class _EditDuesPageState extends State<EditDuesPage> {
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _itemController = TextEditingController();
  DateTime? _selectedDate;
  double _dueAmount = 0.0;
  double _amountPaid = 0.0;
  String? _documentId; // Firestore document ID to update

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Function to get the current user's UID
  String getCurrentUserId() {
    final User? user = _auth.currentUser;
    if (user != null) {
      return user.uid;
    } else {
      throw Exception("User not logged in");
    }
  }

  // Function to pick a date
  Future<void> _pickDueDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        _selectedDate = pickedDate;
      });

      // Fetch dues from Firestore
      _fetchDues();
    }
  }

  // Fetch dues from Firestore based on vendor, item, date, and current user ID
  Future<void> _fetchDues() async {
    final vendor = _vendorController.text.trim().toLowerCase();
    final item = _itemController.text.trim().toLowerCase();

    if (vendor.isEmpty || item.isEmpty || _selectedDate == null) return;

    try {
      final currentUserId = getCurrentUserId(); // Get current user's UID

      QuerySnapshot querySnapshot = await _firestore
          .collection('records')
          .where('vendor', isEqualTo: vendor)
          .where('item', isEqualTo: item)
          .where('user_id', isEqualTo: currentUserId) // Filter by user ID
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isNotEmpty) {
        var doc = querySnapshot.docs.first;
        setState(() {
          _dueAmount = (doc['due_amount'] ?? 0).toDouble();
          _amountPaid = (doc['amount_paid'] ?? 0).toDouble();
          _documentId = doc.id; // Store Firestore document ID for updating
        });
      } else {
        setState(() {
          _dueAmount = 0.0;
          _amountPaid = 0.0;
          _documentId = null;
        });
      }
    } catch (error) {
      // print("Error fetching dues: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error fetching dues"), backgroundColor: Colors.red),
      );
    }
  }

  // Save dues (update Firestore)
  Future<void> _saveDues() async {
    if (_documentId == null || _dueAmount == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('No due amount to update!'),
            backgroundColor: Colors.red),
      );
      return;
    }

    try {
      DocumentReference docRef =
          _firestore.collection('records').doc(_documentId);

      await _firestore.runTransaction((transaction) async {
        DocumentSnapshot snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception("Record does not exist!");
        }

        double currentPaid = snapshot['amount_paid'];

        transaction.update(docRef, {
          'due_amount': 0.0,
          'amount_paid': currentPaid + _dueAmount, // Add due to paid amount
        });
      });

      setState(() {
        _dueAmount = 0.0; // Update UI
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Dues updated successfully!'),
            backgroundColor: Colors.green),
      );
    } catch (error) {
      print("Error updating dues: $error");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Failed to update dues!'),
            backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Dues'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor Name
            TextFormField(
              controller: _vendorController,
              decoration: InputDecoration(
                labelText: 'Vendor Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _fetchDues(),
            ),
            SizedBox(height: 20),

            // Item Name
            TextFormField(
              controller: _itemController,
              decoration: InputDecoration(
                labelText: 'Item Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _fetchDues(),
            ),
            SizedBox(height: 20),

            // Due Date (with Date Picker)
            InkWell(
              onTap: () => _pickDueDate(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Select Due Date',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _selectedDate != null
                      ? "${_selectedDate!.year}-${_selectedDate!.month}-${_selectedDate!.day}"
                      : "Tap to select date",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
            ),
            SizedBox(height: 20),

            // Due Amount (Non-editable)
            TextFormField(
              controller:
                  TextEditingController(text: _dueAmount.toStringAsFixed(2)),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Due Amount',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Amount Paid (Non-editable)
            TextFormField(
              controller:
                  TextEditingController(text: _amountPaid.toStringAsFixed(2)),
              readOnly: true,
              decoration: InputDecoration(
                labelText: 'Amount Paid',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _saveDues,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Save Dues'),
            ),
          ],
        ),
      ),
    );
  }
}
