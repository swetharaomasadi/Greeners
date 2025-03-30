import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'record_options.dart';
import 'home.dart';
import 'search.dart';
import 'settings.dart';
import 'recent_records_page.dart';
import 'package:flutter_tts/flutter_tts.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  final FlutterTts flutterTts = FlutterTts();
  List<String> partners = ["No Gain Sharer"]; // Default partner
  String? _errorMessage;
  String? _longPressedPartner; // Separate variable for long-pressed name
  int _selectedIndex = 2; // Default Add tab index

  @override
  void initState() {
    super.initState();
    _loadPartners();
  }

  Future<void> _loadPartners() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    DocumentSnapshot snapshot = await FirebaseFirestore.instance
        .collection('partners')
        .doc(user.uid)
        .get();

    if (snapshot.exists) {
      List<dynamic> partnerList = snapshot.get('partners') ?? [];
      setState(() {
        partners = ["No Gain Sharer"];
        partners.addAll(partnerList.cast<String>());
      });
    }
  }

  void _addPartner() async {
    setState(() {
      _errorMessage = null; // Clear error message immediately
    });

    await Future.delayed(Duration(milliseconds: 10)); // Allow UI update before dialog opens

    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
      bool alreadyExists = partners.contains(partnerName);

      if (alreadyExists) {
        setState(() {
          _errorMessage = 'You have already added this partner.';
        });
        await flutterTts.speak("You have already added this partner.");
        return;
      } else {
        DocumentReference partnerDocRef =
            FirebaseFirestore.instance.collection('partners').doc(user.uid);

        DocumentSnapshot partnerDocSnapshot = await partnerDocRef.get();
        if (!partnerDocSnapshot.exists) {
          await partnerDocRef.set({
            'u_id': user.uid,
            'created_at': FieldValue.serverTimestamp(),
            'partners': []
          });
        }

        await partnerDocRef.update({
          'partners': FieldValue.arrayUnion([partnerName])
        });

        setState(() {
          partners.add(partnerName);
          _errorMessage = null;
        });
      }
    }
  }

  void _navigateToNextPage(String partnerName) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RecordOptions(partner: partnerName),
      ),
    );
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });

    switch (index) {
      case 0:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen()));
        break;
      case 1:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchScreen()));
        break;
      case 2:
        break;
      case 3:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => RecentRecordsPage()));
        break;
      case 4:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SettingsPage()));
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Add Page",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 17, 211, 10),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            child: Text(
              "Add your partner by clicking the '+' sign. If already added, click the partner's name to enter data for shared profit.",
              style: TextStyle(fontSize: 15, color: Color.fromARGB(255, 51, 100, 248)),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(height: 5),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                _errorMessage!,
                style: TextStyle(color: Colors.red),
              ),
            ),
          SizedBox(height: 10),

          // Show scroll hint before list
          if (partners.length > 5)
            Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.arrow_downward, size: 18, color: Colors.grey),
                  SizedBox(width: 5),
                  Text("Scroll down for more", style: TextStyle(color: Colors.grey, fontSize: 12)),
                ],
              ),
            ),

          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: partners.map((partner) {
                  return Stack(
                    alignment: Alignment.center, // Align tooltip text over button
                    children: [
                      GestureDetector(
                        onLongPressStart: (_) {
                          setState(() {
                            _longPressedPartner = partner; // Show full name while pressing
                          });
                        },
                        onLongPressEnd: (_) {
                          setState(() {
                            _longPressedPartner = null; // Hide name when released
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                          child: ElevatedButton(
                            onPressed: () => _navigateToNextPage(partner),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              minimumSize: Size(double.infinity, 50),
                            ),
                            child: Text(
                              partner,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),

                      // Show full name as overlay when long-pressed
                      if (_longPressedPartner == partner)
                        Positioned(
                          top: -25, // Adjust position above the button
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.black87,
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              _longPressedPartner!,
                              style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                    ],
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
      
      // Keep FAB outside body to prevent scrolling
      floatingActionButton: FloatingActionButton(
        onPressed: _addPartner,
        child: Icon(Icons.add),
      ),

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 30), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 30), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add, size: 30), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time, size: 30), label: 'Recent'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 30), label: 'Settings'),
        ],
      ),
    );
  }
}