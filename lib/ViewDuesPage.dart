import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
 // For date formatting
import 'package:intl/intl.dart' as intl;

class ViewDuesPage extends StatelessWidget {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

   ViewDuesPage({super.key});

  // Helper method to calculate the days since the due date
  int calculateDaysSinceDue(Timestamp timestamp) {
    final dueDate = timestamp.toDate();
    final currentDate = DateTime.now();
    final difference = currentDate.difference(dueDate);
    return difference.inDays; // Returns the number of days difference
  }

  // Fetch dues for the current user using the user ID (UID)
  Future<List<Map<String, dynamic>>> getUserDues() async {
    final userId =
        _auth.currentUser?.uid; // Get the current logged-in user's UID

    if (userId == null) {
      throw Exception('User not logged in');
    }

    final duesSnapshot = await _firestore
        .collection('records')
        .where('user_id', isEqualTo: userId)
        .get();

    return duesSnapshot.docs
        .map((doc) => {
              'id': doc.id,
              'vendor': doc['vendor'],
              'due_amount': doc['due_amount'],
              'timestamp': doc['timestamp'], // Firestore Timestamp field
              'item':
                  doc['item'] ?? 'No item available', // Corrected field name
            })
        .toList();
  }

  // Delete a due
  Future<void> deleteDue(String dueId) async {
    try {
      await _firestore.collection('records').doc(dueId).delete();
    } catch (e) {
      print("Error deleting due: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('View All Dues'),
        backgroundColor: Colors.red, // Red for dues
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        // Asynchronous dues fetching
        future: getUserDues(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final dues = snapshot.data;

          if (dues == null || dues.isEmpty) {
            return Center(child: Text('No dues available.'));
          }

          return ListView.builder(
            itemCount: dues.length,
            itemBuilder: (context, index) {
              final due = dues[index];
              final dueTimestamp = due['timestamp'];
              final daysSinceDue = calculateDaysSinceDue(dueTimestamp);

              return ListTile(
                title: Text('Vendor: ${due['vendor']}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Amount Due: \$${due['due_amount']}'),
                    Text('Days Since Due: $daysSinceDue days'),
                    Text('Item: ${due['item']}'), // Corrected field name
                  ],
                ),
                trailing: IconButton(
                  icon: Icon(Icons.delete),
                  onPressed: () {
                    // Confirm deletion
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Delete Due'),
                          content:
                              Text('Are you sure you want to delete this due?'),
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
                                await deleteDue(due['id']);
                                Navigator.of(context).pop();
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Due deleted successfully'),
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
