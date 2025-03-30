import 'package:flutter/material.dart';
import 'home.dart';
import 'search_date.dart';
import 'search_partners.dart';
import 'search_crop.dart';
import 'settings.dart';
import 'add.dart';
import 'recent_records_page.dart';
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  _SearchViewScreenState createState() => _SearchViewScreenState();
}

class _SearchViewScreenState extends State<SearchScreen> {
  int _selectedIndex = 1;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => HomeScreen()),
        );
        break;
      case 1:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SearchScreen()),
        );
        break;
      case 2:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => AddPage()),
        );
        break;
      case 3:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => RecentRecordsPage()),
        );
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
    }
  }

  void _onSearchTap(String type) {
    Widget page;
    switch (type) {
      case "date":
        page = SearchByDatePage();
        break;
      case "partners":
        page = SearchPartnerScreen();
        break;
      case "crop":
        page = SearchCropScreen();
        break;
      default:
        return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Search Page',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color.fromARGB(255, 234, 82, 173),
        centerTitle: true,
      ),
      body: Column(
        children: [
          
          const SizedBox(height: 20),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOption(
                      icon: Icons.calendar_today,
                      label: "Date",
                      iconSize: 50,
                      iconColor: Colors.green,
                      labelColor: Colors.green,
                      onTap: () => _onSearchTap("date"),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildOption(
                      icon: Icons.agriculture,
                      label: "Crop",
                      iconSize: 50,
                      iconColor: Colors.orange,
                      labelColor: Colors.orange,
                      onTap: () => _onSearchTap("crop"),
                    ),
                    const SizedBox(width: 40),
                    _buildOption(
                      icon: Icons.group,
                      label: "Partners",
                      iconSize: 50,
                      iconColor: Colors.purple,
                      labelColor: Colors.purple,
                      onTap: () => _onSearchTap("partners"),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(
              icon: Icon(Icons.search, size: 30, color: Colors.blue), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add, size: 30), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time, size: 30), label: 'Recent'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildOption({
    required IconData icon,
    required String label,
    required Function() onTap,
    double iconSize = 30,
    Color iconColor = Colors.black,
    Color labelColor = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            height: 80,
            width: 80,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(40),
            ),
            child: Icon(
              icon,
              size: iconSize,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}
