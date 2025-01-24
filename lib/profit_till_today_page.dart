import 'package:flutter/material.dart';

class ProfitTillTodayPage extends StatelessWidget {
  // This function will calculate or fetch the profit till today.
  // For now, we are assuming a static value for demonstration.
  double getProfit() {
    // Replace this with your logic to calculate profit
    return 1500.75; // Example profit till today
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
            // Title
            Text(
              'Total Profit Till Today',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 20),

            // Display Profit
            Text(
              '\$${getProfit().toStringAsFixed(2)}', // Display the profit with 2 decimal places
              style: TextStyle(
                fontSize: 40,
                fontWeight: FontWeight.bold,
                color: Colors.green,
              ),
            ),
            SizedBox(height: 40),

            // Profit Breakdown (Optional)
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
                    _buildProfitRow('Sales Revenue', 3000.00),
                    _buildProfitRow('Cost of Goods Sold', -1200.00),
                    _buildProfitRow('Expenses', -300.00),
                    _buildProfitRow('Other Income', 200.00),
                    SizedBox(height: 20),
                    Divider(color: Colors.black),
                    _buildProfitRow('Net Profit', getProfit()),
                  ],
                ),
              ),
            ),
            SizedBox(height: 30),

            // Reload Button (Optional)
            ElevatedButton(
              onPressed: () {
                // Implement the logic to reload or refresh profit data here.
                // For example, you could call setState or make a network call to fetch live data.
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

  // Helper widget to display individual profit breakdown rows
  Widget _buildProfitRow(String label, double amount) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
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
