import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPartnerScreen extends StatefulWidget {
  @override
  _SearchPartnerScreenState createState() => _SearchPartnerScreenState();
}

class _SearchPartnerScreenState extends State<SearchPartnerScreen> {
  String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? selectedPartner;
  Map<String, dynamic> partnerData = {};
  Map<String, Map<String, dynamic>> allDataMap = {}; // Local storage for all partner data
  double totalProfit = 0.0;
  List<String> partners = ['No Gain Sharer']; // Include "No Gain Sharer"
  bool isFetchingPartners = true; // Track loading state
  bool isLoading = false; // For searching data
  DocumentSnapshot? lastDocument; // Track the last document fetched for pagination
  bool hasMoreData = true; // Track if there is more data to fetch
  final ScrollController _scrollController = ScrollController(); // Controller for detecting scroll events

  @override
  void initState() {
    super.initState();
    fetchPartners();
    _scrollController.addListener(_scrollListener); // Add scroll listener
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener); // Remove scroll listener
    _scrollController.dispose(); // Dispose of the controller
    super.dispose();
  }

  Future<void> fetchPartners() async {
    if (userId == null) return;

    if (!hasMoreData) {
      print("No more data to fetch");
      return;
    }

    setState(() {
      isFetchingPartners = true; // Start loading before fetching data
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;

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
        isFetchingPartners = false; // Stop loading after fetching data
      });
      return;
    }

    lastDocument = userDocs.docs.last; // Update the last document fetched

    List<String> fetchedPartners = [];
    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> partnersList = data['partners'] ?? [];
      for (var partner in partnersList) {
        if (partner is String && !fetchedPartners.contains(partner)) {
          fetchedPartners.add(partner);
        }
      }

      Map<String, dynamic> profits = data['profits'] ?? {};
      profits.forEach((partner, value) {
        if (value is Map<String, dynamic>) {
          Map<String, dynamic> partnerProfits = value['crops'] ?? {};
          partnerProfits.forEach((cropName, cropData) {
            allDataMap.putIfAbsent(partner, () => {});
            allDataMap[partner]!.putIfAbsent(cropName, () => {
              'crop_name': cropName,
              'total_earnings': 0.0,
              'total_expenditures': 0.0,
              'total_weight': 0.0,
              'profit': 0.0,
            });

            allDataMap[partner]![cropName]!['total_earnings'] += cropData['tear'] ?? 0.0;
            allDataMap[partner]![cropName]!['total_expenditures'] += cropData['texp'] ?? 0.0;
            allDataMap[partner]![cropName]!['total_weight'] += cropData['tw'] ?? 0.0;
            allDataMap[partner]![cropName]!['profit'] += cropData['tp'] ?? 0.0;
          });
        }
      });
    }

    setState(() {
      partners.addAll(fetchedPartners);
      isFetchingPartners = false; // Stop loading after fetching partners
    });
  }

  void searchPartnerData(String partner) async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
      selectedPartner = partner;
    });

    await Future.delayed(Duration(milliseconds: 300)); // Allow UI to update

    double totalProfitCalc = 0.0;
    Map<String, dynamic> dataMap = {};

    if (allDataMap.containsKey(partner)) {
      allDataMap[partner]!.forEach((cropName, details) {
        dataMap.putIfAbsent(cropName, () => details);
        totalProfitCalc += details['profit'] ?? 0.0;
      });
    }

    setState(() {
      partnerData = dataMap;
      totalProfit = totalProfitCalc;
      isLoading = false;
    });
  }

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent && !isFetchingPartners) {
      fetchPartners(); // Fetch more data when scrolled to the bottom
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Partner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isFetchingPartners) // Show loading indicator while fetching partners
              Center(child: CircularProgressIndicator())
            else if (partners.isEmpty)
              Center(child: Text("No partners found."))
            else
              DropdownButton<String>(
                value: selectedPartner,
                hint: Text('Select Partner'),
                isExpanded: true,
                items: partners.map((partner) {
                  return DropdownMenuItem(
                    value: partner,
                    child: Text(partner),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    searchPartnerData(value);
                  }
                },
              ),
            SizedBox(height: 20),
            if (isLoading) CircularProgressIndicator(),
            if (selectedPartner != null && !isLoading)
              Expanded(
                child: partnerData.isEmpty && !isLoading
                  ? Center(child: Text("No data available for this partner."))
                  : Column(
                      children: [
                        Card(
                          color: Colors.blue,
                          child: Padding(
                            padding: EdgeInsets.all(12),
                            child: Text(
                              'Total Profit: ₹${totalProfit.toStringAsFixed(2)} ${totalProfit >= 0 ? '💐' : '⚠'}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController, // Attach the scroll controller
                            itemCount: partnerData.length,
                            itemBuilder: (context, index) {
                              String cropName = partnerData.keys.elementAt(index);
                              var details = partnerData[cropName]!;
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                child: ListTile(
                                  title: Text('${details['crop_name']}'),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('Total Weight: ${details['total_weight']} kg'),
                                      Text('Total Earnings: ₹${details['total_earnings']}'),
                                      Text('Total Expenditures: ₹${details['total_expenditures']}'),
                                      Text(
                                        'Profit: ₹${details['profit']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: details['profit'] >= 0 ? Colors.green : Colors.red,
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
          ],
        ),
      ),
    );
  }
}