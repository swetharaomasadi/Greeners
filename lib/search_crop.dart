import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchCropScreen extends StatefulWidget {
  @override
  _SearchCropScreenState createState() => _SearchCropScreenState();
}

class _SearchCropScreenState extends State<SearchCropScreen> {
  final TextEditingController _searchController = TextEditingController();
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic> partnerData = {};
  Map<String, dynamic> allDataMap = {}; // Local storage for all crop data
  bool isLoading = false; // Loading state
  List<String> cropNames = []; // List of crop names
  String? selectedCrop; // Track the selected crop
  DocumentSnapshot? lastDocument; // Track the last document fetched for pagination
  bool hasMoreData = true; // Track if there is more data to fetch
  final ScrollController _scrollController = ScrollController(); // Controller for detecting scroll events

  @override
  void initState() {
    super.initState();
    fetchCropNames();
    _scrollController.addListener(_scrollListener); // Add scroll listener
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // Remove scroll listener
    _scrollController.dispose(); // Dispose of the controller
    super.dispose();
  }

  Future<void> fetchCropNames() async {
    if (userId == null) {
      print("User not logged in");
      return;
    }

    if (!hasMoreData) {
      print("No more data to fetch");
      return;
    }

    setState(() {
      isLoading = true; // Start loading before fetching data
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    List<String> tempCropNames = [];

    Query query = firestore
        .collection('partners')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: userId!)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${userId!}\uf8ff")
        .orderBy(FieldPath.documentId, descending: false)
        .limit(10); // Limit the number of documents fetched

    if (lastDocument != null) {
      query = query.startAfterDocument(lastDocument!); // Start after the last document for pagination
    }

    QuerySnapshot userDocs = await query.get();

    if (userDocs.docs.isEmpty) {
      setState(() {
        hasMoreData = false; // No more data to fetch
        isLoading = false; // Stop loading after fetching data
      });
      return;
    }

    lastDocument = userDocs.docs.last; // Update the last document fetched

    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      Map<String, dynamic> profits = data['profits'] ?? {};

      profits.forEach((partner, partnerData) {
        Map<String, dynamic> crops = partnerData['crops'] ?? {};
        crops.forEach((cropName, cropData) {
          if (!tempCropNames.contains(cropName)) {
            tempCropNames.add(cropName);
          }

          if (!allDataMap.containsKey(cropName)) {
            allDataMap[cropName] = {};
          }

          allDataMap[cropName][partner] = {
            'total_kgs': cropData['tw'] ?? 0.0,
            'total_earnings': cropData['tear'] ?? 0.0,
            'total_expenditures': cropData['texp'] ?? 0.0,
            'total_profits': cropData['tp'] ?? 0.0,
          };
        });
      });
    }

    setState(() {
      cropNames.addAll(tempCropNames);
      isLoading = false; // Stop loading after fetching data
    });
  }

  void searchCrop(String cropName) async {
    if (userId == null) {
      print("User not logged in");
      return;
    }

    setState(() {
      isLoading = true; // Start loading before fetching data
      selectedCrop = cropName; // Update the selected crop
    });

    Map<String, dynamic> dataMap = {};

    // Fetch profits from local storage
    if (allDataMap.containsKey(cropName)) {
      allDataMap[cropName].forEach((partner, details) {
        if (!dataMap.containsKey(partner)) {
          dataMap[partner] = {
            'partner': partner,
            'total_kgs': 0.0,
            'total_earnings': 0.0,
            'total_expenditures': 0.0,
            'total_profits': 0.0,
          };
        }

        dataMap[partner]!['total_kgs'] += details['total_kgs'] ?? 0.0;
        dataMap[partner]!['total_earnings'] += details['total_earnings'] ?? 0.0;
        dataMap[partner]!['total_expenditures'] += details['total_expenditures'] ?? 0.0;
        dataMap[partner]!['total_profits'] += details['total_profits'] ?? 0.0;
      });
    }

    setState(() {
      partnerData = dataMap;
      isLoading = false; // Stop loading after fetching data
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isLoading) {
      fetchCropNames(); // Fetch more data when scrolled to the bottom
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Crop')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Crop Name',
              ),
              items: cropNames.map((cropName) {
                return DropdownMenuItem<String>(
                  value: cropName,
                  child: Text(cropName),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  searchCrop(value);
                }
              },
            ),
            SizedBox(height: 20),
            if (selectedCrop == null)
              Center(child: Text('No crop selected'))
            else if (isLoading) // Show loading indicator while fetching data
              Center(child: CircularProgressIndicator())
            else if (partnerData.isEmpty && !isLoading) // Show no data message when search completes
              Center(child: Text('No data available for this crop.'))
            else
              Expanded(
                child: ListView.builder(
                  controller: _scrollController, // Attach the scroll controller
                  itemCount: partnerData.length,
                  itemBuilder: (context, index) {
                    String partner = partnerData.keys.elementAt(index);
                    var details = partnerData[partner]!;
                    return Card(
                      elevation: 3,
                      margin: EdgeInsets.symmetric(vertical: 8),
                      child: ListTile(
                        title: Text('Partner: ${details['partner']}'),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Total Weight/ Pieces: ${details['total_kgs']}'),
                            Text('Total Earnings: ₹${details['total_earnings']}'),
                            Text('Total Expenditures: ₹${details['total_expenditures']}'),
                            Text(
                              'Profit: ₹${details['total_profits']}',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: details['total_profits'] >= 0 ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}