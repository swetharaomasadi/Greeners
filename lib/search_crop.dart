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
  bool isLoading = false; // 🔹 Added loading state

  void searchCrop(String cropName) async {
    if (userId == null) {
      print("User not logged in");
      return;
    }

    setState(() {
      isLoading = true; // 🔹 Start loading before fetching data
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Map<String, Map<String, dynamic>> dataMap = {};

    print("Fetching records for crop: $cropName");

    QuerySnapshot recordSnapshot = await firestore
        .collection('records')
        .where('user_id', isEqualTo: userId)
        .where('item', isEqualTo: cropName)
        .get();

    print("Fetched ${recordSnapshot.docs.length} records");

    for (var doc in recordSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      print("Record: $data");

      String partner = data['partner'] ?? "Unknown Partner";
      double kgs = (data['kgs'] ?? 0).toDouble();
      double amountPaid = (data['amount_paid'] ?? 0).toDouble();

      if (!dataMap.containsKey(partner)) {
        dataMap[partner] = {
          'partner': partner,
          'total_kgs': 0.0,
          'total_earnings': 0.0,
          'total_expenditures': 0.0,
        };
      }

      dataMap[partner]!['total_kgs'] += kgs;
      dataMap[partner]!['total_earnings'] += amountPaid;
    }

    QuerySnapshot expenditureSnapshot = await firestore
        .collection('expenditures')
        .where('user_id', isEqualTo: userId)
        .where('crop_name', isEqualTo: cropName)
        .get();

    print("Fetched ${expenditureSnapshot.docs.length} expenditures");

    for (var doc in expenditureSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      print("Expenditure: $data");

      String partner = data['partner'] ?? "Unknown Partner";
      double amount = (data['amount'] ?? 0).toDouble();

      if (!dataMap.containsKey(partner)) {
        dataMap[partner] = {
          'partner': partner,
          'total_kgs': 0.0,
          'total_earnings': 0.0,
          'total_expenditures': 0.0,
        };
      }

      dataMap[partner]!['total_expenditures'] += amount;
    }

    dataMap.forEach((partner, details) {
      details['profit'] = details['total_earnings'] - details['total_expenditures'];
    });

    print("Final Computed Data: $dataMap");

    setState(() {
      partnerData = dataMap;
      isLoading = false; // 🔹 Stop loading after fetching data
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Search Crop')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Enter Crop Name',
                suffixIcon: IconButton(
                  icon: Icon(Icons.search),
                  onPressed: () {
                    if (_searchController.text.isNotEmpty) {
                      searchCrop(_searchController.text.trim());
                    }
                  },
                ),
              ),
            ),
            SizedBox(height: 20),
            if (isLoading) // 🔹 Show loading indicator while fetching data
              Center(child: CircularProgressIndicator())
            else if (partnerData.isEmpty) // 🔹 Only show "No Data Found" after search completes
              Center(child: Text('No Data Found'))
            else
              Expanded(
                child: ListView.builder(
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
    );
  }
}
