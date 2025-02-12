import 'package:flutter/material.dart'; 
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'home.dart';
import 'search_date.dart';
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
  List<QueryDocumentSnapshot>? _records;
  String? _selectedCollection;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _fetchRecentRecords('records');
  }

  void _getCurrentUser() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
      });
    }
  }

  Future<void> _fetchRecentRecords(String collection) async {
    if (_currentUserId == null) return;

    Timestamp last24Hours = Timestamp.fromDate(
      DateTime.now().subtract(const Duration(hours: 24)),
    );

    QuerySnapshot snapshot = await FirebaseFirestore.instance
        .collection(collection)
        .where('timestamp', isGreaterThanOrEqualTo: last24Hours)
        .where('user_id', isEqualTo: _currentUserId)
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _records = snapshot.docs;
      _selectedCollection = collection;
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCollection == 'records'
                        ? Colors.deepOrange
                        : Colors.grey,
                  ),
                  onPressed: () => _fetchRecentRecords('records'),
                  child: const Text('Profit Records'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedCollection == 'expenditures'
                        ? Colors.deepOrange
                        : Colors.grey,
                  ),
                  onPressed: () => _fetchRecentRecords('expenditures'),
                  child: const Text('Expenditure Records'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _records == null
                  ? const Center(child: Text('Loading records...'))
                  : _records!.isEmpty
                      ? const Center(child: Text('No recent records found'))
                      : ListView.builder(
                          itemCount: _records!.length,
                          itemBuilder: (context, index) {
                            var record =
                                _records![index].data() as Map<String, dynamic>;
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              elevation: 4,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(Icons.person,
                                            color: Colors.deepPurple, size: 26),
                                        const SizedBox(width: 8),
                                        Expanded(
                                          child: Text(
                                            'Partner: ${record['partner'] ?? 'No Partner'}',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.deepPurple,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                            maxLines: 1,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    if (_selectedCollection == 'records') ...[
                                      buildRow(Icons.eco, 'Crop', record['item'], Colors.green),
                                      buildRow(Icons.store, 'Vendor', record['vendor'], Colors.blue),
                                      buildRow(Icons.attach_money, 'Total Bill', '₹${record['total_bill'] ?? '0'}', Colors.purple),
                                      buildRow(Icons.payment, 'Amount Paid', '₹${record['amount_paid'] ?? '0'}', Colors.teal),
                                      buildRow(Icons.warning, 'Dues', '₹${record['due_amount'] ?? '0'}', Colors.red),
                                    ] else ...[
                                      buildRow(Icons.eco, 'Crop', record['crop_name'], Colors.green),
                                      buildRow(Icons.description, 'Description', record['description'], Colors.grey),
                                      buildRow(Icons.money, 'Amount', '₹${record['amount'] ?? '0'}', Colors.blue),
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
      bottomNavigationBar: BottomNavigationBar(
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
      ),
    );
  }

  Widget buildRow(IconData icon, String label, dynamic value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '$label: ${value ?? 'N/A'}',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}
