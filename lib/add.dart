import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'record_options.dart';
import 'home.dart';
import 'search.dart';
import 'settings.dart';
import 'recent_records_page.dart';

class AddPage extends StatefulWidget {
  const AddPage({super.key});

  @override
  _AddPageState createState() => _AddPageState();
}

class _AddPageState extends State<AddPage> {
  List<String> partners = ["No Gain Sharer"]; // Default partner
  String? _errorMessage;
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
        title: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Image.asset(
              'assets/logo.png',
              height: 80,
            ),
          ],
        ),
      ),
      body: Center(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              child: Text(
                "Add your partner by clicking the '+' sign. If already added, click the partner's name to enter data for shared profit.",
                style: TextStyle(fontSize: 20, color: Color.fromARGB(255, 128, 151, 219)),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 25),
            if (_errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10.0),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red),
                ),
              ),
            SizedBox(height: 10),
            Column(
              children: partners.map((partner) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5.0, horizontal: 10.0),
                  child: ElevatedButton(
                    onPressed: () => _navigateToNextPage(partner),
                    child: Text(partner),
                  ),
                );
              }).toList(),
            ),
            SizedBox(height: 25),
            FloatingActionButton(
              onPressed: _addPartner,
              child: Icon(Icons.add),
            ),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.black,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home, size: 40), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search, size: 40), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.add, size: 40), label: 'Add'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time, size: 40), label: 'Recent'),
          BottomNavigationBarItem(icon: Icon(Icons.settings, size: 40), label: 'Settings'),
        ],
      ),
    );
  }
}
