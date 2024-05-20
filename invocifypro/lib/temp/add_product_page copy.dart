import 'dart:convert';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/theme.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:http/http.dart' as http;

class AddProductPage extends StatefulWidget {
  const AddProductPage({super.key});

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final TextEditingController _qrCodeController = TextEditingController();
  final TextEditingController _productNameController = TextEditingController();
  final TextEditingController _sellingPriceController = TextEditingController();
  final TextEditingController _mrpPriceController = TextEditingController();
  final TextEditingController _costPriceController = TextEditingController();
  final TextEditingController _currentStockController = TextEditingController();
  final TextEditingController _alertStockLimitController =
      TextEditingController();

  String _selectedStockUnit = 'Number';
  late QRViewController _qrViewController;
  RxBool isFlashOn = false.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: _buildTextField(
                    _qrCodeController,
                    'Product QR Code/Unique ID',
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _openQRScannerBottomSheet();
                  },
                  icon: Icon(
                    Icons.qr_code_scanner,
                    size: 38,
                    color: MyTheme.accent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            _buildTextField(_productNameController, 'Product Name'),
            const SizedBox(height: 15),
            _buildTextField(_sellingPriceController, 'Selling Price',
                keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(_mrpPriceController, 'MRP Price',
                keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(_costPriceController, 'Cost Price',
                keyboardType: TextInputType.number),
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
            _buildTextField(_currentStockController, 'Current Stock',
                keyboardType: TextInputType.number),
            const SizedBox(height: 15),
            _buildTextField(_alertStockLimitController, 'Alert Stock Limit',
                keyboardType: TextInputType.number),
            const SizedBox(height: 40),
            customButton(
              label: 'Save',
              onTap: () {
                if (_qrCodeController.text.isEmpty) {
                  showSnackBar(context, "Product QR Code/Unique ID Required");
                  return;
                }
                if (_productNameController.text.isEmpty) {
                  showSnackBar(context, "Product Name Required");
                  return;
                }
                if (_sellingPriceController.text.isEmpty) {
                  showSnackBar(context, "Selling Price Required");
                  return;
                }

                storeProduct();
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
      bool isRequired = false}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' *' : ''),
        labelStyle: TextStyle(color: MyTheme.textColor),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey)),
      ),
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      keyboardType: keyboardType,
      style: TextStyle(color: MyTheme.textColor),
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

  void _openQRScannerBottomSheet() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          height: 250,
          child: Stack(
            alignment: Alignment.topRight,
            children: [
              Expanded(
                child: QRView(
                  overlay: QrScannerOverlayShape(
                    borderColor: MyTheme.accent,
                    borderWidth: 6,
                    // cutOutSize: 300,
                    cutOutWidth: 250,
                    cutOutHeight: 150,
                  ),
                  key: GlobalKey(debugLabel: 'QR'),
                  onQRViewCreated: (controller) {
                    _qrViewController = controller;
                    controller.scannedDataStream.listen((scanData) {
                      _qrCodeController.text = scanData.code!;
                      Get.back();
                    });
                  },
                ),
              ),
              IconButton(
                onPressed: () {
                  isFlashOn.value = !isFlashOn.value;
                  _qrViewController.toggleFlash();
                },
                style: IconButton.styleFrom(padding: const EdgeInsets.all(20)),
                icon: Obx(
                  () => Icon(
                    isFlashOn.value ? Icons.flash_off : Icons.flash_on,
                    color: MyTheme.accent,
                    size: 28,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> storeProduct() async {
    int userId = await GetStorage().read("id");

    // Validate data types before making the POST request
    if (!isNumeric(_sellingPriceController.text) ||
        !isNumeric(_mrpPriceController.text) ||
        !isNumeric(_costPriceController.text) ||
        !isNumeric(_currentStockController.text) ||
        !isNumeric(_alertStockLimitController.text)) {
      // Handle error: Invalid data type
      showSnackBar(context, "Invalid data type for numeric fields");
      print('Error: Invalid data type for numeric fields');
      return;
    }

    EasyLoading.show(status: 'Please Wait ...');
    // Check if the QR code already exists
    var qrCodeResponse = await http.post(
      Uri.parse(ApiConstants.checkQRCodeUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({'qrCode': _qrCodeController.text}),
    );

    if (qrCodeResponse.statusCode == 200) {
      var qrCodeData = json.decode(qrCodeResponse.body);
      if (qrCodeData['exists']) {
        showSnackBar(context, "QR Code already exists.");
        // print('Error: QR Code already exists.');
        return;
      }
    } else {
      // Handle errors
      print('Error checking QR Code: ${qrCodeResponse.reasonPhrase}');
      return;
    }

    // Make the POST request
    var response = await http.post(
      Uri.parse(ApiConstants.storeProductUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode({
        'userid': userId,
        'qrCode': _qrCodeController.text,
        'productName': _productNameController.text,
        'sellingPrice': _sellingPriceController.text,
        'mrpPrice': _mrpPriceController.text,
        'costPrice': _costPriceController.text,
        'currentStock': _currentStockController.text,
        'alertStockLimit': _alertStockLimitController.text,
        'stockUnit': _selectedStockUnit,
      }),
    );
    print(response);
    if (response.statusCode == 200) {
      // Product stored successfully
      _qrCodeController.text = "";
      _productNameController.text = "";
      _sellingPriceController.text = "";
      _mrpPriceController.text = "";
      _costPriceController.text = "";
      _currentStockController.text = "";
      _alertStockLimitController.text = "";
    } else {
      // Handle errors
      print('Error: ${response.reasonPhrase}');
    }
  }

  bool isNumeric(String str) {
    if (str == "") {
      return true;
    }
    return double.tryParse(str) != null;
  }

  // @override
  // void dispose() {
  // _qrViewController.dispose();
  //   super.dispose();
  // }
}
