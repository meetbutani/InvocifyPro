import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:invocifypro/models/product_model.dart';
import 'package:invocifypro/pages/pdf_preview_screen.dart';
import 'package:invocifypro/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class CustomQRCodeListPage extends StatefulWidget {
  const CustomQRCodeListPage({super.key});

  @override
  State<CustomQRCodeListPage> createState() => _CustomQRCodeListPageState();
}

class _CustomQRCodeListPageState extends State<CustomQRCodeListPage> {
  List<dynamic> customQRCodes = [];
  final _formKey = GlobalKey<FormState>();
  final _productNameController = TextEditingController();
  final _sellingPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchCustomQRCodes();
  }

  Future<void> fetchCustomQRCodes() async {
    EasyLoading.show(status: 'Please Wait...');

    var response = await http.get(Uri.parse(
        ApiConstants.getCustomQRCodesUrl + GetStorage().read('id').toString()));

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      print(response.body);
      List<dynamic> data = json.decode(response.body);

      setState(() {
        customQRCodes = data
            .map((json) => {
                  'qrCode': json["qrcode"],
                  'productName': json["product_name"],
                  'sellingPrice': json["selling_price"],
                })
            .toList();

        print(customQRCodes.toString());
      });
    } else {
      showSnackBar(context, json.decode(response.body)['message']);
      print('Failed to load products: ${response.reasonPhrase}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => fetchCustomQRCodes(),
                child: ListView.builder(
                  itemCount: customQRCodes.length,
                  itemBuilder: (context, index) {
                    return Card(
                      color: MyTheme.cardBackground,
                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            QrImageView(
                              data: customQRCodes[index]["qrCode"],
                              backgroundColor: MyTheme.textColor,
                              padding: const EdgeInsets.all(1),
                              size: 80,
                            ),
                            const SizedBox(
                              width: 10,
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  SizedBox(
                                    height: 48,
                                    child: Text(
                                      customQRCodes[index]["productName"],
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: MyTheme.textColor,
                                        fontWeight: FontWeight.bold,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Selling Price: ${customQRCodes[index]["sellingPrice"]}',
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                    ),
                                  ),
                                  Text(
                                    'QR: ${customQRCodes[index]["qrCode"]}',
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              children: [
                                IconButton(
                                  onPressed: () {
                                    _showQRPdfPreview(index);
                                  },
                                  icon: Icon(
                                    Icons.print,
                                    color: MyTheme.accent,
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    _showEditProductDialog(index);
                                  },
                                  icon: Icon(
                                    Icons.edit,
                                    color: MyTheme.accent,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddNewQRCodeDialog,
        tooltip: 'Add New QR code',
        backgroundColor: MyTheme.cardBackground,
        child: Icon(
          Icons.add,
          color: MyTheme.accent,
          size: 32,
        ),
      ),
    );
  }

  void _showAddNewQRCodeDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MyTheme.cardBackground,
          title: Text(
            'Generate New QR code',
            style: TextStyle(
              color: MyTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _productNameController,
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: TextStyle(color: MyTheme.textColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                  style: TextStyle(color: MyTheme.textColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
                TextFormField(
                  controller: _sellingPriceController,
                  decoration: InputDecoration(
                    labelText: 'Selling Price',
                    labelStyle: TextStyle(color: MyTheme.textColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                  style: TextStyle(color: MyTheme.textColor),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
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
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter selling price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: MyTheme.accent),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final productName = _productNameController.text;
                  final sellingPrice = _sellingPriceController.text;

                  final qrCode = 'CUST${DateTime.now().millisecondsSinceEpoch}';

                  await _generateQRCodeAndSaveToDatabase(
                      qrCode, productName, sellingPrice);

                  Get.back();
                }
              },
              child: Text(
                'Generate QR Code',
                style: TextStyle(color: MyTheme.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _generateQRCodeAndSaveToDatabase(
    String qrCode,
    String productName,
    String sellingPrice,
  ) async {
    print(qrCode);
    print(productName);
    print(sellingPrice);
    EasyLoading.show(status: 'Please Wait...');

    final response = await http.post(
      Uri.parse(ApiConstants.storeCustomQRCodeUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userid': GetStorage().read('id').toString(),
        'qrCode': qrCode,
        'productName': productName,
        'sellingPrice': sellingPrice,
      }),
    );

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      showSnackBar(context, 'QR created successfully', isError: false);
      fetchCustomQRCodes();
    } else {
      showSnackBar(context, json.decode(response.body)['message']);
      print('Failed to add product: ${response.reasonPhrase}');
    }
  }

  void _showEditProductDialog(int index) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MyTheme.cardBackground,
          title: Text(
            'Edit QR code',
            style: TextStyle(
              color: MyTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _productNameController
                    ..text = customQRCodes[index]['productName'],
                  decoration: InputDecoration(
                    labelText: 'Product Name',
                    labelStyle: TextStyle(color: MyTheme.textColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                  style: TextStyle(color: MyTheme.textColor),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter product name';
                    }
                    return null;
                  },
                ),
                const SizedBox(
                  height: 15,
                ),
                TextFormField(
                  controller: _sellingPriceController
                    ..text = customQRCodes[index]['sellingPrice'],
                  decoration: InputDecoration(
                    labelText: 'Selling Price',
                    labelStyle: TextStyle(color: MyTheme.textColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey)),
                  ),
                  style: TextStyle(color: MyTheme.textColor),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
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
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter selling price';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Get.back();
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: MyTheme.accent),
              ),
            ),
            TextButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  final productName = _productNameController.text;
                  final sellingPrice = _sellingPriceController.text;

                  final qrCode = customQRCodes[index]['qrCode'];

                  await _updateQRCodeDetails(qrCode, productName, sellingPrice);

                  Get.back();
                }
              },
              child: Text(
                'Update QR Code',
                style: TextStyle(color: MyTheme.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateQRCodeDetails(
    String qrCode,
    String productName,
    String sellingPrice,
  ) async {
    EasyLoading.show(status: 'Updating...');
    final response = await http.put(
      Uri.parse(ApiConstants.updateCustomQRCodeUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'userid': GetStorage().read('id').toString(),
        'qrCode': qrCode,
        'productName': productName,
        'sellingPrice': sellingPrice,
      }),
    );
    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      showSnackBar(context, 'QR code details updated successfully',
          isError: false);
      fetchCustomQRCodes(); // Refresh the list after updating
    } else {
      showSnackBar(context, 'Failed to update QR code details.');
      print('Failed to update QR code details: ${response.reasonPhrase}');
    }
  }

  void _showQRPdfPreview(int index) async {
    final pdf = pw.Document();
    final image = await QrPainter(
      data: customQRCodes[index]['qrCode'],
      version: QrVersions.auto,
    ).toImage(200);
    final imageBytes = await image.toByteData(format: ImageByteFormat.png);
    final imageWidget = pw.Image(
        pw.MemoryImage(imageBytes!.buffer.asUint8List()),
        height: 90,
        width: 90);
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        build: (pw.Context context) {
          return pw.Column(children: [
            for (int row = 0; row < 8; row++)
              pw.Row(
                children: [
                  for (int col = 0; col < 2; col++)
                    pw.Expanded(
                      child: pw.Container(
                        height: 100,
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            imageWidget,
                            pw.SizedBox(width: 15),
                            pw.Column(
                              mainAxisAlignment: pw.MainAxisAlignment.center,
                              crossAxisAlignment: pw.CrossAxisAlignment.start,
                              children: [
                                pw.SizedBox(
                                  width: 160,
                                  height: 52,
                                  child: pw.Text(
                                    customQRCodes[index]['productName'],
                                    // overflow: pw.TextOverflow.clip,
                                    maxLines: 2,
                                    style: pw.TextStyle(
                                      fontWeight: pw.FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                pw.Text(customQRCodes[index]['qrCode'],
                                    style: const pw.TextStyle(fontSize: 14)),
                                pw.SizedBox(height: 6),
                                pw.Text(
                                    "Price: " +
                                        customQRCodes[index]['sellingPrice'],
                                    style: const pw.TextStyle(fontSize: 14)),
                              ],
                            )
                          ],
                        ),
                      ),
                    )
                ],
              )
          ]);
        },
      ),
    );

    final bytes = await pdf.save();
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/qr_codes.pdf');
    await file.writeAsBytes(bytes);
    Get.to(PDFPreviewScreen(
      pdfPath: file.path,
      pageTitle: "QR Code Preview",
    ));
  }
}
