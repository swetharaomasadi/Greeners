import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:flutter_tts/flutter_tts.dart';


class DeleteRecordsPage extends StatefulWidget {
  @override
  _DeleteRecordsPageState createState() => _DeleteRecordsPageState();
}

class _DeleteRecordsPageState extends State<DeleteRecordsPage> {
  final FlutterTts flutterTts = FlutterTts();
  String? _currentUserId;
  Map<String, List<Map<String, dynamic>>>? _allRecords; // Local storage for all records
  bool _isLoading = false; // For loading data
  bool _isDeleting = false; // For tracking deletion status
  bool _isFetchingMore = false; // ✅ Track if more records are being fetched
  bool _hasMoreRecords = true; // ✅ Track if there are more records to load
  DocumentSnapshot? _lastDocument; // ✅ Store last document for pagination
  final int _fetchLimit = 10; // ✅ Number of records per page
  
  final ScrollController _scrollController = ScrollController(); // ✅ Added ScrollController

  @override
  void initState() {
    super.initState();
    _getCurrentUser();
    _scrollController.addListener(_scrollListener); // ✅ Attach listener
  }
  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !_isFetchingMore &&
        _hasMoreRecords) {
      _fetchAllRecords(); // ✅ Fetch more records when scrolling reaches the bottom
    }
  }
  
