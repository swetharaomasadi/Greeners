import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DeleteRecords extends StatefulWidget {
  DeleteRecords({super.key});

  @override
  _DisplayPartnersState createState() => _DisplayPartnersState();
}

class _DisplayPartnersState extends State<DeleteRecords> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<String> _partners = [];
  String? _selectedPartner;
  String _cropName = '';
  List<QueryDocumentSnapshot> _records = [];
  List<QueryDocumentSnapshot> _selectedRecords = []; // Store selected records
  bool _isLoading = false;
  bool _selectAll = false; // Track "Select All" status

  @override
  void initState() {
    super.initState();
    _fetchPartners();
  }

  // Fetch distinct partners for the current user
  Future<void> _fetchPartners() async {
    final userId = _auth.currentUser?.uid;

    if (userId == null) {
      return;
    }

    try {
      final recordsSnapshot = await _firestore
          .collection('records')
          .where('user_id', isEqualTo: userId)
          .get();

      final expendituresSnapshot = await _firestore
          .collection('expenditures')
          .where('user_id', isEqualTo: userId)
          .get();

      final partners = {
        ...recordsSnapshot.docs.map((doc) => doc['partner'] as String),
        ...expendituresSnapshot.docs.map((doc) => doc['partner'] as String),
      };

      setState(() {
        _partners = partners.toList();
      });
    } catch (e) {
      print("Error fetching partners: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching partners. Please try again.')),
      );
    }
  }

  // Fetch records based on selected partner and crop name
  Future<void> _fetchRecords() async {
    final userId = _auth.currentUser?.uid;

    if (userId == null || _selectedPartner == null || _cropName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select a partner and enter a crop name')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final recordsSnapshot = await _firestore
          .collection('records')
          .where('user_id', isEqualTo: userId)
          .where('partner', isEqualTo: _selectedPartner)
          .where('item', isEqualTo: _cropName)
          .get();

      final expendituresSnapshot = await _firestore
          .collection('expenditures')
          .where('user_id', isEqualTo: userId)
          .where('partner', isEqualTo: _selectedPartner)
          .where('crop_name', isEqualTo: _cropName)
          .get();

      setState(() {
        _records = [
          ...recordsSnapshot.docs,
          ...expendituresSnapshot.docs,
        ];
      });
    } catch (e) {
      print("Error fetching records: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching records. Please try again.')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Delete multiple records
  Future<void> _deleteSelectedRecords() async {
    try {
      for (var record in _selectedRecords) {
        await record.reference.delete();
      }

      setState(() {
        _records.removeWhere((record) => _selectedRecords.contains(record));
        _selectedRecords.clear();
        _selectAll = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Selected records deleted successfully.')),
      );
    } catch (e) {
      print("Error deleting records: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting records. Please try again.')),
      );
    }
  }

  // Toggle "Select All" option
  void _toggleSelectAll() {
    setState(() {
      if (_selectAll) {
        _selectedRecords.clear();
      } else {
        _selectedRecords = List.from(_records);
      }
      _selectAll = !_selectAll;
    });
  }

  // Toggle record selection
  void _toggleRecordSelection(QueryDocumentSnapshot record) {
    setState(() {
      if (_selectedRecords.contains(record)) {
        _selectedRecords.remove(record);
      } else {
        _selectedRecords.add(record);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Select Partner & Crop'),
        backgroundColor: Colors.green,
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Partner',
                border: OutlineInputBorder(),
              ),
              items: _partners
                  .map((partner) => DropdownMenuItem(
                        value: partner,
                        child: Text(partner),
                      ))
                  .toList(),
              value: _selectedPartner,
              onChanged: (value) {
                setState(() {
                  _selectedPartner = value;
                });
              },
            ),
            SizedBox(height: 16.0),
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Crop Name',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                setState(() {
                  _cropName = value;
                });
              },
            ),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: _fetchRecords,
              child: Text('Submit'),
            ),
            SizedBox(height: 16.0),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Column(
                    children: [
                      // Move "Select All" checkbox here
                      Row(
                        children: [
                          Checkbox(
                            value: _selectAll,
                            onChanged: (value) => _toggleSelectAll(),
                          ),
                          Text('Select All'),
                        ],
                      ),
                      ElevatedButton(
                        onPressed: _deleteSelectedRecords,
                        child: Text('Delete Selected Records'),
                        style: ButtonStyle(
                          backgroundColor:
                              MaterialStateProperty.all(Colors.red),
                        ),
                      ),
                      SizedBox(height: 16.0),
                      _records.isEmpty
                          ? Center(child: Text('No records found'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: _records.length,
                              itemBuilder: (context, index) {
                                final record = _records[index];
                                final data = record.data() as Map<String, dynamic>;
                                return ListTile(
                                  leading: Checkbox(
                                    value: _selectedRecords.contains(record),
                                    onChanged: (bool? value) {
                                      _toggleRecordSelection(record);
                                    },
                                  ),
                                  title: Text(data['vendor'] ?? data['crop_name']),
                                  subtitle: Text(data['item'] != null
                                      ? 'Item: ${data['item']} - Paid: \$${data['amount_paid']}'
                                      : 'Amount: \$${data['amount']} - Description: ${data['description']}'),
                                );
                              },
                            ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
