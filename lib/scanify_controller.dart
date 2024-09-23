// scanify_controller.dart
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'database_helper.dart';

class ScanifyController {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController controller;
  final FocusNode focusNode;
  final Function() onDataChanged;

  ScanifyController({
    required this.controller,
    required this.focusNode,
    required this.onDataChanged,
  });

  Future<void> insertData(String code) async {
    if (code.length < 20) {
      Fluttertoast.showToast(
        msg: 'Invalid code: must be at least 20 characters long.',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
      return;
    }
    try {
      await _dbHelper.insertScan(code);
      Fluttertoast.showToast(
        msg: 'Data saved successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Record exists',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    } finally {
      onDataChanged();
    }
  }

  Future<void> fetchData(
      Function(List<Map<String, dynamic>>) onDataFetched) async {
    try {
      final data = await _dbHelper.getScannedData();
      onDataFetched(data);
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to fetch data: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }

  Future<void> sendDataToApi() async {
    try {
      await _dbHelper.sendScannedDataToApi();
      Fluttertoast.showToast(
        msg: 'All data sent successfully',
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
      );
      fetchData((data) {});
    } catch (e) {
      Fluttertoast.showToast(
        msg: 'Failed to send data: ${e.toString()}',
        toastLength: Toast.LENGTH_LONG,
        gravity: ToastGravity.BOTTOM,
      );
    }
  }
}
