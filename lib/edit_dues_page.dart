import 'package:flutter/material.dart';

class EditDuesPage extends StatefulWidget {
  @override
  _EditDuesPageState createState() => _EditDuesPageState();
}

class _EditDuesPageState extends State<EditDuesPage> {
  // Define controllers for the text fields
  final TextEditingController _vendorController = TextEditingController();
  final TextEditingController _dueAmountController = TextEditingController();
  final TextEditingController _dueDateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  // Function to save the data (You can integrate it with your database or logic)
  void _saveDues() {
    final vendor = _vendorController.text;
    final dueAmount = _dueAmountController.text;
    final dueDate = _dueDateController.text;
    final notes = _notesController.text;

    if (vendor.isEmpty || dueAmount.isEmpty || dueDate.isEmpty) {
      // You can show an error dialog or message if required fields are empty
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Please fill in all required fields!'),
        backgroundColor: Colors.red,
      ));
    } else {
      // You can save the data to your database or do other operations
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Dues saved successfully!'),
        backgroundColor: Colors.green,
      ));
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
            ),
            SizedBox(height: 20),

            // Due Amount
            TextFormField(
              controller: _dueAmountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Due Amount',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Due Date
            TextFormField(
              controller: _dueDateController,
              keyboardType: TextInputType.datetime,
              decoration: InputDecoration(
                labelText: 'Due Date (YYYY-MM-DD)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),

            // Notes
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 30),

            // Save Button
            ElevatedButton(
              onPressed: _saveDues,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button color
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
