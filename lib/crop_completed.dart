import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_tts/flutter_tts.dart';

class CompleteCrop extends StatefulWidget {
  const CompleteCrop({super.key});

  @override
  _CompleteCropState createState() => _CompleteCropState();
}

class _CompleteCropState extends State<CompleteCrop> {
  final FlutterTts flutterTts = FlutterTts();

  List<String> partnerNames = [];
  List<String> cropNames = [];
  String? selectedPartner;
  String? selectedCrop;
  bool isLoading = false;
  bool isCropsLoading = false; // New flag for loading crops

  @override
  void initState() {
    super.initState();
    fetchData(); // Fetch partner names when the page loads
  }

  Future<void> fetchData() async {
    setState(() {
      isLoading = true;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      // Fetch the first document for the user
      DocumentSnapshot userDoc = await firestore.collection('partners').doc(user.uid).get();
      if (userDoc.exists) {
        Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;
        if (userData != null && userData['partners'] != null) {
          List<String> partners = [];
          for (String partner in userData['partners']) {
            if (userData['profits'][partner]['tp'] != 0) {
              partners.add(partner);
            }
          }
          // Add "No Gain Sharer" explicitly to the partners list
          partners.add("No Gain Sharer");
          setState(() {
            partnerNames = partners;
          });
        }
      }
    } catch (e) {
      print("Error fetching partners: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching partners: $e")),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> fetchCropsForPartner(String partner, StateSetter dialogSetState) async {
    dialogSetState(() {
      isCropsLoading = true;
    });

    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;
      User? user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      List<String> crops = [];
      bool partnerFound = false;

      QuerySnapshot userDocs = await firestore.collection('partners')
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: user.uid)
          .where(FieldPath.documentId, isLessThanOrEqualTo: "${user.uid}\uf8ff")
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      for (var doc in userDocs.docs) {
        Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;
        if (data != null && data['profits'] != null) {
          Map<String, dynamic> profits = data['profits'];
          if (profits.containsKey(partner)) {
            Map<String, dynamic> partnerData = profits[partner];
            Map<String, dynamic> cropsData = partnerData['crops'];

            crops.addAll(
              cropsData.keys.where((crop) {
                return cropsData[crop]['tp'] != 0;
              }),
            );
            partnerFound = true;
            break;
          }
        }
      }

      dialogSetState(() {
        cropNames = crops;
        selectedCrop = null;
      });

      if (crops.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("No crops found for the selected partner.")),
        );
      }
    } catch (e) {
      print("Error fetching crops: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching crops: $e")),
      );
    } finally {
      dialogSetState(() {
        isCropsLoading = false;
      });
    }
  }

  Future<void> completeCrop() async {
    setState(() {
      isLoading = true;
    });

    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (selectedPartner == null || selectedCrop == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please select a partner and crop before proceeding!")),
      );
      setState(() {
        isLoading = false;
      });
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    WriteBatch batch = firestore.batch();

    DocumentReference partnerDocRef = firestore.collection('partners').doc(user.uid);
    DocumentSnapshot partnerDoc = await partnerDocRef.get();

    if (partnerDoc.exists) {
      Map<String, dynamic>? partnerData = partnerDoc.data() as Map<String, dynamic>?;
      if (partnerData != null) {
        Map<String, dynamic> cropData = partnerData['profits'][selectedPartner]['crops'][selectedCrop];

        // Get the current values of tp, texp, tear, and tw
        int cropTp = cropData['tp'];
        int cropTexp = cropData['texp'];
        int cropTear = cropData['tear'];
        int cropTw = cropData['tw'];

        // Update the partner's total profit, total expenditures, and total earnings by decrementing the values from the selected crop
        batch.update(partnerDocRef, {
          'profits.$selectedPartner.tp': FieldValue.increment(-cropTp),
          'profits.$selectedPartner.texp': FieldValue.increment(-cropTexp),
          'profits.$selectedPartner.tear': FieldValue.increment(-cropTear),
          'profits.$selectedPartner.crops.$selectedCrop.tp': 0,
          'profits.$selectedPartner.crops.$selectedCrop.texp': 0,
          'profits.$selectedPartner.crops.$selectedCrop.tear': 0,
          'profits.$selectedPartner.crops.$selectedCrop.tw': 0,
        });

        // Store the crop data in the old_data collection
        DocumentReference oldDataDocRef = firestore.collection('old_data').doc(user.uid);
        DocumentSnapshot oldDataDoc = await oldDataDocRef.get();
        Map<String, dynamic> oldDataEntry = {
          'partner': selectedPartner,
          'crop': selectedCrop,
          'tp': cropTp,
          'texp': cropTexp,
          'tear': cropTear,
          'tw': cropTw,
          'deleted_at': Timestamp.now(),
        };

        if (oldDataDoc.exists) {
          batch.update(oldDataDocRef, {
            'data': FieldValue.arrayUnion([oldDataEntry]),
          });
        } else {
          batch.set(oldDataDocRef, {
            'data': [oldDataEntry],
          });
        }

        // Query only the logged-in user's documents
        QuerySnapshot userDocs = await firestore.collection('records')
            .where(FieldPath.documentId, isGreaterThanOrEqualTo: user.uid)
            .where(FieldPath.documentId, isLessThanOrEqualTo: "${user.uid}\uf8ff")
            .orderBy(FieldPath.documentId, descending: true)
            .get();

        List<DocumentReference> docsToUpdate = [];
        List<Map<String, dynamic>> updatedRecordsList = [];

        for (var doc in userDocs.docs) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          if (data.containsKey('r')) {
            List<dynamic> records = List.from(data['r']);

            // Remove only records that match the selected partner & crop
            List<dynamic> updatedRecords = records.where((record) {
              return !(record['partner'] == selectedPartner && record['c_id'] == selectedCrop);
            }).toList();

            // If changes were made, collect the document reference and updated records
            if (updatedRecords.length != records.length) {
              docsToUpdate.add(doc.reference);
              updatedRecordsList.add({'r': updatedRecords});
            }
          }
        }

        // Batch update collected documents
        for (int i = 0; i < docsToUpdate.length; i++) {
          batch.update(docsToUpdate[i], updatedRecordsList[i]);
        }

        try {
          await batch.commit(); // Execute batch updates
          await flutterTts.speak("successfully Crop completed.");  // ✅ Speak success
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Crop completed and records deleted successfully!")),
          );

          // Reset the selections and UI after confirmation
          setState(() {
            selectedPartner = null;
            selectedCrop = null;
            cropNames = [];
            isLoading = false;
          });
        } catch (e) {
        await flutterTts.speak("failed completion.");  // ❌ Speak failure
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error removing records: $e")),
          );
          setState(() {
            isLoading = false;
          });
        }
      }
    }
  }

  void showSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AlertDialog(
              title: Text("Select Partner and Crop"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (partnerNames.isEmpty)
                    Text("No data available"),
                  if (partnerNames.isNotEmpty)
                    DropdownButton<String>(
                      value: selectedPartner,
                      hint: Text("Select Partner"),
                      isExpanded: true,
                      items: partnerNames.map((partner) {
                        return DropdownMenuItem(value: partner, child: Text(partner));
                      }).toList(),
                      onChanged: (value) {
                        print("Selected partner: $value"); // Debugging statement
                        setState(() {
                          selectedPartner = value;
                          selectedCrop = null; // Reset selected crop when partner is changed
                          cropNames = []; // Clear crop names while fetching new crops
                        });
                        fetchCropsForPartner(value!, setState); // Fetch crops for the selected partner
                      },
                    ),
                  SizedBox(height: 10),
                  if (isCropsLoading)
                    CircularProgressIndicator(),
                  if (!isCropsLoading && cropNames.isEmpty && selectedPartner != null)
                    Text("No crops found for the selected partner."),
                  if (!isCropsLoading && cropNames.isNotEmpty)
                    DropdownButton<String>(
                      value: selectedCrop,
                      hint: Text("Select Crop"),
                      isExpanded: true,
                      items: cropNames.map((crop) {
                        return DropdownMenuItem(value: crop, child: Text(crop));
                      }).toList(),
                      onChanged: selectedPartner != null ? (value) {
                        print("Selected crop: $value"); // Debugging statement
                        setState(() {
                          selectedCrop = value;
                        });
                      } : null, // Disable crop dropdown if partner is not selected
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: (selectedPartner != null && selectedCrop != null)
                      ? () {
                          Navigator.pop(context);
                          completeCrop();
                        }
                      : null, // Disable button if selections are not made
                  child: Text("Confirm"),
                ),
              ],
            );
          }
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Complete Crop",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.green,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(Icons.warning, size: 30, color: Colors.red),
              SizedBox(height: 10),
              Text(
                "Important Update!",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              SizedBox(height: 10),
              Text(
                "The profit of the selected crop under the selected partner will reset to 0.\n"
                "The records under the selected partner and crop will be completely deleted.\n"
                "You can view the profit of old crops under 'Older Crops' in Settings.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: isLoading ? null : showSelectionDialog,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  backgroundColor: const Color.fromARGB(255, 17, 209, 11),
                  textStyle: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
                child: Text("Confirm & Complete"),
              ),
              if (isLoading) Padding(
                padding: const EdgeInsets.only(top: 20),
                child: CircularProgressIndicator(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}