import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DeleteRecordsPage extends StatefulWidget {
  @override
  _DeleteRecordsPageState createState() => _DeleteRecordsPageState();
}

class _DeleteRecordsPageState extends State<DeleteRecordsPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;

  DateTime? _selectedDate;

  List<Map<String, dynamic>> _records = [];
  bool _isLoading = false;

  Future<void> _fetchRecords() async {
    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a date')),
      );
      return;
    }

    if (user == null) return;
    setState(() {
      _isLoading = true;
      _records = [];
    });

    String dateString = DateFormat('yyyy-MM-dd').format(_selectedDate!);

    Query collectionQuery = _firestore.collection('records')
        .where('u_id', isEqualTo: user!.uid)
        .where('date', isEqualTo: dateString);

    QuerySnapshot querySnapshot = await collectionQuery.get();

    for (var doc in querySnapshot.docs) {
      Map<String, dynamic> docData = (doc.data() as Map<String, dynamic>?) ?? {};
      List<dynamic> records = List.from(docData['r'] ?? []);
      for (var record in records) {
        if (record is Map<String, dynamic>) {
          setState(() {
            _records.add({'docId': doc.id, 'record': record});
          });
        }
      }
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _deleteRecord(String docId, Map<String, dynamic> record) async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
    });

    DocumentReference docRef = _firestore.collection('records').doc(docId);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      Map<String, dynamic> docData = (docSnapshot.data() as Map<String, dynamic>?) ?? {};
      List<dynamic> records = List.from(docData['r'] ?? []);
      records.remove(record);

      await docRef.update({'r': records});
    }

    setState(() {
      _records.removeWhere((r) => r['docId'] == docId);
      _isLoading = false;
    });
  }

  Future<void> _updateRecord(String docId, Map<String, dynamic> oldRecord, Map<String, dynamic> newRecord) async {
    if (user == null) return;
    setState(() {
      _isLoading = true;
    });

    DocumentReference docRef = _firestore.collection('records').doc(docId);
    DocumentSnapshot docSnapshot = await docRef.get();

    if (docSnapshot.exists) {
      Map<String, dynamic> docData = (docSnapshot.data() as Map<String, dynamic>?) ?? {};
      List<dynamic> records = List.from(docData['r'] ?? []);
      int index = records.indexOf(oldRecord);
      if (index != -1) {
        records[index] = newRecord;
        await docRef.update({'r': records});
      }
    }

    setState(() {
      int index = _records.indexWhere((r) => r['docId'] == docId);
      if (index != -1) {
        _records[index] = {'docId': docId, 'record': newRecord};
      }
      _isLoading = false;
    });
  }

  void _showUpdateDialog(String docId, Map<String, dynamic> record) {
    final TextEditingController partnerController = TextEditingController(text: record['partner'] ?? '');
    final TextEditingController vendorController = TextEditingController(text: record['v_id'] ?? '');
    final TextEditingController cropController = TextEditingController(text: record['c_id'] ?? '');
    final TextEditingController dateController = TextEditingController(text: record['date'] ?? '');
    final TextEditingController weightController = TextEditingController(text: record['w']?.toString() ?? '');
    final TextEditingController totalBillController = TextEditingController(text: record['tb']?.toString() ?? '');
    final TextEditingController amountPaidController = TextEditingController(text: record['amount_paid']?.toString() ?? '');
    final TextEditingController descriptionController = TextEditingController(text: record['desc'] ?? '');
    final TextEditingController amountController = TextEditingController(text: record['amt']?.toString() ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Update Record'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(controller: partnerController, decoration: InputDecoration(labelText: 'Partner'), readOnly: true),
                if (record.containsKey('v_id'))
                  TextField(controller: vendorController, decoration: InputDecoration(labelText: 'Vendor Name')),
                TextField(controller: cropController, decoration: InputDecoration(labelText: 'Crop Name')),
                TextField(controller: dateController, decoration: InputDecoration(labelText: 'Date'), readOnly: true),
                if (record.containsKey('w'))
                  TextField(controller: weightController, decoration: InputDecoration(labelText: 'Weight')),
                if (record.containsKey('tb'))
                  TextField(controller: totalBillController, decoration: InputDecoration(labelText: 'Total Bill')),
                if (record.containsKey('amount_paid'))
                  TextField(controller: amountPaidController, decoration: InputDecoration(labelText: 'Amount Paid')),
                if (record.containsKey('desc'))
                  TextField(controller: descriptionController, decoration: InputDecoration(labelText: 'Description')),
                if (record.containsKey('amt'))
                  TextField(controller: amountController, decoration: InputDecoration(labelText: 'Amount')),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            ElevatedButton(
              child: Text('Update'),
              onPressed: () {
                Navigator.of(context).pop();
                Map<String, dynamic> newRecord = {
                  'partner': partnerController.text.toLowerCase(),
                  'v_id': vendorController.text.toLowerCase(),
                  'c_id': cropController.text.toLowerCase(),
                  'date': dateController.text,
                  if (record.containsKey('w')) 'w': double.tryParse(weightController.text) ?? 0.0,
                  if (record.containsKey('tb')) 'tb': double.tryParse(totalBillController.text) ?? 0.0,
                  if (record.containsKey('amount_paid')) 'amount_paid': double.tryParse(amountPaidController.text) ?? 0.0,
                  if (record.containsKey('desc')) 'desc': descriptionController.text,
                  if (record.containsKey('amt')) 'amt': double.tryParse(amountController.text) ?? 0.0,
                };
                _updateRecord(docId, record, newRecord);
              },
            ),
          ],
        );
      },
    );
  }

  void _showActionDialog(String docId, Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Choose Action'),
          content: Text('Do you want to update or delete this record?'),
          actions: [
            TextButton(
              child: Text('Update'),
              onPressed: () {
                Navigator.of(context).pop();
                _showUpdateDialog(docId, record);
              },
            ),
            TextButton(
              child: Text('Delete'),
              onPressed: () {
                Navigator.of(context).pop();
                _deleteRecord(docId, record);
              },
            ),
          ],
        );
      },
    );
  }

  bool get _areMandatoryFieldsFilled {
    return _selectedDate != null;
  }

  Widget _buildFilterForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          onTap: () async {
            DateTime? pickedDate = await showDatePicker(
              context: context,
              initialDate: DateTime.now(),
              firstDate: DateTime(2000),
              lastDate: DateTime(2101),
            );
            if (pickedDate != null) {
              setState(() {
                _selectedDate = pickedDate;
              });
            }
          },
          readOnly: true,
          decoration: InputDecoration(
            labelText: 'Date',
            suffixIcon: Icon(Icons.calendar_today),
          ),
          controller: TextEditingController(
            text: _selectedDate != null ? DateFormat('yyyy-MM-dd').format(_selectedDate!) : '',
          ),
        ),
        SizedBox(height: 20),
        ElevatedButton(
          onPressed: _areMandatoryFieldsFilled ? _fetchRecords : null,
          style: ButtonStyle(
            backgroundColor: MaterialStateProperty.all(_areMandatoryFieldsFilled ? Colors.blue : Colors.grey),
          ),
          child: Text('Fetch Records'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Manage Records'),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Note: Actions performed will also affect total profits and dues.',
              style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20),
            _buildFilterForm(),
            SizedBox(height: 20),
            Expanded(
              child: _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : ListView.separated(
                      itemCount: _records.length,
                      separatorBuilder: (context, index) => Divider(),
                      itemBuilder: (context, index) {
                        Map<String, dynamic> recordData = _records[index];
                        String docId = recordData['docId'];
                        Map<String, dynamic> record = recordData['record'];

                        return ListTile(
                          title: Text(record['t'] == 'sales'
                              ? 'Vendor Name: ${record['v_id']}, Crop Name: ${record['c_id']}'
                              : 'Crop Name: ${record['c_id']}, Description: ${record['desc']}'),
                          subtitle: Text('Date: ${record['date']}, Amount: ${record['tb'] ?? record['amt']}'),
                          onTap: () => _showActionDialog(docId, record),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}