import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditDuesPage extends StatefulWidget {
  @override
  _EditDuesPageState createState() => _EditDuesPageState();
}

class _EditDuesPageState extends State<EditDuesPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  User? user;
  String? selectedRecordId;
  double? oldDue;
  double? oldAmountPaid;
  final TextEditingController _dueController = TextEditingController();

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
  }

  Future<void> updateDueAmount() async {
    if (selectedRecordId == null || oldDue == null || oldAmountPaid == null) return;

    double? enteredAmount = double.tryParse(_dueController.text.trim());
    if (enteredAmount == null || enteredAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Enter a valid amount!")),
      );
      return;
    }

    double newDue = oldDue! - enteredAmount;
    double newAmountPaid = oldAmountPaid! + enteredAmount;

    if (newDue < 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Amount cannot exceed the due balance!")),
      );
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('records').doc(selectedRecordId).update({
        'due_amount': newDue,
        'amount_paid': newAmountPaid,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Due updated successfully!")),
      );

      // Close the dialog
      Navigator.of(context).pop();

      // Update UI
      setState(() {
        if (newDue == 0) {
          selectedRecordId = null;
          oldDue = null;
          oldAmountPaid = null;
        }
        _dueController.clear();
      });

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error updating due: $e")),
      );
    }
  }

  void showDueDialog(String recordId, double due, double amountPaid) {
    setState(() {
      selectedRecordId = recordId;
      oldDue = due;
      oldAmountPaid = amountPaid;
    });

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Due Amount", textAlign: TextAlign.center),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Current Due: ₹${oldDue!.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text("Amount Paid: ₹${oldAmountPaid!.toStringAsFixed(2)}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              SizedBox(height: 10),
              TextField(
                controller: _dueController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18),
                decoration: InputDecoration(
                  hintText: "Enter amount",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 16)),
            ),
            ElevatedButton(
              onPressed: updateDueAmount,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              child: Text("Confirm", style: TextStyle(fontSize: 16)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Edit Dues")),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('records')
                  .where('user_id', isEqualTo: user?.uid)
                  .where('due_amount', isGreaterThan: 0)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }
                var records = snapshot.data!.docs;
                if (records.isEmpty) {
                  return Center(child: Text("No dues to edit!"));
                }

                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    var record = records[index];

                    return Card(
                      color: Colors.grey[200],
                      margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: Icon(Icons.shopping_cart, color: Colors.blue),
                        title: Text(
                          "Crop: ${record['item']}",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Vendor: ${record['vendor']}"),
                            Text("Kgs: ${record['kgs']}"),
                            Text("Cost per Kg: ₹${record['cost_per_kg']}"),
                            Text(
                              "Due: ₹${record['due_amount']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                            Text(
                              "Amount Paid: ₹${record['amount_paid']}",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        trailing: Icon(Icons.edit, color: Colors.green),
                        onTap: () {
                          showDueDialog(record.id, record['due_amount'].toDouble(), record['amount_paid'].toDouble());
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
