import 'package:flutter/material.dart';
import 'package:firstly/profit_record.dart';
import 'package:firstly/expenditures_record.dart';

class RecordOptions extends StatelessWidget {
  final String partner; // Accept a single partner

  // Constructor with required partner field
  const RecordOptions({super.key, required this.partner});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/logo.png', 
              height: 50,
            ),
          ],
        ),
      ),
      body: Container(
        color: Colors.grey[200], 
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center, 
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProfitRecord(partner: partner), // Pass a single partner
                    ),
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.note_add, size: 80, color: Colors.black),
                    SizedBox(height: 10),
                    Text(
                      "Add Profits",
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 40),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ExpendituresRecord(partner: partner), // Pass a single partner
                    ),
                  );
                },
                child: Column(
                  children: [
                    Icon(Icons.receipt, size: 80, color: Colors.black),
                    SizedBox(height: 10),
                    Text(
                      "Add Expenditures",
                      style: TextStyle(
                        color: Colors.purple,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );  
  }
}
