import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchByDatePage extends StatefulWidget {
  const SearchByDatePage({super.key});

  @override
  _SearchByDatePageState createState() => _SearchByDatePageState();
}

class _SearchByDatePageState extends State<SearchByDatePage> {
  DateTime? _selectedDate;
  List<dynamic>? _records;
  List<dynamic>? _paginatedRecords;
  String? _currentUserId;
  double _totalEarnings = 0;
  double _totalExpenditures = 0;
  Map<String, List<dynamic>>? _allRecordsMap; // Local storage for all records
  bool _isLoading = false; // For loading data
  int _recordsPerPage = 10; // Number of records per page
  int _currentPage = 0; // Current page index
  final ScrollController _scrollController = ScrollController(); // Controller for detecting scroll events

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _scrollController.addListener(_scrollListener); // Add scroll listener
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // Remove scroll listener
    _scrollController.dispose(); // Dispose of the controller
    super.dispose();
  }

  void _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _fetchAllRecords(); // Fetch all records when the user is identified
      });
    }
  }

  Future<void> _fetchAllRecords() async {
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true; // Start loading before fetching data
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<String, List<dynamic>> allRecordsMap = {};

    Query query = firestore
        .collection('records')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserId!)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${_currentUserId!}\uf8ff")
        .orderBy(FieldPath.documentId, descending: true);

    QuerySnapshot userDocs = await query.get();

    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> records = data['r'] ?? [];

      for (var record in records) {
        String date = record['date'];
        if (!allRecordsMap.containsKey(date)) {
          allRecordsMap[date] = [];
        }
        allRecordsMap[date]!.add(record);
      }
    }

    setState(() {
      _allRecordsMap = allRecordsMap;
      _isLoading = false; // Stop loading after fetching data
    });
  }

  Future<void> _pickDate(BuildContext context) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _isLoading = true; // Show loading indicator
      });

      await Future.delayed(Duration(seconds: 1)); // Simulate a 1-second loading delay

      setState(() {
        _selectedDate = picked;
        _records = null;
        _totalEarnings = 0;
        _totalExpenditures = 0;
        _currentPage = 0; // Reset the current page index
      });

      _searchRecords(); // Search records when date is picked
    }
  }

  void _searchRecords() {
    if (_selectedDate == null || _allRecordsMap == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    List<dynamic> allRecords = _allRecordsMap![formattedDate] ?? [];

    double totalEarnings = 0;
    double totalExpenditures = 0;

    for (var record in allRecords) {
      if (record['t'] == 'sale') {
        totalEarnings += record['tb'] ?? 0;
      } else if (record['typ'] == 'exp') {
        totalExpenditures += record['amt'] ?? 0;
      }
    }

    setState(() {
      _records = allRecords;
      _totalEarnings = totalEarnings;
      _totalExpenditures = totalExpenditures;
      _updatePaginatedRecords(); // Update paginated records
      _isLoading = false; // Stop loading after searching records
    });
  }

  void _updatePaginatedRecords() {
    if (_records == null) return;

    int startIndex = _currentPage * _recordsPerPage;
    int endIndex = startIndex + _recordsPerPage;

    setState(() {
      _paginatedRecords = _records!.sublist(
        startIndex,
        endIndex > _records!.length ? _records!.length : endIndex,
      );
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
      _loadNextPage(); // Load next page when scrolled to the bottom
    } else if (_scrollController.position.pixels == _scrollController.position.minScrollExtent) {
      _loadPreviousPage(); // Load previous page when scrolled to the top
    }
  }

  void _loadNextPage() {
    if (_records == null) return;

    setState(() {
      if ((_currentPage + 1) * _recordsPerPage < _records!.length) {
        _currentPage++;
        _updatePaginatedRecords();
      }
    });
  }

  void _loadPreviousPage() {
    if (_records == null) return;

    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
        _updatePaginatedRecords();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    double profit = _totalEarnings - _totalExpenditures;

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

            // Display Total Earnings, Expenditures, and Profit
            if (_records != null) ...[
              Text('Total Earnings: ₹$_totalEarnings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Total Expenditures: ₹$_totalExpenditures', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Profit: ₹$profit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
            ],

            // Display Results
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator()) // Show loading indicator while fetching data
                  : _paginatedRecords == null
                      ? const Center(child: Text('Select a date and search records'))
                      : _paginatedRecords!.isEmpty
                          ? const Center(child: Text('No records found'))
                          : ListView.builder(
                              controller: _scrollController, // Attach the scroll controller
                              itemCount: _paginatedRecords!.length,
                              itemBuilder: (context, index) {
                                var record = _paginatedRecords![index];

                                String partnerName = record['partner'] ?? 'No Partner';
                                String type = record['t'] ?? record['typ'] ?? 'Unknown';

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

                                        if (type == 'sale') ...[
                                          // Profit (Sales) Records Section
                                          Text("Crop: ${record['c_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          Text("Vendor: ${record['v_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16)),
                                          Text("Total Bill: ₹${record['tb'] ?? '0'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          Text("Weight: ${record['w'] ?? '0'} kg", style: const TextStyle(fontSize: 16)),
                                        ] else if (type == 'exp') ...[
                                          // Expenditure Records Section
                                          Text("Crop: ${record['c_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          Text("Description: ${record['desc'] ?? 'Unknown'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                                          Text("Amount Spent: ₹${record['amt'] ?? '0'}", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
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