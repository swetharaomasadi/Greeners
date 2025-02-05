import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth

class ViewRecordsPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

   ViewRecordsPage({super.key});

  // Fetch records for the current user using the user ID (UID)
  Future<List<Map<String, dynamic>>> getUserRecords() async {
    final userId =
        _auth.currentUser?.uid; // Get the current logged-in user's UID

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final recordsSnapshot = await _firestore
        .collection('records')
        .where('user_id', isEqualTo: userId)
        .get();

    return recordsSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'vendor': doc['vendor'],
              'item': doc['item'],
              'amount_paid': doc['amount_paid'],
            })
        .toList();
  }

  // Delete a record
  Future<void> deleteRecord(String recordId) async {
    try {
      await _firestore.collection('records').doc(recordId).delete();
    } catch (e) {
      print("Error deleting record: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View All Records'),
        backgroundColor: Colors.green,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Asynchronous record fetching
        future: getUserRecords(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final records = snapshot.data;

          if (records == null || records.isEmpty) {
            return Center(child: Text('No records available.'));
          }

          return ListView.builder(
            itemCount: records.length,
            itemBuilder: (context, index) {
              final record = records[index];

              return ListTile(
                title: Text(record['vendor'] ?? 'Unknown Vendor'),
                subtitle: Text(
                    'Item: ${record['item']} - Amount: \$${record['amount_paid']}'),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Confirm deletion
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Delete Record'),
                          content: Text(
                              'Are you sure you want to delete this record?'),
                          actions: <Widget>[
                            TextButton(
                              onPressed: () {
                                // Close the dialog
                                Navigator.of(context).pop();
                              },
                              child: Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () async {
                                await deleteRecord(record['id']);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content:
                                        Text('Record deleted successfully'),
                                  ),
                                );
                              },
                              child: Text('Delete'),
                            ),
                          ],
                        );
                      },
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