@override
void dispose() {
  _scrollController.dispose();
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
  if (_currentUserId == null || !_hasMoreRecords || _isFetchingMore) return;

  setState(() {
    _isFetchingMore = true; // Start loading before fetching data
  });

  FirebaseFirestore firestore = FirebaseFirestore.instance;
  Map<String, List<Map<String, dynamic>>> allRecords = _allRecords ?? {};

  Query query = firestore
      .collection('records')
      .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserId!)
      .where(FieldPath.documentId, isLessThanOrEqualTo: "${_currentUserId!}\uf8ff")
      .orderBy(FieldPath.documentId, descending: true)
      .limit(_fetchLimit);

  if (_lastDocument != null) {
    query = query.startAfterDocument(_lastDocument!);
  }

  QuerySnapshot userDocs = await query.get();
  if (userDocs.docs.isNotEmpty) {
    _lastDocument = userDocs.docs.last;
    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> records = data['r'] ?? [];

      for (var record in records) {
        String date = record['date'];
        allRecords.putIfAbsent(date, () => []).add({
          'record': record,
          'docId': doc.id,
        });
      }
    }
  }

  setState(() {
    _allRecords = allRecords;
    _isFetchingMore = false; // Stop loading after fetching data
    _hasMoreRecords = userDocs.docs.length == _fetchLimit; // Stop if fewer than limit
  });
}
  void _navigateToFindByDate() {
    if (_currentUserId != null && _allRecords != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => FindByDatePage(
            userId: _currentUserId!,
            records: _allRecords,
            deleteRecordCallback: _deleteRecord, // Pass the callback
          ),
        ),
      );
    }
  }

  Future<List<QueryDocumentSnapshot>> _fetchDuesDocuments(String vendorId) async {
    List<QueryDocumentSnapshot> allDuesDocs = [];
    Query query = FirebaseFirestore.instance
        .collection('dues')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserId!)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${_currentUserId!}\uf8ff")
        .orderBy(FieldPath.documentId, descending: true);

    bool hasMore = true;
    QueryDocumentSnapshot? lastDoc;

    while (hasMore) {
      QuerySnapshot snapshot;
      if (lastDoc == null) {
        snapshot = await query.limit(10).get();
      } else {
        snapshot = await query.startAfterDocument(lastDoc).limit(10).get();
      }

      if (snapshot.docs.isNotEmpty) {
        allDuesDocs.addAll(snapshot.docs);
        lastDoc = snapshot.docs.last;
        if (snapshot.docs.length < 10) {
          hasMore = false;
        }
      } else {
        hasMore = false;
      }
    }

    return allDuesDocs;
  }

  void _deleteRecord(Map<String, dynamic> recordData) async {
    setState(() {
      _isDeleting = true; // Start the deletion loading indicator
    });

    String type = recordData['record']['t'] ?? recordData['record']['typ'] ?? 'Unknown';
    WriteBatch batch = FirebaseFirestore.instance.batch();

    DocumentReference recordRef = FirebaseFirestore.instance.collection('records').doc(recordData['docId']);
    batch.update(recordRef, {
      'r': FieldValue.arrayRemove([recordData['record']]),
    });

    if (type == 'sale') {
      // Fetch all dues documents until vendor name is matched
      String vendorId = recordData['record']['v_id'] ?? 'Unknown';
      String crop = recordData['record']['c_id'] ?? 'Unknown';
      List<QueryDocumentSnapshot> duesDocs = await _fetchDuesDocuments(vendorId);
      bool canDelete = false; // Track if a matching dues record is found

for (var dueDoc in duesDocs) {
  Map<String, dynamic> dueData = dueDoc.data() as Map<String, dynamic>;
  List<dynamic> duesList = dueData['d'] ?? [];

  for (var due in duesList) {
    if (due['vendor_id'] == vendorId && 
        due['crop_id'] == crop && 
        (due['total_bill'] ?? 0) >= recordData['record']['tb']) {
      
      // Adjust dues amounts
      due['total_bill'] = (due['total_bill'] ?? 0) - recordData['record']['tb'];
      due['total_due'] = (due['total_due'] ?? 0) - (recordData['record']['tb'] - recordData['record']['a_p']);
      due['amount_paid'] = (due['amount_paid'] ?? 0) - recordData['record']['a_p'];
      due['weight'] = due['weight'] - recordData['record']['w'];

      batch.update(dueDoc.reference, {'d': duesList});
      canDelete = true;
      break; // Stop searching once we find a match
    }
  }

  if (canDelete) break; // Stop checking other docs if a match is found
}

//  If no matching dues record was found, stop the deletion process
if (!canDelete) {
  setState(() {
    _isDeleting = false; // Stop the deletion loading indicator
  });
  await flutterTts.speak("Unable to delete");
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text("Cannot delete record. No matching dues found.")),
  );
  return; // Stop execution to prevent committing an incomplete batch
}
      // Fetch all partner documents until the partner and crop are found
      QuerySnapshot partnerSnapshot = await FirebaseFirestore.instance
          .collection('partners')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserId!)
          .where(FieldPath.documentId, isLessThanOrEqualTo: "${_currentUserId!}\uf8ff")
          .orderBy(FieldPath.documentId, descending: true)
          .get();
      for (var partnerDoc in partnerSnapshot.docs) {
        Map<String, dynamic>? partnerData = partnerDoc.data() as Map<String, dynamic>?;
        if (partnerData != null) {
          Map<String, dynamic> cropData = partnerData['profits'][recordData['record']['partner']]['crops'][recordData['record']['c_id']];
          if (cropData != null) {
            batch.update(partnerDoc.reference, {
              'profits.${recordData['record']['partner']}.tp': FieldValue.increment(-recordData['record']['tb']),
              'profits.${recordData['record']['partner']}.tear': FieldValue.increment(-recordData['record']['tb']),
              'profits.${recordData['record']['partner']}.crops.${recordData['record']['c_id']}.tp': FieldValue.increment(-recordData['record']['tb']),
              'profits.${recordData['record']['partner']}.crops.${recordData['record']['c_id']}.tw': FieldValue.increment(-recordData['record']['w']),
              'profits.${recordData['record']['partner']}.crops.${recordData['record']['c_id']}.tear': FieldValue.increment(-recordData['record']['tb']),
            });
            break;
          }
        }
      }
    } else if (type == 'exp') {
      // Fetch all partner documents until the partner and crop are found
      QuerySnapshot partnerSnapshot = await FirebaseFirestore.instance
          .collection('partners')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: _currentUserId!)
          .where(FieldPath.documentId, isLessThanOrEqualTo: "${_currentUserId!}\uf8ff")
          .orderBy(FieldPath.documentId, descending: true)
          .get();
      for (var partnerDoc in partnerSnapshot.docs) {
        Map<String, dynamic>? partnerData = partnerDoc.data() as Map<String, dynamic>?;
        if (partnerData != null) {
          Map<String, dynamic> cropData = partnerData['profits'][recordData['record']['partner']]['crops'][recordData['record']['c_id']];
          if (cropData != null) {
            batch.update(partnerDoc.reference, {
              'profits.${recordData['record']['partner']}.tp': FieldValue.increment(recordData['record']['amt']),
              'profits.${recordData['record']['partner']}.texp': FieldValue.increment(-recordData['record']['amt']),
              'profits.${recordData['record']['partner']}.crops.${recordData['record']['c_id']}.tp': FieldValue.increment(recordData['record']['amt']),
              'profits.${recordData['record']['partner']}.crops.${recordData['record']['c_id']}.texp': FieldValue.increment(-recordData['record']['amt']),
            });
            break;
          }
        }
      }
    }
  try{
    await batch.commit();

    // Remove the record from local variable
    setState(() {
      String date = recordData['record']['date'];
      _allRecords?[date]?.removeWhere((record) => record['docId'] == recordData['docId'] && record['record'] == recordData['record']);
      _isDeleting = false; // Stop the deletion loading indicator
    });
    await flutterTts.speak("Successfully deleted");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Record deleted successfully!")));

  }catch (e) {
    setState(() {
      _isDeleting = false;
    });

    await flutterTts.speak("Failed");
    await flutterTts.speak("Unable to delete");
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error deleting record: $e")));
  }
}

  @override
  Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text("Delete Record"),
      backgroundColor: Colors.green,
    ),
    body: _isLoading
        ? Center(child: CircularProgressIndicator())
        : Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      "Select a date to view records",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      "Changes will also make changes in total profit and dues.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.red,
                      ),
                    ),
                    SizedBox(height: 10),
                    OptionButton(text: "Find by Date", onTap: _navigateToFindByDate),
                  ],
                ),
              ),
              Expanded(
  child: _allRecords == null || _allRecords!.isEmpty
      ? Center()
      : ListView.builder(
          controller: _scrollController,
          itemCount: _allRecords!.length + 1,
          itemBuilder: (context, index) {
            if (index == _allRecords!.length) {
              return _isFetchingMore
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox.shrink();
            }

            // Remove the display of 'date:' and 'records no:'
            // String date = _allRecords!.keys.elementAt(index);
            return Card(
              margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              elevation: 4,
            );
          },
        ),
        ),
            ],
          ),
  );
}
}
class OptionButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const OptionButton({
    required this.text,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color.fromARGB(255, 66, 221, 71),
          minimumSize: Size(double.infinity, 50),
          textStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        onPressed: onTap,
        child: Text(text, textAlign: TextAlign.center),
      ),
    );
  }
}

