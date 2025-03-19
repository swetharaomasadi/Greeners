import 'package:flutter/material.dart';
import 'search_partners.dart'; // Import the SearchPartnerScreen

class ProfitTillTodayPage extends StatelessWidget {
  const ProfitTillTodayPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Directly navigate to SearchPartnerScreen when the page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => SearchPartnerScreen()),
      );
    });

    // Return an empty container as the navigation will happen automatically
    return Container();
  }
}