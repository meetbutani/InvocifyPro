import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get/state_manager.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/theme.dart';
import 'package:http/http.dart' as http;

class EditProductPage extends StatefulWidget {
  final String productId;

  const EditProductPage({Key? key, required this.productId}) : super(key: key);

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _mrpPriceController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _newStockController = TextEditingController();
  final TextEditingController _alertStockLimitController =
      TextEditingController();

  String _selectedStockUnit = 'Number';

  @override
  void initState() {
    super.initState();
    fetchProductDetails();
  }

  Future<void> fetchProductDetails() async {
    try {
      EasyLoading.show(status: 'Loading...');

      int userId = await GetStorage().read("id");

      var response = await http.post(
        Uri.parse(ApiConstants.getProductAllDataUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'qrCode': widget.productId, 'userid': userId}),
      );

      if (response.statusCode == 200) {
        var data = json.decode(response.body);
        data = data["data"];
        // print(data);

        _qrCodeController.text = data['qrCode'];
        _productNameController.text = data['productName'];
        _sellingPriceController.text = data['sellingPrice'].toString();
        _mrpPriceController.text = data['mrpPrice'].toString();
        _costPriceController.text = data['costPrice'].toString();
        _currentStockController.text = data['currentStock'].toString();
        _alertStockLimitController.text = data['alertStockLimit'].toString();
        _selectedStockUnit = data['stockUnit'];
      } else {
        if (kDebugMode) {
          print('Failed to load product details');
        }
      }
    } catch (error) {
      if (kDebugMode) {
        print('Error fetching product details: $error');
      }
    } finally {
      EasyLoading.dismiss();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background,
      appBar: AppBar(
        title: Text(
          'Edit Product',
          style: TextStyle(color: MyTheme.textColor),
        ),
        backgroundColor: MyTheme.cardBackground,
        centerTitle: true,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(
            Icons.arrow_back,
            color: MyTheme.accent,
            size: 34,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildTextField(_qrCodeController, 'Product QR Code/Unique ID',
                readOnly: true),
            const SizedBox(height: 15),
            _buildTextField(_productNameController, 'Product Name'),
            const SizedBox(height: 15),
            _buildTextField(_sellingPriceController, 'Selling Price',
                keyboardType: TextInputType.number,
                positive: true,
                decimal: true),
            const SizedBox(height: 15),
            _buildTextField(_mrpPriceController, 'MRP Price',
                keyboardType: TextInputType.number,
                positive: true,
                decimal: true),
            const SizedBox(height: 15),
            _buildTextField(_costPriceController, 'Cost Price',
                keyboardType: TextInputType.number,
                positive: true,
                decimal: true),
            const SizedBox(height: 15),
            DropdownButtonFormField<String>(
              isExpanded: false,
              dropdownColor: MyTheme.cardBackground,
              iconEnabledColor: MyTheme.textColor,
              iconDisabledColor: MyTheme.textColor,
              decoration: InputDecoration(
                labelText: 'Stock Unit',
                labelStyle: TextStyle(color: MyTheme.textColor),
                border: const OutlineInputBorder(),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(color: Colors.grey),
                ),
              ),
              value: _selectedStockUnit,
              onChanged: (String? newValue) {
                setState(() {
                  _selectedStockUnit = newValue!;
                });
              },
              items: <String>['Number', 'Kg', 'Liter']
                  .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: TextStyle(color: MyTheme.textColor),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _currentStockController,
                    style: TextStyle(color: MyTheme.textColor),
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Current Stock',
                      labelStyle: TextStyle(color: MyTheme.textColor),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
                      FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*'))
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (double.parse(_currentStockController.text).toInt() <=
                        double.parse(_newStockController.text).toInt()) {
                      setState(() {
                        _currentStockController.text = "0";
                        _newStockController.clear();
                      });
                      return;
                    }

                    if (_newStockController.text.isNotEmpty) {
                      setState(() {
                        _currentStockController
                            .text = (double.parse(_currentStockController.text)
                                    .toInt() -
                                double.parse(_newStockController.text).toInt())
                            .toString();

                        _newStockController.clear();
                      });
                    }
                  },
                  icon: Icon(
                    Icons.remove,
                    color: MyTheme.accent,
                  ),
                ),
                SizedBox(
                  width: 105,
                  child: TextField(
                    controller: _newStockController,
                    style: TextStyle(color: MyTheme.textColor),
                    onTapOutside: (event) =>
                        FocusManager.instance.primaryFocus?.unfocus(),
                    decoration: InputDecoration(
                      labelText: 'New Stock',
                      labelStyle: TextStyle(color: MyTheme.textColor),
                      border: const OutlineInputBorder(),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
                      FilteringTextInputFormatter.allow(
                          RegExp(r'^[1-9][0-9]*')),
                    ],
                    keyboardType: TextInputType.number,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    if (_newStockController.text.isNotEmpty) {
                      setState(() {
                        _currentStockController
                            .text = (double.parse(_currentStockController.text)
                                    .toInt() +
                                double.parse(_newStockController.text).toInt())
                            .toString();

                        _newStockController.clear();
                      });
                    }
                  },
                  icon: Icon(
                    Icons.add,
                    color: MyTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(_alertStockLimitController, 'Alert Stock Limit',
                keyboardType: TextInputType.number, positive: true),
            const SizedBox(height: 40),
            customButton(
              label: 'Update',
              onTap: () {
                if (_qrCodeController.text.trim().isEmpty) {
                  showSnackBar(context, "Product QR Code/Unique ID Required");
                  return;
                }
                if (_productNameController.text.trim().isEmpty) {
                  showSnackBar(context, "Product Name Required");
                  return;
                }
                if (_sellingPriceController.text.trim().isEmpty) {
                  showSnackBar(context, "Selling Price Required");
                  return;
                }
                updateProduct();
              },
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text,
      bool readOnly = false,
      bool isRequired = false,
      bool positive = false,
      bool decimal = false}) {
    return TextField(
      controller: controller,
      style: TextStyle(color: MyTheme.textColor),
      readOnly: readOnly,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' *' : ''),
        labelStyle: TextStyle(color: MyTheme.textColor),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey),
        ),
      ),
      inputFormatters: positive && decimal
          ? [
              FilteringTextInputFormatter.deny(RegExp('[- ]')),
              TextInputFormatter.withFunction((oldValue, newValue) {
                if (newValue.text == "") {
                  return newValue;
                }

                if (double.tryParse(newValue.text) == null) {
                  return oldValue;
                }

                return newValue;
              })
            ]
          : positive
              ? [
                  FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
                  FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*'))
                ]
              : decimal
                  ? [
                      FilteringTextInputFormatter.deny(RegExp('[ ]')),
                      TextInputFormatter.withFunction((oldValue, newValue) {
                        if (newValue.text == "" || newValue.text == "-") {
                          return newValue;
                        }

                        if (double.tryParse(newValue.text) == null) {
                          return oldValue;
                        }

                        return newValue;
                      })
                    ]
                  : [],
      keyboardType: keyboardType,
    );
  }

  Widget customButton(
      {required String label,
      required VoidCallback onTap,
      bool isExpanded = false}) {
    return Material(
      borderRadius: BorderRadius.circular(8),
      color: MyTheme.cardBackground,
      child: InkWell(
        onTap: onTap,
        splashColor: MyTheme.buttonRippleEffectColor,
        borderRadius: BorderRadius.circular(8),
        child: isExpanded
            ? Container(
                alignment: Alignment.center,
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                child: Text(
                  label,
                  style: MyTheme.buttonTextStyle,
                ),
              )
            : Padding(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 18),
                child: Text(
                  label,
                  style: MyTheme.buttonTextStyle,
                ),
              ),
      ),
    );
  }

  void updateProduct() async {
    int userId = await GetStorage().read("id");

    // Validate data types before making the POST request
    if (!_isNumeric(_sellingPriceController.text) ||
        !_isNumeric(_mrpPriceController.text) ||
        !_isNumeric(_costPriceController.text) ||
        !_isNumeric(_currentStockController.text) ||
        !_isNumeric(_alertStockLimitController.text)) {
      // Handle error: Invalid data type
      if (kDebugMode) {
        print('Error: Invalid data type for numeric fields');
      }
      return;
    }

    EasyLoading.show(status: 'Please Wait ...');

    // Make the PUT request to update product details
    var response = await http.put(
      Uri.parse(ApiConstants.updateProductUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userid': userId,
        'qrCode': _qrCodeController.text,
        'productName': _productNameController.text,
        'sellingPrice': double.tryParse(_sellingPriceController.text) ?? 0,
        'mrpPrice': double.tryParse(_mrpPriceController.text) ?? 0,
        'costPrice': double.tryParse(_costPriceController.text) ?? 0,
        'currentStock': int.tryParse(_currentStockController.text) ?? 0,
        'alertStockLimit': int.tryParse(_alertStockLimitController.text) ?? 0,
        'stockUnit': _selectedStockUnit,
      }),
    );

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      showSnackBar(context, "Product updated successfully.",
          isError: false, isDismissible: false);

      await Future.delayed(
          const Duration(seconds: 3), () => Get.back(result: true));
    } else {
      // Handle errors
      if (kDebugMode) {
        print('Error updating product: ${response.reasonPhrase}');
      }
      showSnackBar(context, "Error updating product.", isDismissible: false);
      await Future.delayed(
          const Duration(seconds: 3), () => Get.back(result: false));
    }
  }

  bool _isNumeric(String str) {
    if (str.isEmpty) {
      return true;
    }
    return double.tryParse(str) != null;
  }
}