class FindByDatePage extends StatefulWidget {
  final String userId;
  final Map<String, List<Map<String, dynamic>>>? records;
  final Function(Map<String, dynamic>) deleteRecordCallback; // Add this line

  const FindByDatePage({Key? key, required this.userId, required this.records, required this.deleteRecordCallback}) : super(key: key); // Update this line

  @override
  _FindByDatePageState createState() => _FindByDatePageState();
}

class _FindByDatePageState extends State<FindByDatePage> {
  DateTime? _selectedDate;
  List<Map<String, dynamic>>? _filteredRecords;
  bool _isLoading = false;
  bool _isDeleting = false; // New state variable for deletion status

  void _pickDate() async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _isLoading = true; // Show loading indicator
        _selectedDate = picked;
        _filteredRecords = null;
      });

      await Future.delayed(Duration(seconds: 1)); // Simulate a 1-second loading delay

      _filterRecordsByDate();
    }
  }

  void _filterRecordsByDate() {
    if (_selectedDate == null || widget.records == null) return;

    String formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate!);
    List<Map<String, dynamic>> allRecords = widget.records![formattedDate] ?? [];

    setState(() {
      _filteredRecords = allRecords;
      _isLoading = false; // Stop loading after filtering records
    });
  }

  void _confirmDeleteRecord(Map<String, dynamic> recordData) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Confirm Delete"),
          content: Text("Are you sure you want to delete this record?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context); // Close the dialog before starting the deletion
                setState(() {
                  _isDeleting = true; // Show loading indicator for deletion
                });
                await widget.deleteRecordCallback(recordData); // Use the callback
                setState(() {
                  _filteredRecords?.remove(recordData);
                  if (_filteredRecords?.isEmpty ?? true) {
                    _filteredRecords = null; // Set to null if no records left
                  }
                  _isDeleting = false; // Hide loading indicator after deletion
                });
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Find by Date"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _selectedDate == null
                      ? 'Select a Date'
                      : DateFormat('d MMMM yyyy').format(_selectedDate!),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                ),
                ElevatedButton(
                  onPressed: _pickDate,
                  child: const Text('Pick Date'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRecords == null
                    ? const Center(child: Text('Select a date to view records'))
                    : _filteredRecords!.isEmpty
                        ? const Center(child: Text('No records found'))
                        : Expanded(
                            child: Stack(
                              children: [
                                ListView.builder(
                                  itemCount: _filteredRecords!.length,
                                  itemBuilder: (context, index) {
                                    var recordData = _filteredRecords![index];
                                    var record = recordData['record'];
                                    var partnerName = record['partner'] ?? 'Unknown';
                                    var type = record['t'] ?? record['typ'] ?? 'Unknown';

                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      elevation: 4,
                                      child: ListTile(
                                        title: Text("Partner: $partnerName", style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            if (type == 'sale') ...[
                                              // Profit (Sales) Records Section
                                              Text("Crop: ${record['c_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text("Vendor: ${record['v_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text("Total Bill: ₹${record['tb'] ?? '0'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text("Weight: ${record['w'] ?? '0'} kg/boxes/pcs", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text("Amount Paid: ₹${record['a_p'] ?? '0'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ] else if (type == 'exp') ...[
                                              // Expenditure Records Section
                                              Text("Crop: ${record['c_id'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text("Description: ${record['desc'] ?? 'Unknown'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                              Text("Amount Spent: ₹${record['amt'] ?? '0'}", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                            ],
                                          ],
                                        ),
                                        trailing: IconButton(
                                          icon: Icon(Icons.delete),
                                          onPressed: () {
                                            _confirmDeleteRecord(recordData);
                                          },
                                        ),
                                      ),
                                    );
                                  },
                                ),
                                if (_isDeleting)
                                  Container(
                                    color: Colors.black54,
                                    child: Center(
                                      child: CircularProgressIndicator(),
                                    ),
                                  ),
                              ],
                            ),
                          ),
          ],
        ),
      ),
    );
  }
}