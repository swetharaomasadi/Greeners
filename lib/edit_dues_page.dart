import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditDuesPage extends StatefulWidget {
  @override
  _EditDuesPageState createState() => _EditDuesPageState();
}

class _EditDuesPageState extends State<EditDuesPage> {
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

  List<Map<String, dynamic>> filteredDuesData = [];
  bool isFiltered = false;

  // Pagination variables
  bool _isLoading = false;
  bool _hasMore = true;
  int _documentLimit = 10;
  DocumentSnapshot? _lastDocument;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    user = _auth.currentUser;
    listenToDues();
    _dueController.addListener(_validateInput);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        if (isFiltered) {
          _fetchMoreFilteredDues();
        } else {
          _fetchMoreDues();
        }
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
        .orderBy(FieldPath.documentId, descending: true)
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
        }).toList();
      }

      setState(() {
        allDues = tempDuesData;
        if (snapshot.docs.length < _documentLimit) {
          _hasMore = false;
        } else {
          _lastDocument = snapshot.docs.last;
        }
      });
    });
  }

  Future<void> _fetchMoreDues() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore.instance
        .collection('dues')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: user!.uid)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${user!.uid}\uf8ff")
        .orderBy(FieldPath.documentId, descending: true)
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
          }).toList();
        }

        setState(() {
          allDues.addAll(tempDuesData);
          if (snapshot.docs.length < _documentLimit) {
            _hasMore = false;
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

  Future<void> _fetchMoreFilteredDues() async {
    if (_isLoading || !_hasMore) return;

    setState(() {
      _isLoading = true;
    });

    FirebaseFirestore.instance
        .collection('dues')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: user!.uid)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${user!.uid}\uf8ff")
        .orderBy(FieldPath.documentId, descending: true)
        .startAfterDocument(_lastDocument!)
        .limit(_documentLimit)
        .get()
        .then((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        List<Map<String, dynamic>> tempFilteredDuesData = [];

        for (var doc in snapshot.docs) {
          Map<String, dynamic> data = Map<String, dynamic>.from(doc.data());
          List<dynamic> duesList = data['d'] ?? [];

          duesList.forEach((due) {
            if (due['vendor_id'] == selectedVendorId) {
              due['docId'] = doc.id; // Ensure docId is correctly set
              tempFilteredDuesData.add(Map<String, dynamic>.from(due));
            }
          });
        }

        setState(() {
          filteredDuesData.addAll(tempFilteredDuesData);
          if (snapshot.docs.length < _documentLimit) {
            _hasMore = false;
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
          double oldDue = due['total_due'];
          double newDueAmount = oldDue - newAmountPaid;

          if (newDueAmount <= 0) {
            due['total_due'] = 0; // Set total_due to 0 instead of removing
          } else {
            due['total_due'] = newDueAmount;
            due['amount_paid'] += newAmountPaid;
          }
          break;
        }
      }
    });
  }

  Future<void> updateDueInFirestore(String docId, String vendorId, String cropId, double totalBill, double newDue, double newAmountPaid) async {
    if (docId.isEmpty || vendorId.isEmpty || cropId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Invalid document ID or fields")),
      );
      return;
    }

    try {
      DocumentReference dueRef = FirebaseFirestore.instance.collection('dues').doc(docId);
      
      // Get the existing dues array
      DocumentSnapshot docSnapshot = await dueRef.get();
      List<dynamic> existingDues = docSnapshot['d'] ?? [];

      // Update the due entry in the array
      List<dynamic> updatedDues = existingDues.map((due) {
        if (due['vendor_id'] == vendorId && due['crop_id'] == cropId && due['total_bill'] == totalBill) {
          return {
            ...due,
            'total_due': newDue,
            'amount_paid': newAmountPaid,
          };
        }
        return due;
      }).toList();

      // Update the entire dues array
      await dueRef.update({'d': updatedDues});
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

    updateLocalDue(selectedDueDocId!, selectedVendorId!, selectedCropId!, selectedTotalBill!, newDue, enteredAmount);
    await updateDueInFirestore(selectedDueDocId!, selectedVendorId!, selectedCropId!, selectedTotalBill!, newDue, newAmountPaid);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Due updated successfully!")),
    );

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
      isConfirmEnabled = false;
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
                  Text("Current Due: ₹${oldDue?.toStringAsFixed(2) ?? '0.00'}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  Text("Amount Paid: ₹${oldAmountPaid?.toStringAsFixed(2) ?? '0.00'}", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 10),
                  TextField(
                    controller: _dueController,
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18),
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
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Close dialog
                  },
                  child: Text("Cancel", style: TextStyle(color: Colors.red, fontSize: 16)),
                ),
                ElevatedButton(
                  onPressed: isConfirmEnabled ? updateDueAmount : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isConfirmEnabled ? Colors.green : Colors.grey,
                  ),
                  child: Text("Confirm", style: TextStyle(fontSize: 16)),
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
        title: Text("Edit Dues"),
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showVendorSelectionDialog();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (isFiltered)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    filteredDuesData = allDues.values.expand((list) => list).toList();
                    isFiltered = false;
                  });
                },
                child: Text("Show All Dues"),
              ),
            ),
          if (allDues.isEmpty)
            Center(child: Text("No dues found")),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: isFiltered ? filteredDuesData.length + (_isLoading ? 1 : 0) : allDues.values.expand((duesList) => duesList).length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (isFiltered && index == filteredDuesData.length) {
                  return Center(child: CircularProgressIndicator());
                } else if (!isFiltered && index == allDues.values.expand((duesList) => duesList).length) {
                  return Center(child: CircularProgressIndicator());
                }
                var due = isFiltered ? filteredDuesData[index] : allDues.values.expand((duesList) => duesList).elementAt(index);
                return ListTile(
                  title: Text("Vendor: ${due['vendor_id'] ?? 'Unknown'}"),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Crop ID: ${due['crop_id'] ?? 'Unknown'}"),
                      Text("Due: ₹${due['total_due'] ?? 0}"),
                    ],
                  ),
                  trailing: Icon(Icons.edit, color: Colors.green),
                  onTap: () {
                    showDueDialog(due['docId'] ?? '', due['vendor_id'] ?? '', due['vendor_id'] ?? '', due['crop_id'] ?? '', due['total_due'] ?? 0, due['amount_paid'] ?? 0, due['total_bill'] ?? 0);
                  },
                );
              },
            ),
          ),
        ],
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
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: getUniqueVendors().length,
              itemBuilder: (context, index) {
                String vendorId = getUniqueVendors()[index];
                return ListTile(
                  title: Text(vendorId),
                  onTap: () {
                    setState(() {
                      selectedVendorId = vendorId;
                      filteredDuesData = allDues.values.expand((list) => list).where((due) => due['vendor_id'] == vendorId).toList();
                      isFiltered = true;
                    });
                    Navigator.of(context).pop();
                  },
                );
              },
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