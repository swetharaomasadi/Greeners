import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class Olddata extends StatefulWidget {
  @override
  _OldProfitsState createState() => _OldProfitsState();
}

class _OldProfitsState extends State<Olddata> {
  String? _currentUserId;
  List<Map<String, dynamic>> _oldData = [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  bool _hasMoreData = true;
  int _currentPage = 0;
  final int _limit = 10;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _scrollController.addListener(_onScroll);
  }

  void _getCurrentUser() async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _currentUserId = user.uid;
        _fetchOldData();
      });
    }
  }

  Future<void> _fetchOldData() async {
    if (_currentUserId == null || !_hasMoreData) return;

    setState(() {
      _isLoading = true;
    });

    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('old_data')
        .doc(_currentUserId)
        .get();

    if (docSnapshot.exists) {
      List<Map<String, dynamic>> allRecords =
          List<Map<String, dynamic>>.from(docSnapshot['data']);

      // Sort by 'deleted_at' (latest first)
      allRecords.sort((a, b) =>
          (b['deleted_at'] as Timestamp).compareTo(a['deleted_at'] as Timestamp));

      // Apply pagination manually
      int startIndex = _currentPage * _limit;
      int endIndex = startIndex + _limit;
      List<Map<String, dynamic>> paginatedRecords =
          allRecords.sublist(startIndex, endIndex > allRecords.length ? allRecords.length : endIndex);

      setState(() {
        _oldData.addAll(paginatedRecords);
        _isLoading = false;
        _hasMoreData = endIndex < allRecords.length; // Check if more data exists
        _currentPage++;
      });
    } else {
      setState(() {
        _oldData = [];
        _isLoading = false;
        _hasMoreData = false;
      });
    }
  }

  void _onScroll() {
    if (_scrollController.position.pixels ==
            _scrollController.position.maxScrollExtent &&
        !_isLoadingMore &&
        _hasMoreData) {
      _fetchOldData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Old Profits'),
        centerTitle: true,
        backgroundColor: Colors.teal[600],
        elevation: 4,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade50, Colors.teal.shade100],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: _isLoading && _oldData.isEmpty
            ? Center(child: CircularProgressIndicator(color: Colors.teal))
            : _oldData.isEmpty
                ? Center(
                    child: Text(
                      'No crops completed',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.teal.shade700,
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.all(12),
                    itemCount: _oldData.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _oldData.length) {
                        return _hasMoreData
                            ? Center(child: CircularProgressIndicator(color: Colors.teal))
                            : SizedBox.shrink();
                      }

                      var data = _oldData[index];
                      var deletedAt =
                          (data['deleted_at'] as Timestamp).toDate();
                      var formattedDate = DateFormat('d MMM yyyy, hh:mm a')
                          .format(deletedAt);

                      return Card(
                        margin: const EdgeInsets.symmetric(
                            vertical: 10, horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 6,
                        color: Colors.teal.shade50,
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, color: Colors.green, size: 22),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        _showFullNameDialog("Crop Name", data['crop']);
                                      },
                                      child: Text(
                                        "Crop: ${data['crop']}",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.teal.shade800,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              if (data.containsKey('partner'))
                                Row(
                                  children: [
                                    Icon(Icons.handshake, color: Colors.amber[700], size: 22),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () {
                                          _showFullNameDialog("Partner Name", data['partner']);
                                        },
                                        child: Text(
                                          "Partner: ${data['partner']}",
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.teal.shade700,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              Divider(
                                color: Colors.teal.shade300,
                                thickness: 1,
                                height: 10,
                              ),
                              Text(
                                "🕒 Deleted At: $formattedDate",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: 10),
                              Center(
                                child: Column(
                                  children: [
                                    _infoTile("Total Earnings", "${data['tear']}"),
                                    SizedBox(height: 5),
                                    _infoTile("Total Expenditures", "${data['texp']}"),
                                    SizedBox(height: 5),
                                    _infoTile("Total Profit", "${data['tp']}"),
                                    SizedBox(height: 5),
                                    _infoTile("Total Weight", "${data['tw']}"),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return Column(
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  void _showFullNameDialog(String title, String fullName) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(fullName, style: TextStyle(fontSize: 16)),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Close"),
            ),
          ],
        );
      },
    );
  }
}
