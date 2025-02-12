import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class SearchByDatePage extends StatefulWidget {
  const SearchByDatePage({super.key});

  @override
  _SearchByDatePageState createState() => _SearchByDatePageState();
}

class _SearchByDatePageState extends State<SearchByDatePage> {
  DateTime? _selectedDate;
  List<QueryDocumentSnapshot>? _records;
  String? _selectedCollection;
  String? _currentUserId; // Store the current user's ID

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
  }

  // Get the currently logged-in user's UID
  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid; // Store the user ID
      });
    }
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _records = null; // Reset results on new selection
      });
    }
  }

  Future<void> _searchRecords(String collection) async {
    if (_selectedDate == null || _currentUserId == null) return;

    Timestamp startTimestamp = Timestamp.fromDate(
      DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 0, 0, 0),
    );
    Timestamp endTimestamp = Timestamp.fromDate(
      DateTime(_selectedDate!.year, _selectedDate!.month, _selectedDate!.day, 23, 59, 59),
    );

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
        .where('timestamp', isLessThanOrEqualTo: endTimestamp)
        .where('user_id', isEqualTo: _currentUserId) // Filter by user ID
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _records = snapshot.docs;
      _selectedCollection = collection;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search by Date'),
        backgroundColor: Colors.orange.shade700,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Date Picker
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'Select a Date'
                      : DateFormat('d MMMM yyyy').format(_selectedDate!),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  onPressed: () => _pickDate(context),
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Search Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => _searchRecords('records'),
                  child: const Text('Profit Records'),
                ),
                ElevatedButton(
                  onPressed: () => _searchRecords('expenditures'),
                  child: const Text('Expenditure Records'),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Display Results
            Expanded(
              child: _records == null
                  ? const Center(child: Text('Select a date and search records'))
                  : _records!.isEmpty
                      ? const Center(child: Text('No records found'))
                      : ListView.builder(
                          itemCount: _records!.length,
                          itemBuilder: (context, index) {
                            var record = _records![index].data() as Map<String, dynamic>;

                            // Get partner field correctly
                            String partnerName = _selectedCollection == 'records'
                                ? (record['partners'] != null && record['partners'].isNotEmpty
                                    ? record['partners']
                                    : 'No Partner')
                                : (record['partner'] != null && record['partner'].isNotEmpty
                                    ? record['partner']
                                    : 'No Partner');

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Partner Name
                                    Text(
                                      "Partner: $partnerName",
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.deepOrange,
                                      ),
                                    ),
                                    const Divider(),

                                    if (_selectedCollection == 'records') ...[
                                      // Profit Records Section
                                      Text("Item: ${record['item'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text("Vendor: ${record['vendor'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                                      Text("Total Bill: ₹${record['total_bill'] ?? '0'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text("Amount Paid: ₹${record['amount_paid'] ?? '0'}", style: const TextStyle(fontSize: 16)),
                                      Text("Dues: ₹${record['due_amount'] ?? '0'}", style: const TextStyle(fontSize: 16, color: Colors.red)),
                                      
                                    ] else ...[
                                      // Expenditure Records Section
                                      Text("Crop Name: ${record['crop_name'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text("Description: ${record['description'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                      Text("Amount: ₹${record['amount'] ?? '0'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                    ],
                                  ],
                                ),
                              ),
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
