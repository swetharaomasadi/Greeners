import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';
class EditDuesPage extends StatefulWidget {
  @override
  _EditDuesPageState createState() => _EditDuesPageState();
}

class _EditDuesPageState extends State<EditDuesPage> {
  final FlutterTts flutterTts = FlutterTts();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? user;
  String? selectedDueDocId;
  double? oldDue;
  double? oldAmountPaid;
  String? selectedVendorId;
  String? selectedCropId;
  double? selectedTotalBill;
  final TextEditingController _dueController = TextEditingController();
  bool isConfirmEnabled = false;
  bool _initialLoading = true;

  List<Map<String, dynamic>> filteredDuesData = [];
  bool isFiltered = false;

  // Pagination variables
  bool _isLoading = false;
  bool _hasMore = true; // This will be set to false after initial load if docs <= 3
  int _documentLimit = 10; // Default limit
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    listenToDues();
    _dueController.addListener(_validateInput);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && _lastDocument != null) {
        _fetchMoreDues();
      }
    });
  }

  void _validateInput() {
    double? enteredAmount = double.tryParse(_dueController.text.trim());
    if (enteredAmount != null && enteredAmount > 0 && enteredAmount <= (oldDue ?? 0)) {
      setState(() {
        isConfirmEnabled = true;
      });
    } else {
      setState(() {
        isConfirmEnabled = false;
      });
    }
  }

  Map<String, List<Map<String, dynamic>>> allDues = {};

  void listenToDues() {
    FirebaseFirestore.instance
        .collection('dues')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: user!.uid)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${user!.uid}\uf8ff")
        .limit(_documentLimit)
        .snapshots()
        .listen((snapshot) {
      Map<String, List<Map<String, dynamic>>> tempDuesData = {};

      for (var doc in snapshot.docs) {
        Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
        List<dynamic> duesList = data['d'] ?? [];

        tempDuesData[doc.id] = duesList.map((due) {
          due['docId'] = doc.id; // Ensure docId is correctly set
          return Map<String, dynamic>.from(due);
        }).where((due) => due['total_due'] > 0).toList(); // Filter dues with total_due > 0
      }

      setState(() {
        allDues = tempDuesData;
        _initialLoading = false;
        if (snapshot.docs.length < _documentLimit) {
          _hasMore = false; // No more documents to fetch
        } else {
          _lastDocument = snapshot.docs.last;
        }
      });
    });
  }

  Future<void> _fetchMoreDues() async {
    if (_isLoading || !_hasMore || _lastDocument == null) return; // Prevent further fetching if no more docs or _lastDocument is null

    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore.instance
        .collection('dues')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: user!.uid)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${user!.uid}\uf8ff")
        .startAfterDocument(_lastDocument!)
        .limit(_documentLimit)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        Map<String, List<Map<String, dynamic>>> tempDuesData = {};

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
          List<dynamic> duesList = data['d'] ?? [];

          tempDuesData[doc.id] = duesList.map((due) {
            due['docId'] = doc.id; // Ensure docId is correctly set
            return Map<String, dynamic>.from(due);
          }).where((due) => due['total_due'] > 0).toList(); // Filter dues with total_due > 0
        }

        setState(() {
          allDues.addAll(tempDuesData);
          if (snapshot.docs.length < _documentLimit) {
            _hasMore = false; // No more documents to fetch
          } else {
            _lastDocument = snapshot.docs.last;
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
      }
    }).catchError((error) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching more dues: $error")),
      );
    });
  }

  void updateLocalDue(String docId, String vendorId, String cropId, double totalBill, double newDue, double newAmountPaid) {
    if (!allDues.containsKey(docId)) return;

    setState(() {
      var duesList = allDues[docId]!;
      for (var due in duesList) {
        if (due['vendor_id'] == vendorId && due['crop_id'] == cropId && due['total_bill'] == totalBill) {
          double oldDue = due['total_due']?.toDouble() ?? 0.0;
          double newDueAmount = oldDue - newAmountPaid;

          if (newDueAmount <= 0) {
            duesList.remove(due); // Remove due from local list
            if (duesList.isEmpty) {
              allDues.remove(docId); // Remove the entire document if no dues left
            }
          } else {
            due['total_due'] = newDueAmount;
            due['amount_paid'] += newAmountPaid;
          }
          break;
        }
      }
    });

    // Update filtered data if necessary
    if (isFiltered) {
      setState(() {
        filteredDuesData = allDues.values.expand((list) => list).where((due) => due['vendor_id'] == selectedVendorId).toList();
      });
    }
  }

  Future<void> updateDueInFirestore(String docId, String vendorId, String cropId, double totalBill, double newDue, double newAmountPaid) async {
  if (docId.isEmpty || vendorId.isEmpty || cropId.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid document ID or fields")),
    );
    return;
  }

  try {
    WriteBatch batch = FirebaseFirestore.instance.batch();
    DocumentReference dueRef = FirebaseFirestore.instance.collection('dues').doc(docId);
    
    // Get the existing dues array
    DocumentSnapshot docSnapshot = await dueRef.get();
    List<dynamic> existingDues = docSnapshot['d'] ?? [];

    // Update the due entry in the array
    List<dynamic> updatedDues = existingDues.map((due) {
      if (due['vendor_id'] == vendorId && due['crop_id'] == cropId && due['total_bill'] == totalBill) {
        if (newDue <= 0) {
          return null; // Mark for removal
        } else {
          return {
            ...due,
            'total_due': newDue,
            'amount_paid': newAmountPaid,
          };
        }
      }
      return due;
    }).where((due) => due != null).toList();

    // Update the entire dues array
    if (updatedDues.isEmpty) {
      batch.delete(dueRef); // Delete the entire document if no dues left
    } else {
      batch.update(dueRef, {'d': updatedDues});
    }
    await batch.commit();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error updating due: $e")),
    );
  }
}

  Future<void> updateDueAmount() async {
  if (selectedDueDocId == null || oldDue == null || oldAmountPaid == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Invalid due data")),
    );
    return;
  }

  double? enteredAmount = double.tryParse(_dueController.text.trim());
  if (enteredAmount == null || enteredAmount <= 0 || enteredAmount > oldDue!) {
    return;
  }

  double newDue = oldDue! - enteredAmount;
  double newAmountPaid = oldAmountPaid! + enteredAmount;

  // Disable the button and show loading indicator
  setState(() {
    isConfirmEnabled = false; // Disable button
    _isSubmitting = true; // Set submitting to true
  });

  try {
    updateLocalDue(selectedDueDocId!, selectedVendorId!, selectedCropId!, selectedTotalBill!, newDue, enteredAmount);
    await updateDueInFirestore(selectedDueDocId!, selectedVendorId!, selectedCropId!, selectedTotalBill!, newDue, newAmountPaid);
    
    await flutterTts.speak("successful"); // ✅ Speak success

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Due updated successfully!")),
    );
  } catch (e) {
    await flutterTts.speak("failed"); // ❌ Speak failure

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error updating due: $e")),
    );
  }

  // Re-enable button and close the dialog
  setState(() {
    isConfirmEnabled = true;
    _isSubmitting = false;
  });

  _dueController.clear(); // Clear the text in the controller
  Navigator.of(context).pop(); // Close dialog
}


  void showDueDialog(String dueDocId, String vendorId, String vendorName, String cropId, double due, double amountPaid, double totalBill) {
  setState(() {
    selectedDueDocId = dueDocId;
    selectedVendorId = vendorId;
    selectedCropId = cropId;
    oldDue = due;
    oldAmountPaid = amountPaid;
    selectedTotalBill = totalBill;
    isConfirmEnabled = false; // Initially disable the button
  });

  showDialog(
    context: context,
    builder: (context) {
      return StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text("Update Due Amount", textAlign: TextAlign.center),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text("Due: ₹${oldDue?.toStringAsFixed(2) ?? '0.00'}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                Text("Amount Paid: ₹${oldAmountPaid?.toStringAsFixed(2) ?? '0.00'}", style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                TextField(
                  controller: _dueController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14),
                  decoration: InputDecoration(
                    hintText: "Enter amount",
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    double? enteredAmount = double.tryParse(value.trim());
                    setState(() {
                      isConfirmEnabled = enteredAmount != null && enteredAmount > 0 && enteredAmount <= (oldDue ?? 0);
                    });
                  },
                  enabled: !_isSubmitting, // Disable the text field when submitting
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // Close dialog
                },
                child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 15)),
              ),
              ElevatedButton(
                onPressed: isConfirmEnabled
                    ? () async {
                        setState(() {
                          isConfirmEnabled = false; // Disable button during processing
                        });

                        await updateDueAmount();

                        setState(() {
                          isConfirmEnabled = true; // Re-enable after completion
                        });
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isConfirmEnabled ? Colors.green : Colors.grey,
                ),
                child: isConfirmEnabled
                    ? Text("Confirm", style: TextStyle(fontSize: 15))
                    : CircularProgressIndicator(color: Colors.white), // Show loading
              ),
            ],
          );
        },
      );
    },
  );
}
  List<String> getUniqueVendors() {
    return allDues.values.expand((list) => list).map<String>((due) => due['vendor_id'] as String).toSet().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Dues",style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(255, 73, 98, 179),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showVendorSelectionDialog();
            },
          ),
        ],
      ),
      body: _initialLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  if (isFiltered)
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          filteredDuesData = allDues.values.expand((list) => list).toList();
                          isFiltered = false;
                        });
                      },
                      icon: const Icon(Icons.clear, color: Colors.white),
                      label: const Text("Show All Dues"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(height: 5),
                  if (allDues.isEmpty)
                    const Expanded(
                      child: Center(
                        child: Text(
                          "No dues found",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey),
                        ),
                      ),
                    ),
                  Expanded(
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: isFiltered
                          ? filteredDuesData.length
                          : allDues.values.expand((duesList) => duesList).length,
                      itemBuilder: (context, index) {
                        var due = isFiltered
                            ? filteredDuesData[index]
                            : allDues.values.expand((duesList) => duesList).elementAt(index);

                        return Card(
                          elevation: 4,
                          margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                            title: Text(
                              "${due['vendor_id'] ?? 'Unknown'}",
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              softWrap: true, // Allows text wrapping
                              maxLines: 3, // Limits to 3 lines before cutting off
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${due['crop_id'] ?? 'Unknown'}",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                                  softWrap: true, // Allows text wrapping
                                  maxLines: 3, // Limits to 3 lines before cutting off
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  "Due: ₹${due['total_due'] ?? 0}",
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.red),
                                ),
                              ],
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit, color: Colors.green, size: 30),
                              onPressed: () {
                                showDueDialog(
                                  due['docId'] ?? '',
                                  due['vendor_id'] ?? '',
                                  due['vendor_id'] ?? '',
                                  due['crop_id'] ?? '',
                                  double.tryParse(due['total_due']?.toString() ?? '0') ?? 0.0,
                                  double.tryParse(due['amount_paid']?.toString() ?? '0') ?? 0.0,
                                  double.tryParse(due['total_bill']?.toString() ?? '0') ?? 0.0,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  if (_isLoading)
                    const Center(
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
    );
  }

  void showVendorSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Select Vendor"),
          content: Container(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: getUniqueVendors().length,
                    itemBuilder: (context, index) {
                      String vendorId = getUniqueVendors()[index];
                      return ListTile(
                        title: Text(vendorId),
                        onTap: () {
                          setState(() {
                            isFiltered = true;
                            selectedVendorId = vendorId;
                            filteredDuesData = allDues.values.expand((list) => list).where((due) => due['vendor_id'] == vendorId).toList();
                          });
                          Navigator.of(context).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text("Cancel"),
            ),
          ],
        );
      },
    );
  }
}
