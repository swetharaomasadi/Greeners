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
  double totalProfit = 0.0;
  List<String> partners = [];
  bool isFetchingPartners = true; // 🔹 Added to track loading state
  bool isLoading = false; // 🔹 For searching data

  @override
  void initState() {
    super.initState();
    fetchPartners();
  }

  Future<void> fetchPartners() async {
    if (userId == null) return;
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Set<String> partnerSet = {};

    for (String collection in ['records', 'expenditures']) {
      QuerySnapshot snapshot = await firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .get();

      for (var doc in snapshot.docs) {
        var partner = doc['partner'];
        if (partner != null) {
          partnerSet.add(partner.toString());
        }
      }
    }

    setState(() {
      partners = partnerSet.toList();
      isFetchingPartners = false; // 🔹 Stop loading after fetching partners
    });
  }

  void searchPartnerData(String partner) async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
      selectedPartner = partner;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<String, Map<String, dynamic>> dataMap = {};
    double totalProfitCalc = 0.0;

    for (String collection in ['records', 'expenditures']) {
      QuerySnapshot snapshot = await firestore
          .collection(collection)
          .where('user_id', isEqualTo: userId)
          .where('partner', isEqualTo: partner)
          .get();

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        String cropName = (data['item'] ?? data['crop_name'] ?? 'Unknown').toString();
        double amount = ((data['amount_paid'] ?? data['amount'] ?? 0) as num).toDouble();

        dataMap.putIfAbsent(cropName, () => {
          'crop_name': cropName,
          'total_earnings': 0.0,
          'total_expenditures': 0.0,
          'profit': 0.0,
        });

        if (collection == 'records') {
          dataMap[cropName]!['total_earnings'] += amount;
        } else {
          dataMap[cropName]!['total_expenditures'] += amount;
        }
      }
    }

    dataMap.forEach((crop, details) {
      details['profit'] = details['total_earnings'] - details['total_expenditures'];
      totalProfitCalc += details['profit'];
    });

    setState(() {
      partnerData = dataMap;
      totalProfit = totalProfitCalc;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Partner')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (isFetchingPartners) // 🔹 Show loading indicator while fetching partners
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
                child: Column(
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
