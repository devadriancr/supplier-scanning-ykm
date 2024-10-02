import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'scanify_controller.dart';

void main() {
  runApp(ScanifyApp());
}

class ScanifyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'supplier scanning',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: ScanifyHomePage(),
    );
  }
}

class ScanifyHomePage extends StatefulWidget {
  @override
  _ScanifyHomePageState createState() => _ScanifyHomePageState();
}

class _ScanifyHomePageState extends State<ScanifyHomePage> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late ScanifyController _scanifyController;

  List<Map<String, dynamic>> _scannedData = [];
  bool _isLoading = false;
  int _count = 0;

  @override
  void initState() {
    super.initState();
    _focusNode.requestFocus();
    _scanifyController = ScanifyController(
      controller: _textController,
      focusNode: _focusNode,
      onDataChanged: _fetchData,
    );
    _fetchData();
  }

  Future<void> _fetchData() async {
    await _scanifyController.fetchData((data) {
      setState(() {
        _scannedData = data;
      });
    });
    _updateCount(); // Update the count when data is fetched
  }

  Future<void> _updateCount() async {
    int count = await _scanifyController.getActiveScansCount();
    setState(() {
      _count = count;
    });
  }

  void _showToastAndSaveToDatabase() {
    String inputText = _textController.text;

    if (inputText.isNotEmpty) {
      _scanifyController.insertData(inputText);

      _textController.clear();
      _focusNode.requestFocus();
    }
  }

  Future<void> _sendDataToApi() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await _scanifyController.sendDataToApi();
    } finally {
      setState(() {
        _isLoading = false;
      });
      _fetchData(); // Refresh data after sending
    }
  }

  @override
  void dispose() {
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  String _formatDateTime(String iso8601String) {
    final DateTime dateTime = DateTime.parse(iso8601String);
    final DateFormat formatter = DateFormat('dd-MM-yyyy HH:mm');
    return formatter.format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Supplier Scanning'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              decoration: InputDecoration(
                hintText: 'Enter Code Here',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) => _showToastAndSaveToDatabase(),
            ),
            SizedBox(height: 16.0),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _sendDataToApi,
                icon: Icon(Icons.cloud_sync),
                label: Text('Load Scanned Data'),
              ),
            ),
            SizedBox(height: 16.0),
            // Display the total count of active scans
            Text(
              'Scanned: $_count',
              style: TextStyle(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16.0),
            _isLoading
                ? Center(child: CircularProgressIndicator())
                : Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.vertical,
                        child: DataTable(
                          columns: [
                            DataColumn(label: Text('Code')),
                            DataColumn(label: Text('Status')),
                            DataColumn(label: Text('Created At')),
                          ],
                          rows: _scannedData
                              .map(
                                (item) => DataRow(
                                  cells: [
                                    DataCell(Text(item['code'])),
                                    DataCell(
                                      Text(
                                        item['status'] == 1
                                            ? 'Scanned'
                                            : 'Loaded',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16.0,
                                          color: item['status'] == 1
                                              ? Colors.orange
                                              : Colors.green,
                                        ),
                                      ),
                                    ),
                                    DataCell(Text(
                                        _formatDateTime(item['created_at']))),
                                  ],
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
