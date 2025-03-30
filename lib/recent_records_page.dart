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
    _isLoading = true;
  });

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  String todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());

  try {
    QuerySnapshot userDocs = await firestore
        .collection('records')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserId!)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${_currentUserId!}\uf8ff")
        .get();

    List<dynamic> todayRecords = []; // ✅ Store only today's records

    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

      if (data.containsKey('r')) {  // ✅ Check if 'r' exists to prevent errors
        for (var record in data['r']) {
          if (record['date'] == todayDate) {  
            todayRecords.add(record); // ✅ Directly store only today's records
          }
        }
      }
    }

    // ✅ Update _records inside setState
    setState(() {
      _records = todayRecords; 
      _isLoading = false;
      if (_records.isNotEmpty) {
        _searchRecords(); // ✅ Process only if records exist
      }
    });

  } catch (e) {
    print("Error fetching today's records: $e");
    setState(() => _isLoading = false);
  }
}

  void _searchRecords() {

  double totalEarnings = 0;
  double totalExpenditures = 0;

  for (var record in _records) {
    if (record['t'] == 'sale') {
      totalEarnings += (record['tb'] ?? 0).toDouble(); // Convert to double for accuracy
    } else if (record['typ'] == 'exp') {
      totalExpenditures += (record['amt'] ?? 0).toDouble();
    }
  }

  setState(() {
    _totalEarnings = totalEarnings;
    _totalExpenditures = totalExpenditures;
  _updatePaginatedRecords(); // Update pagination after processing
  });
}


  void _updatePaginatedRecords() {
  if (_records.isEmpty) return;

  int startIndex = _currentPage * _recordsPerPage;
  int endIndex = startIndex + _recordsPerPage;

  setState(() {
    _paginatedRecords = _records.sublist(
      startIndex,
      (endIndex > _records.length) ? _records.length : endIndex,
    );
  });
}


  void _scrollListener() {
  if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
      (_currentPage + 1) * _recordsPerPage < _records.length) {
    _loadNextPage(); // ✅ Load next page only if more records exist
  } else if (_scrollController.position.pixels == _scrollController.position.minScrollExtent &&
             _currentPage > 0) {
    _loadPreviousPage(); // ✅ Load previous page only if not on the first page
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
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 5),

            // Display Total Earnings, Expenditures, and Profit
            if (_records.isNotEmpty) ...[
              Text('Total Earnings: ₹$_totalEarnings', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Total Expenditures: ₹$_totalExpenditures', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              Text('Profit: ₹$profit', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
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
                                      "$partnerName",
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.pink,
                                      ),
                                    ),
                                    const Divider(),

                                    if (type == 'sale') ...[
                                      // Profit (Sales) Records Section
                                  Text(
                                    "Crop: ${record['c_id'] ?? 'Unknown'}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green, // Corrected color format
                                    ),
                                  ),
                                      Text("Vendor: ${record['v_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 15)),
                                      Text("Total Bill: ₹${record['tb'] ?? '0'}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                                      Text("Wt: ${record['w'] ?? '0'} kg/boxes/pcs", style: const TextStyle(fontSize: 15)),
                                    ] else if (type == 'exp') ...[
                                      // Expenditure Records Section
                                  Text(
                                    "Crop: ${record['c_id'] ?? 'Unknown'}",
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.green, // Corrected color format
                                    ),
                                  ),
                                  Text("Desc: ${record['desc'] ?? 'Unknown'}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),maxLines: 2,overflow: TextOverflow.ellipsis,),
                                  Text("Amount Spent: ₹${record['amt'] ?? '0'}", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
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
        BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.search, size: 30), label: 'Search'),
        BottomNavigationBarItem(icon: Icon(Icons.add, size: 30), label: 'Add'),
        BottomNavigationBarItem(
          icon: Icon(Icons.access_time, size: 30, color: Colors.blue), label: 'Recent'),
        BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: 'Settings'),
      ],
    );
  }
}