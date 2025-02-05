import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecentRecordsPage extends StatefulWidget {
  const RecentRecordsPage({super.key});

  @override
  _RecentRecordsPageState createState() => _RecentRecordsPageState();
}

class _RecentRecordsPageState extends State<RecentRecordsPage> {
  late Stream<QuerySnapshot> _recentRecordsStream;

  @override
  void initState() {
    super.initState();

    // Fetch the logged-in user's ID
    String userId = FirebaseAuth.instance.currentUser!.uid;

    // Print userId
    print('User ID: $userId');

    // Fetch records where the user_id matches the logged-in user's ID and timestamp is within the last 24 hours
    _recentRecordsStream = FirebaseFirestore.instance
        .collection('records')
        .where('user_id', isEqualTo: userId) // Filter by logged-in user's ID
        .where('timestamp',
            isGreaterThan: Timestamp.fromDate(
                DateTime.now().subtract(Duration(days: 1)))) // Last 24 hours
        .orderBy('timestamp', descending: true) // Recent first
        .snapshots();

    // We cannot directly print the stream like a variable, but we can listen for the data
 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.orange.shade700,
        elevation: 4,
        title: Text(
          'Recent Records',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _recentRecordsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
                child: Text('No records found in the last 24 hours.',
                    style: TextStyle(fontSize: 18)));
          }

          var records = snapshot.data!.docs;
          print("Records List Length: ${records.length}");

          // Now print individual records for debugging
     
          return ListView.builder(
            padding: EdgeInsets.all(12),
            itemCount: records.length,
            itemBuilder: (context, index) {
              var record = records[index];
              double totalBill = record['total_bill'] ?? 0.0;
              double amountPaid = record['amount_paid'] ?? 0.0;
              double dues = totalBill - amountPaid;

              return Card(
                margin: EdgeInsets.symmetric(vertical: 10),
                color: Colors.white,
                elevation: 6,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_cart, color: Colors.orange, size: 24),
                          SizedBox(width: 8),
                          Text(
                            record['item'] ?? 'No item',
                            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person, color: Colors.blue, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Vendor: ${record['vendor']}',
                            style: TextStyle(fontSize: 16, color: Colors.blue.shade700),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.attach_money, color: Colors.green, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Total Bill: ₹${totalBill.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.payment, color: Colors.teal, size: 22),
                          SizedBox(width: 8),
                          Text(
                            'Amount Paid: ₹${amountPaid.toStringAsFixed(2)}',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.warning,
                              color: dues > 0 ? Colors.red : Colors.green,
                              size: 22),
                          SizedBox(width: 8),
                          Text(
                            dues > 0
                                ? 'Dues: ₹${dues.toStringAsFixed(2)}'
                                : 'No Dues 🎉',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: dues > 0 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
