import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchViewScreen extends StatefulWidget {
  const SearchViewScreen({super.key});

  @override
  _SearchViewScreenState createState() => _SearchViewScreenState();
}

class _SearchViewScreenState extends State<SearchViewScreen> {
  int _selectedIndex = 1;
  final TextEditingController _searchController = TextEditingController();
  String _searchType = "";
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _searchResults = [];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Handle navigation based on selected index
  }

  void _performSearch() async {
    String query = _searchController.text.trim();
    if (query.isEmpty && _selectedDate == null) return;

    final User? user =
        FirebaseAuth.instance.currentUser; // Get the logged-in user

    try {
      String userId = user!
          .uid; // Replace this with actual logged-in user ID from authentication
      Query queryRef = FirebaseFirestore.instance
          .collection('records')
          .where('user_id', isEqualTo: userId); // Filter by user_id

      if (_searchType == "vendor") {
        queryRef = queryRef.where('vendor', isEqualTo: query);
      } else if (_searchType == "date" && _selectedDate != null) {
        DateTime startOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
        );
        DateTime endOfDay = DateTime(
          _selectedDate!.year,
          _selectedDate!.month,
          _selectedDate!.day,
          23,
          59,
          59,
          999,
        );

        Timestamp startTimestamp = Timestamp.fromDate(startOfDay);
        Timestamp endTimestamp = Timestamp.fromDate(endOfDay);

        queryRef = queryRef
            .where('timestamp', isGreaterThanOrEqualTo: startTimestamp)
            .where('timestamp', isLessThanOrEqualTo: endTimestamp);
      } else if (_searchType == "crop" && query.isNotEmpty) {
        queryRef = queryRef.where('item', isEqualTo: query);
      } else if (_searchType == "partners" && query.isNotEmpty) {
        queryRef = queryRef.where('partners', arrayContains: query);
      }

      QuerySnapshot snapshot = await queryRef.get();

      setState(() {
        _searchResults = snapshot.docs
            .map((doc) => doc.data() as Map<String, dynamic>)
            .toList();
      });

      // if (_searchResults.isEmpty) {
      //   print("No results found for $query in $_searchType");
      // }
    } catch (e) {
      // print("Error fetching data: $e");
    }
  }

  void _onSearchTap(String type) {
    setState(() {
      _searchType = type;
    });
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
        _searchController.text =
            "${_selectedDate?.toLocal()}".split(' ')[0]; // Format as yyyy-MM-dd
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 80,
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 30),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: _searchType.isEmpty
                  ? "Select a search category"
                  : "Enter $_searchType",
              border: OutlineInputBorder(),
              suffixIcon: IconButton(
                icon: Icon(Icons.search),
                onPressed: _performSearch,
              ),
            ),
            onSubmitted: (_) => _performSearch(),
            onTap: _searchType == "date"
                ? () => _selectDate(context)
                : null, // Open date picker when tapped if it's the date search type
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center, // Center the row
            children: [
              _buildOption(
                icon: Icons.person_search,
                label: "Vendor",
                iconSize: 30, // Reduced icon size
                iconColor: Colors.blue,
                labelColor: Colors.blue,
                onTap: () => _onSearchTap("vendor"),
              ),
              SizedBox(width: 20), // Add space between options
              _buildOption(
                icon: Icons.calendar_today,
                label: "Date",
                iconSize: 25, // Reduced icon size
                iconColor: Colors.green,
                labelColor: Colors.green,
                onTap: () => _onSearchTap("date"),
              ),
              SizedBox(width: 20), // Add space between options
              _buildOption(
                icon: Icons.agriculture,
                label: "Crop",
                iconSize: 35, // Reduced icon size
                iconColor: Colors.orange,
                labelColor: Colors.orange,
                onTap: () => _onSearchTap("crop"),
              ),
              SizedBox(width: 20), // Add space between options
              _buildOption(
                icon: Icons.group,
                label: "Partners",
                iconSize: 30, // Reduced icon size
                iconColor: Colors.purple,
                labelColor: Colors.purple,
                onTap: () => _onSearchTap("partners"),
              ),
            ],
          ),
          SizedBox(height: 20),
          Expanded(
            child: _searchResults.isEmpty
                ? Center(child: Text("No results found"))
                : SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columns: [
                        DataColumn(label: Text('Vendor')),
                        DataColumn(label: Text('Crop')),
                        DataColumn(label: Text('Amount')),
                        DataColumn(label: Text('Due Amount')),
                        // DataColumn(label: Text('Partners')),
                        // DataColumn(label: Text('Total Bill')),
                      ],
                      rows: _searchResults.map<DataRow>((record) {
                        return DataRow(cells: [
                          DataCell(Text(record['vendor'] ?? 'N/A')),
                          DataCell(Text(record['item'] ?? 'N/A')),
                          DataCell(
                              Text(record['amount_paid'].toString())),
                          DataCell(Text(
                              (record['total_bill'] - record['amount_paid'])
                                      .toString())),
                          DataCell(Text((record['partners'] != null)
                              ? record['partners'].join(', ')
                              : 'N/A')),
                          DataCell(
                              Text(record['total_bill'].toString())),
                        ]);
                      }).toList(),
                    ),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
              icon: Icon(Icons.home, size: 40), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 40, color: Colors.blue),
              label: 'Search'),
          BottomNavigationBarItem(
              icon: Icon(Icons.add, size: 40), label: 'Add'),
          BottomNavigationBarItem(
              icon: Icon(Icons.access_time, size: 40), label: 'Recent'),
          BottomNavigationBarItem(
              icon: Icon(Icons.settings, size: 40), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Function() onTap,
    double iconSize = 30,
    Color iconColor = Colors.black,
    Color labelColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 70,
            width: 70,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(35),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
