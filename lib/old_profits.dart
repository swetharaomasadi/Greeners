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
  List<Map<String, dynamic>>? _oldData;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
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
    if (_currentUserId == null) return;

    setState(() {
      _isLoading = true;
    });

    DocumentSnapshot docSnapshot = await FirebaseFirestore.instance
        .collection('old_data')
        .doc(_currentUserId)
        .get();

    if (docSnapshot.exists) {
      List<Map<String, dynamic>> data =
          List<Map<String, dynamic>>.from(docSnapshot['data']);
      data.sort((a, b) =>
          (b['deleted_at'] as Timestamp).compareTo(a['deleted_at'] as Timestamp));
      setState(() {
        _oldData = data;
        _isLoading = false;
      });
    } else {
      setState(() {
        _oldData = null;
        _isLoading = false;
      });
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
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Colors.teal))
            : _oldData == null || _oldData!.isEmpty
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
                    padding: EdgeInsets.all(12),
                    itemCount: _oldData!.length,
                    itemBuilder: (context, index) {
                      var data = _oldData![index];
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
                        color: Colors.teal.shade50, // Uniform color for all cards
                        child: Padding(
                          padding: const EdgeInsets.all(14.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.eco, color: Colors.green, size: 22),
                                  SizedBox(width: 8),
                                  Text(
                                    "Crop: ${data['crop']}",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: Colors.teal.shade800,
                                    ),
                                  ),
                                ],
                              ),
                              if (data.containsKey('partner'))
                                Row(
                                  children: [
                                    Icon(Icons.handshake, color: Colors.amber[700], size: 22),
                                    SizedBox(width: 8),
                                    Text(
                                      "Partner: ${data['partner']}",
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.teal.shade700,
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
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoTile("Total Earnings", "${data['tear']}"),
                                  _infoTile("Total Expenditures", "${data['texp']}"),
                                ],
                              ),
                              SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  _infoTile("Total Profit", "${data['tp']}"),
                                  _infoTile("Total Weight", "${data['tw']}"),
                                ],
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
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.teal.shade800,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }
}
