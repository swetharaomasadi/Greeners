import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProfitTillTodayPage extends StatefulWidget {
  const ProfitTillTodayPage({super.key});

  @override
  _ProfitTillTodayPageState createState() => _ProfitTillTodayPageState();
}

class _ProfitTillTodayPageState extends State<ProfitTillTodayPage> {
  double salesRevenue = 0.0;
  double costOfGoodsSold = 0.0;
  double netProfit = 0.0;

  // Function to fetch the precomputed profit data for the current user
  Future<void> fetchProfitData() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print("User is not logged in.");
        return;
      }

      final userId = currentUser.uid;

      // Fetch profit summary document instead of all records
      final profitDoc = await FirebaseFirestore.instance
          .collection('profit_summary')
          .doc(userId)
          .get();

      if (profitDoc.exists) {
        final data = profitDoc.data();
        setState(() {
          salesRevenue = data?['total_sales'] ?? 0.0;
          costOfGoodsSold = data?['total_expenditures'] ?? 0.0;
          netProfit = salesRevenue - costOfGoodsSold;
        });
      } else {
        print("No profit summary found for this user.");
      }
    } catch (e) {
      print("Error fetching profit data: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    fetchProfitData(); // Fetch data when the page loads
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profit Till Today'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Total Profit Till Today',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '₹${netProfit.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: netProfit < 0 ? Colors.red : Colors.green,
              ),
            ),
            SizedBox(height: 40),
            Card(
              elevation: 5,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    Text(
                      'Profit Breakdown:',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    SizedBox(height: 10),
                    _buildProfitRow('Total Sales', salesRevenue),
                    _buildProfitRow('Total Expenditure', costOfGoodsSold),
                    SizedBox(height: 20),
                    Divider(color: Colors.black),
                    _buildProfitRow('Net Profit', netProfit),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                fetchProfitData(); // Re-fetch the data when the button is pressed
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text('Profit data refreshed'),
                  backgroundColor: Colors.blue,
                ));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                textStyle: TextStyle(fontSize: 18),
              ),
              child: Text('Refresh Profit Data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfitRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '₹${amount.toStringAsFixed(2)}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: amount < 0 ? Colors.red : Colors.green,
          ),
        ),
      ],
    );
  }
}
