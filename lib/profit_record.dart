import 'package:flutter/material.dart';

class ProfitRecord extends StatefulWidget {
  @override
  _ProfitRecordScreenState createState() => _ProfitRecordScreenState();
}

class _ProfitRecordScreenState extends State<ProfitRecord> {
  final _vendorController = TextEditingController();
  final _itemController = TextEditingController();
  final _kgsController = TextEditingController();
  final _weightController = TextEditingController();
  final _amountPaidController = TextEditingController();

  double _totalBill = 0.0;
  bool _isSubmitEnabled = false;

  void _calculateTotalBill() {
    final kgs = double.tryParse(_kgsController.text) ?? 0.0;
    final weight = double.tryParse(_weightController.text) ?? 0.0;

    setState(() {
      _totalBill = kgs * weight;
    });

    _validateForm();
  }

  void _validateForm() {
    final amountPaid = double.tryParse(_amountPaidController.text) ?? -1.0;

    setState(() {
      _isSubmitEnabled = _vendorController.text.isNotEmpty &&
          _itemController.text.isNotEmpty &&
          (_kgsController.text.isNotEmpty && double.tryParse(_kgsController.text) != null) &&
          (_weightController.text.isNotEmpty && double.tryParse(_weightController.text) != null) &&
          (_amountPaidController.text.isNotEmpty &&
              double.tryParse(_amountPaidController.text) != null &&
              amountPaid <= _totalBill);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            //
          ],
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _vendorController,
                decoration: InputDecoration(
                  labelText: 'Vendor Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _itemController,
                decoration: InputDecoration(
                  labelText: 'Item Name',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _kgsController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'No. of Kgs/Items',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateTotalBill(),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _weightController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Cost of 1 Kg/Item',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _calculateTotalBill(),
              ),
              SizedBox(height: 16),
              TextField(
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'Total Bill',
                  border: OutlineInputBorder(),
                  hintText: _totalBill.toStringAsFixed(2),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _amountPaidController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: 'Amount Paid',
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _validateForm(),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _isSubmitEnabled
                    ? () {
                        // Perform your submit action here
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Form submitted successfully!')),
                        );
                      }
                    : null,
                child: Text('SUBMIT'),
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _vendorController.dispose();
    _itemController.dispose();
    _kgsController.dispose();
    _weightController.dispose();
    _amountPaidController.dispose();
    super.dispose();
  }
}
