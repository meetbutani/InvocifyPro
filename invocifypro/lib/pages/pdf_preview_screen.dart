// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/pages/home_page.dart';
import 'package:invocifypro/theme.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:whatsapp_share/whatsapp_share.dart';
import 'package:http/http.dart' as http;

class PDFPreviewScreen extends StatelessWidget {
  final String pdfPath;
  final String? whatsappNo;
  final Map<String, dynamic>? invoiceData;
  final String? pageTitle;

  const PDFPreviewScreen(
      {Key? key,
      required this.pdfPath,
      this.whatsappNo,
      this.invoiceData,
      this.pageTitle})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (val) async {
        if (invoiceData != null) {
          await _showExitConfirmationDialog(context);
        } else {
          Get.back();
        }
      },
      child: Scaffold(
        backgroundColor: MyTheme.background,
        appBar: AppBar(
          backgroundColor: MyTheme.background,
          centerTitle: true,
          title: Text(
            pageTitle ?? 'Invoice Preview',
            style: TextStyle(color: MyTheme.textColor),
          ),
          leading: IconButton(
            onPressed: () async {
              // Show dialog when back button is pressed
              if (invoiceData != null) {
                await _showExitConfirmationDialog(context);
              } else {
                Get.back();
              }
            },
            icon: Icon(
              Icons.arrow_back,
              color: MyTheme.accent,
              size: 34,
            ),
          ),
        ),
        body: PDFView(
          filePath: pdfPath,
          enableSwipe: true,
          swipeHorizontal: true,
          autoSpacing: false,
          pageFling: false,
          onRender: (pages) {
            if (kDebugMode) {
              print("PDF is rendered");
            }
          },
          onError: (error) {
            if (kDebugMode) {
              print(error.toString());
            }
          },
          onPageError: (page, error) {
            if (kDebugMode) {
              print('$page: ${error.toString()}');
            }
          },
          onViewCreated: (PDFViewController pdfViewController) {
            // You can use the controller to interact with the PDF view
          },
          onPageChanged: (int? page, int? total) {
            if (kDebugMode) {
              print('page change: $page/$total');
            }
          },
        ),
        floatingActionButton: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            FloatingActionButton(
              onPressed: () {
                Printing.sharePdf(
                    bytes: File(pdfPath).readAsBytesSync(),
                    filename: 'invoice.pdf');
              },
              backgroundColor: MyTheme.accent,
              child: Icon(Icons.share, color: MyTheme.background, size: 28),
            ),
            const SizedBox(height: 16),
            if (whatsappNo != null)
              FloatingActionButton(
                onPressed: () async {
                  bool? whatsappInstalled = await WhatsappShare.isInstalled(
                    package: Package.whatsapp,
                  );

                  if (whatsappInstalled ?? false) {
                    _sendFile(context, pdfPath, whatsappNo!);
                  } else {
                    showSnackBar(context, 'WhatsApp not installed.');
                  }
                },
                backgroundColor: MyTheme.accent,
                child: FaIcon(FontAwesomeIcons.whatsapp,
                    color: MyTheme.background, size: 30),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _sendFile(
      BuildContext context, String filePath, String phoneNumber) async {
    final String formattedPhoneNumber =
        phoneNumber.replaceAll(RegExp(r'[+\s]'), '');

    const String message = 'Thank you for business.';
    final Uri whatsappUri = Uri.parse(
        'https://wa.me/$formattedPhoneNumber?text=${Uri.encodeComponent(message)}');
    final bool whatsappInstalled =
        await canLaunchUrlString(whatsappUri.toString());

    if (whatsappInstalled) {
      await launchUrlString(whatsappUri.toString());
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: MyTheme.cardBackground,
            title: Text(
              'WhatsApp Not Installed',
              style: TextStyle(
                color: MyTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Please install WhatsApp to send the message and file.',
              style: TextStyle(color: MyTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: MyTheme.accent),
                ),
              ),
            ],
          );
        },
      );
      return;
    }

    final bool? shareResult = await WhatsappShare.shareFile(
      phone: formattedPhoneNumber,
      filePath: [filePath],
    );

    if (shareResult != null && shareResult) {
      if (kDebugMode) {
        print('File shared successfully.');
      }
    } else {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: MyTheme.cardBackground,
            title: Text(
              'Failed to Share File',
              style: TextStyle(
                color: MyTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Unable to share the file via WhatsApp.',
              style: TextStyle(color: MyTheme.textColor),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Get.back();
                },
                child: Text(
                  'OK',
                  style: TextStyle(color: MyTheme.accent),
                ),
              ),
            ],
          );
        },
      );
    }
  }

  Future<bool?> isInstalled() async {
    return await WhatsappShare.isInstalled(package: Package.whatsapp);
  }

  Future<void> _showExitConfirmationDialog(BuildContext context) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: MyTheme.cardBackground,
          title: Text(
            'Confirm Exit',
            style: TextStyle(
              color: MyTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Do you want to save the invoice in the database?',
            style: TextStyle(color: MyTheme.textColor),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Get.back();
                Get.back();
              },
              child: Text(
                'Edit',
                style: TextStyle(color: MyTheme.accent),
              ),
            ),
            TextButton(
              onPressed: () async {
                Get.back();
                await saveInvoice(context, invoiceData!);
              },
              child: Text(
                'Save',
                style: TextStyle(color: MyTheme.accent),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> saveInvoice(
      BuildContext context, Map<String, dynamic> invoiceData) async {
    EasyLoading.show(status: 'Please Wait ...');

    List<dynamic> needToUpdate =
        invoiceData["products"].map((item) => [item[4], item[1]]).toList();

    invoiceData["needToUpdate"] = needToUpdate;

    invoiceData["products"] = invoiceData["products"]
        .map((item) => [item[0], item[1], item[2], item[3]])
        .toList();

    // Make the POST request to store the generated invoice
    var response = await http.post(
      Uri.parse(ApiConstants.storeInvoiceUrl),
      headers: {'Content-Type': 'application/json'},
      body: json.encode(invoiceData),
    );

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      Get.offAll(const HomePage());
      // showSnackBar(context, "Invoice created successfully.");
    } else {
      // Handle errors
      if (kDebugMode) {
        print('Error in saving invoice: ${response.reasonPhrase}');
      }
      showSnackBar(context, "Error in saving invoice.");
    }
  }
}
