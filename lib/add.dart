import 'package:flutter/material.dart';
import 'home.dart';
import 'search.dart';
import 'settings.dart';
import 'record_options.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  int _selectedIndex = 2;
  List<String> partners = [];

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
          MaterialPageRoute(builder: (context) => SearchViewScreen()),
        );
        break;
      case 2:
        break;
      case 4:
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => SettingsPage()),
        );
        break;
    }
  }

  void _addPartner() async {
    final String? partnerName = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        TextEditingController controller = TextEditingController();
        return AlertDialog(
          title: Text("Enter Partner's Name"),
          content: TextField(
            controller: controller,
            decoration: InputDecoration(hintText: 'Partner name'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(controller.text);
              },
              child: Text('Add'),
            ),
          ],
        );
      },
    );

    if (partnerName != null && partnerName.isNotEmpty) {
      setState(() {
        partners.add(partnerName);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.person, color: Colors.black),
          onPressed: () {},
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', height: 60),
          ],
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title with lock symbol and different font
              Column(
                children: [
                  Text(
                    "Share Profit with",
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: const Color.fromARGB(255, 250, 163, 42),
                      fontFamily: 'RobotoMono', // Different font for styling
                    ),
                  ),
                  SizedBox(height: 8),
                  Icon(Icons.lock, color: Colors.purple, size: 30), // Lock icon
                  SizedBox(height: 8), // Space between lock and text
                  Text(
                    "only with me",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
                      fontFamily: 'RobotoMono', // Different font for styling
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),

              // Display partners only when the list is not empty
              if (partners.isNotEmpty)
                ...partners
                    .map(
                      (partner) => Container(
                        margin: EdgeInsets.symmetric(vertical: 10),
                        padding:
                            EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          partner,
                          style: TextStyle(fontSize: 18, color: Colors.black),
                        ),
                      ),
                    )
                    ,

              // Add Partner Button
              GestureDetector(
                onTap: _addPartner,
                child: CircleAvatar(
                  radius: 35,
                  backgroundColor: Colors.grey[200],
                  child: Icon(Icons.add, size: 40, color: Colors.blue),
                ),
              ),
              SizedBox(height: 30),

              // Submit Button
             // In the _AddPageState class

  // Submit Button on pressed
  ElevatedButton(
    onPressed: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => RecordOptions(partners: partners), // Pass partners here
        ),
      );
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: EdgeInsets.symmetric(horizontal: 60, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
    ),
    child: Text(
      "SUBMIT",
      style: TextStyle(fontSize: 18, color: Colors.white),
    ),
  ),

            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.black,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.home, size: 40),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.search, size: 40),
            label: 'Search',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.add, size: 40, color: Colors.blue),
            label: 'Add',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time, size: 40),
            label: 'Recent',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings, size: 40),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
