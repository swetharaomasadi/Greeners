import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'home.dart';
import 'search.dart';
import 'settings.dart';
import 'add.dart';

class RecentRecordsPage extends StatefulWidget {
  const RecentRecordsPage({super.key});

  @override
  _RecentRecordsPageState createState() => _RecentRecordsPageState();
}

class _RecentRecordsPageState extends State<RecentRecordsPage> {
  int _selectedIndex = 3; // Recent page index
  List<dynamic> _records = [];
  List<dynamic> _paginatedRecords = [];
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
      _searchRecords(); // Search records after fetching data
    });
  }

  void _searchRecords() {
    if (_allRecordsMap == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
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
    });
  }

  void _updatePaginatedRecords() {
    if (_records.isEmpty) return;

    int startIndex = _currentPage * _recordsPerPage;
    int endIndex = startIndex + _recordsPerPage;

    setState(() {
      _paginatedRecords = _records.sublist(
        startIndex,
        endIndex > _records.length ? _records.length : endIndex,
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
    if (_records.isEmpty) return;

    setState(() {
      if ((_currentPage + 1) * _recordsPerPage < _records.length) {
        _currentPage++;
        _updatePaginatedRecords();
      }
    });
  }

  void _loadPreviousPage() {
    if (_records.isEmpty) return;

    setState(() {
      if (_currentPage > 0) {
        _currentPage--;
        _updatePaginatedRecords();
      }
    });
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SearchScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RecentRecordsPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    double profit = _totalEarnings - _totalExpenditures;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Recent Records',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.deepOrange,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),

            // Display Total Earnings, Expenditures, and Profit
            if (_records.isNotEmpty) ...[
              Text('Total Earnings: ₹$_totalEarnings', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Total Expenditures: ₹$_totalExpenditures', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('Profit: ₹$profit', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 20),
            ],

            // Display Results
            Expanded(
              child: _isLoading && _records.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : _records.isEmpty
                      ? const Center(child: Text('No recent records found'))
                      : ListView.builder(
                          controller: _scrollController,
                          itemCount: _paginatedRecords.length,
                          itemBuilder: (context, index) {
                            var record = _paginatedRecords[index];

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
      bottomNavigationBar: buildBottomNavigationBar(),
    );
  }

  Widget buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.black,
      unselectedItemColor: Colors.black,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home, size: 40), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search, size: 40), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add, size: 40), label: 'Add'),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time, size: 40, color: Colors.blue), label: 'Recent'),
        BottomNavigationBarItem(icon: Icon(Icons.settings, size: 40), label: 'Settings'),
      ],
    );
  }
}