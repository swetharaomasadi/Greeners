import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SearchPartnerScreen extends StatefulWidget {
  @override
  _SearchPartnerScreenState createState() => _SearchPartnerScreenState();
}

class _SearchPartnerScreenState extends State<SearchPartnerScreen> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  String? selectedPartner;
  String? selectedCrop;
  Map<String, dynamic> partnerData = {};
  Map<String, Map<String, dynamic>> allDataMap = {};
  double totalProfit = 0.0;
  List<String> partners = ['No Gain Sharer'];
  bool isFetchingPartners = true;
  bool isLoading = false;
  final ScrollController _scrollController = ScrollController();
  Map<String, List<dynamic>> allRecordsMap = {};
  List<dynamic> filteredRecords = [];
  bool hideProfitCard = false;

  @override
  void initState() {
    super.initState();
    if (userId != null) {
      fetchPartners();
      fetchAllRecords();
    }
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> fetchPartners() async {
    if (userId == null) return;

    setState(() {
      isFetchingPartners = true;
    });

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Query query = firestore
        .collection('partners')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: userId!)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${userId!}\uf8ff");

    QuerySnapshot userDocs = await query.get();

    if (userDocs.docs.isEmpty) {
      setState(() {
        isFetchingPartners = false;
      });
      return;
    }

    List<String> fetchedPartners = [];
    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> partnersList = data['partners'] ?? [];
      for (var partner in partnersList) {
        if (partner is String && !fetchedPartners.contains(partner)) {
          fetchedPartners.add(partner);
        }
      }

      Map<String, dynamic> profits = data['profits'] ?? {};
      profits.forEach((partner, value) {
        if (value is Map<String, dynamic>) {
          Map<String, dynamic> partnerProfits = value['crops'] ?? {};
          partnerProfits.forEach((cropName, cropData) {
            double totalEarnings = (cropData['tear'] ?? 0.0).toDouble();
            double totalExpenditures = (cropData['texp'] ?? 0.0).toDouble();
            if (totalEarnings > 0 || totalExpenditures > 0) {
              if (!partners.contains(partner)) {
                partners.add(partner);
              }
              if (!allDataMap.containsKey(partner)) {
                allDataMap[partner] = {};
              }
              allDataMap[partner]![cropName] = {
                'crop_name': cropName,
                'total_earnings': totalEarnings,
                'total_expenditures': totalExpenditures,
                'total_weight': cropData['tw'] ?? 0.0,
                'profit': cropData['tp'] ?? 0.0,
              };
            }
          });
        }
      });
    }

    setState(() {
      partners.addAll(fetchedPartners);
      isFetchingPartners = false;
    });
  }

  Future<void> fetchAllRecords() async {
    if (userId == null) return;

    FirebaseFirestore firestore = FirebaseFirestore.instance;
    Query query = firestore
        .collection('records')
        .where(FieldPath.documentId, isGreaterThanOrEqualTo: userId!)
        .where(FieldPath.documentId, isLessThanOrEqualTo: "${userId!}\uf8ff");

    QuerySnapshot userDocs = await query.get();

    Map<String, List<dynamic>> tempRecordsMap = {};
    for (var doc in userDocs.docs) {
      Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
      List<dynamic> records = data['r'] ?? [];
      for (var record in records) {
        String date = record['date'];
        if (!tempRecordsMap.containsKey(date)) {
          tempRecordsMap[date] = [];
        }
        tempRecordsMap[date]!.add(record);
      }
    }

    setState(() {
      allRecordsMap = tempRecordsMap;
    });
  }

  void searchPartnerData(String partner) async {
    if (userId == null) return;

    setState(() {
      isLoading = true;
      selectedPartner = partner;
    });

    await Future.delayed(Duration(milliseconds: 300));

    double totalProfitCalc = 0.0;
    Map<String, dynamic> dataMap = {};

    if (allDataMap.containsKey(partner)) {
      allDataMap[partner]!.forEach((cropName, details) {
        if (details['profit'] != null) {
          totalProfitCalc += details['profit'];
        }
        dataMap.putIfAbsent(cropName, () => details);
      });
    }

    setState(() {
      partnerData = dataMap;
      totalProfit = totalProfitCalc;
      isLoading = false;
    });
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;

    double offset = _scrollController.position.pixels;

    if (offset > 50 && !hideProfitCard) {
      setState(() {
        hideProfitCard = true;
      });
    } else if (offset <= 50 && hideProfitCard) {
      setState(() {
        hideProfitCard = false;
      });
    }
  }

  void searchRecordsForPartnerCrop(String partner, String cropName) {
  if (partner.isEmpty || cropName.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Error: No partner or crop selected.")),
    );
    return;
  }

  setState(() {
    selectedCrop = cropName;
    filteredRecords = allRecordsMap.values
        .expand((records) => records
            .where((record) {
              bool partnerMatches = record['partner'] == partner;
              bool cropMatches = record['c_id'] == cropName; // Ensure this matches the key in your data
              print("Record: $record, Partner Matches: $partnerMatches, Crop Matches: $cropMatches"); // Debugging print statement
              return partnerMatches && cropMatches;
            }))
        .toList();
  });

  print("Filtered Records: $filteredRecords"); // Debugging print statement

  if (filteredRecords.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("No records found for this crop.")),
    );
    return;
  }

  WidgetsBinding.instance.addPostFrameCallback((_) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => RecordsScreen(
          partner: partner,
          cropName: cropName,
          allRecords: filteredRecords, // Pass filtered records
        ),
      ),
    );
  });
}
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Search Partner',
        style: TextStyle(color: Colors.white),
      ),
      backgroundColor: const Color.fromARGB(255, 218, 56, 213),
    ),
    body: Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (isFetchingPartners)
            Center(child: CircularProgressIndicator())
          else if (partners.isEmpty)
            Center(child: Text("No partners found."))
          else
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              child: DropdownButton<String>(
                value: partners.contains(selectedPartner) ? selectedPartner : null,
                hint: Text('Select Partner'),
                isExpanded: true,
                items: partners.toSet().map((partner) {
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
                underline: SizedBox(), // Removes default underline
                icon: Icon(Icons.arrow_drop_down, color: Colors.purple, size: 30),
              ),
            ),
          SizedBox(height: 10),
          if (isLoading) CircularProgressIndicator(),
          if (selectedPartner != null && !isLoading)
            Expanded(
              child: partnerData.isEmpty && !isLoading
                  ? Center(child: Text("No data available for this partner."))
                  : Column(
                      children: [
                        if (!hideProfitCard)
                          Card(
                            color: Colors.blue,
                            child: Padding(
                              padding: EdgeInsets.all(12),
                              child: Text(
                                'Total Profit: ₹${totalProfit.toStringAsFixed(2)} ${totalProfit >= 0 ? '💐' : '⚠'}',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        SizedBox(height: 10),
                        Expanded(
                          child: ListView.builder(
                            controller: _scrollController,
                            itemCount: partnerData.length,
                            itemBuilder: (context, index) {
                              String cropName = partnerData.keys.elementAt(index);
                              var details = partnerData[cropName]!;
                              return Card(
                                elevation: 3,
                                margin: EdgeInsets.symmetric(vertical: 8),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  title: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '${details['crop_name']}',
                                        style: TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.green,
                                        ),
                                      ),
                                      Divider(color: Colors.grey), // Adds underline after crop name
                                    ],
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Total Wgt: ${details['total_weight']} kg/boxes/pcs',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color:  const Color.fromARGB(255, 38, 41, 44),
                                        ),
                                      ),
                                      Text(
                                        'Earnings: ₹${details['total_earnings']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color:  const Color.fromARGB(255, 38, 41, 44),
                                        ),
                                      ),
                                      Text(
                                        'Expenditures: ₹${details['total_expenditures']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: const Color.fromARGB(255, 38, 41, 44),
                                        ),
                                      ),
                                      Text(
                                        'Profit: ₹${details['profit']}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: details['profit'] >= 0 ? Colors.green : Colors.red,
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () => searchRecordsForPartnerCrop(selectedPartner!, cropName),
                                        style: TextButton.styleFrom(
                                          backgroundColor: Colors.purple,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        ),
                                        child: Text(
                                          "Show Records",
                                          style: TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
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
class RecordsScreen extends StatefulWidget {
  final String partner;
  final String cropName;
  final List<dynamic> allRecords; // Pass all records

  RecordsScreen({
    required this.partner,
    required this.cropName,
    required this.allRecords,
  });

  @override
  _RecordsScreenState createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  final ScrollController _scrollController = ScrollController();
  Map<int, bool> _expandedMap = {}; // Track expanded state for descriptions
  bool isLoadingMore = false;
  int currentPage = 0;
  final int pageSize = 10;
  List<dynamic> records = []; // Store paginated records

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _loadInitialData();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

void _loadInitialData() {
  setState(() {
    records = widget.allRecords.take(pageSize).toList();
  });
  print("Initial Records Loaded: $records"); // Debugging print statement
}

  void _scrollListener() {
    if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent &&
        !isLoadingMore) {
      onLoadMore();
    }
  }

  Future<void> onLoadMore() async {
    if (isLoadingMore) return;

    setState(() {
      isLoadingMore = true;
    });

    // Calculate the next page of data
    int nextPageStartIndex = (currentPage + 1) * pageSize;
    int nextPageEndIndex = nextPageStartIndex + pageSize;

    if (nextPageStartIndex < widget.allRecords.length) {
      setState(() {
        records.addAll(widget.allRecords
            .sublist(nextPageStartIndex, nextPageEndIndex > widget.allRecords.length ? widget.allRecords.length : nextPageEndIndex));
        currentPage++;
        isLoadingMore = false;
      });
    } else {
      setState(() {
        isLoadingMore = false; // No more data to load
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Records', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: Colors.purple.shade700,
        elevation: 5,
      ),
      body: Column(
        children: [
          Expanded(
            child: records.isEmpty
                ? Center(
                    child: Text(
                      'No records found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  )
                : ListView.separated( // ✅ Optimized ListView
                    controller: _scrollController,
                    itemCount: records.length + (isLoadingMore ? 1 : 0),
                    separatorBuilder: (context, index) => const SizedBox(height: 5), // Adds space between items
                    itemBuilder: (context, index) {
                      if (index == records.length) {
                        return Center(child: CircularProgressIndicator());
                      }

                      var record = records[index];
                      String partnerName = record['partner'] ?? 'No Partner';
                      String type = record['t'] ?? record['typ'] ?? 'Unknown';
                      bool isExpanded = _expandedMap[index] ?? false;

                      return Align(
                        alignment: Alignment.center,
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width * 0.95,
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 8),
                            elevation: 5,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey[300]!, width: 1),
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(12),
                                gradient: LinearGradient(
                                  colors: type == 'sale'
                                      ? [Colors.green.shade200, Colors.green.shade50]
                                      : [Colors.blue.shade200, Colors.blue.shade50],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      partnerName,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.teal.shade700,
                                      ),
                                    ),
                                    const Divider(),

                                    // ✅ Sale Type Fields
                                    if (type == 'sale') ...[
                                      _buildInfoRow(Icons.shopping_cart, "Crop", record['c_id']),
                                      _buildInfoRow(Icons.storefront, "Vendor", record['v_id']),
                                      _buildInfoRow(Icons.attach_money, "Total Bill", "₹${record['tb'] ?? '0'}"),
                                      _buildInfoRow(Icons.scale, "Weight", "${record['w'] ?? '0'} kg/boxes/pcs"),
                                    ]
                                    // ✅ Expense Type Fields
                                    else if (type == 'exp') ...[
                                      _buildInfoRow(Icons.grass, "Crop", record['c_id']),
                                      const SizedBox(height: 6),

                                      // ✅ Expandable Large Description with Scrolling
                                      StatefulBuilder(
                                        builder: (context, setInnerState) {
                                          return GestureDetector(
                                            onTap: () {
                                              setInnerState(() {
                                                _expandedMap[index] = !_expandedMap[index]!;
                                              });
                                            },
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Icon(Icons.description, color: Colors.deepPurple),
                                                    const SizedBox(width: 5),
                                                    Text(
                                                      "Desc:",
                                                      style: TextStyle(
                                                        fontSize: 15,
                                                        fontWeight: FontWeight.bold,
                                                        color: Colors.deepPurple,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                AnimatedCrossFade(
                                                  firstChild: Text(
                                                    record['desc'] ?? 'Unknown',
                                                    maxLines: 2,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: TextStyle(fontSize: 15, color: Colors.black87),
                                                  ),
                                                  secondChild: Container(
                                                    width: double.infinity,
                                                    padding: const EdgeInsets.all(8),
                                                    decoration: BoxDecoration(
                                                      color: Colors.grey[100],
                                                      borderRadius: BorderRadius.circular(5),
                                                    ),
                                                    child: SingleChildScrollView(
                                                      child: Text(
                                                        record['desc'] ?? 'Unknown',
                                                        style: TextStyle(fontSize: 15, color: Colors.black87),
                                                      ),
                                                    ),
                                                  ),
                                                  crossFadeState: _expandedMap[index] == true
                                                      ? CrossFadeState.showSecond
                                                      : CrossFadeState.showFirst,
                                                  duration: Duration(milliseconds: 300),
                                                ),
                                              ],
                                            ),
                                          );
                                        },
                                      ),
                                      const SizedBox(height: 6),
                                      _buildInfoRow(Icons.money_off, "Amount Spent", "₹${record['amt'] ?? '0'}"),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ✅ Improved _buildInfoRow() Helper Function with Icons
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.black54),
          const SizedBox(width: 6),
          Text(
            "$label: ",
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value ?? "Unknown",
              style: const TextStyle(fontSize: 15, color: Colors.black54),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}