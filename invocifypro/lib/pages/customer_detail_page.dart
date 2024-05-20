// ignore_for_file: use_build_context_synchronously

import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/pages/pdf_preview_screen.dart';
import 'package:invocifypro/theme.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class CustomerDetailPage extends StatefulWidget {
  final Map<String, dynamic> invoiceItems;
  final double totalAmount;
  const CustomerDetailPage(this.invoiceItems, this.totalAmount, {super.key});

  @override
  State<CustomerDetailPage> createState() => _CustomerDetailPageState();
}

class _CustomerDetailPageState extends State<CustomerDetailPage> {
  final TextEditingController _custNameController =
      TextEditingController(text: 'Meet Butani');
  final TextEditingController _custAddressController = TextEditingController(
      text:
          'E-301 Miramanan Residency, nikol, Ahmedabad, Gujarat, India - 382350');
  final TextEditingController _custPhoneController = TextEditingController();
  final TextEditingController _custEmailController =
      TextEditingController(text: 'meet.butani2702@gmail.com');

  Map<String, dynamic>? invoiceData;

  late PhoneNumber number;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    number = PhoneNumber.fromCompleteNumber(completeNumber: '+919327052373');
    _custPhoneController.text = number.number;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background,
      appBar: AppBar(
        backgroundColor: MyTheme.background,
        centerTitle: true,
        title: Text(
          'Customer Details',
          style: TextStyle(color: MyTheme.textColor),
        ),
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
            _buildTextField(_custNameController, 'Customer Name',
                isRequired: true),
            const SizedBox(height: 15),
            _buildTextField(_custAddressController, 'Customer Address',
                keyboardType: TextInputType.streetAddress, isRequired: true),
            const SizedBox(height: 15),
            IntlPhoneField(
              controller: _custPhoneController,
              decoration: InputDecoration(
                labelText: 'Customer Phone Number *',
                labelStyle: TextStyle(color: MyTheme.textColor),
                border: const OutlineInputBorder(
                  borderSide: BorderSide(),
                ),
                counterStyle: TextStyle(color: MyTheme.textColor),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.deny(RegExp(r'[^0-9]')),
              ],
              pickerDialogStyle: PickerDialogStyle(
                backgroundColor: MyTheme.cardBackground,
                searchFieldTextStyle: TextStyle(color: MyTheme.textColor),
                searchFieldInputDecoration: InputDecoration(
                  border: const UnderlineInputBorder(),
                  suffixIcon: Icon(
                    Icons.search,
                    color: MyTheme.textColor.withAlpha(150),
                  ),
                  labelText: "Search country",
                  labelStyle:
                      TextStyle(color: MyTheme.textColor.withAlpha(150)),
                ),
                countryNameStyle: TextStyle(color: MyTheme.textColor),
                countryCodeStyle: TextStyle(
                    color: MyTheme.textColor.withAlpha(150), fontSize: 14),
              ),
              languageCode: "en",
              initialCountryCode: number.countryISOCode.isNotEmpty
                  ? number.countryISOCode
                  : 'IN',
              style: TextStyle(color: MyTheme.textColor),
              dropdownTextStyle: TextStyle(color: MyTheme.textColor),
              onChanged: (phone) {
                number = phone;
              },
            ),
            const SizedBox(height: 15),
            _buildTextField(_custEmailController, 'Customer Email',
                keyboardType: TextInputType.emailAddress, isRequired: false),
            const SizedBox(height: 40),
            customButton(
              label: 'Preview Invoice',
              onTap: () {
                // Generate and preview invoice
                _previewInvoice(context);
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
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: labelText + (isRequired ? ' *' : ''),
        labelStyle: TextStyle(color: MyTheme.textColor),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey)),
      ),
      keyboardType: keyboardType,
      style: TextStyle(color: MyTheme.textColor),
    );
  }

  Future<void> _previewInvoice(BuildContext context) async {
    // Validate fields
    if (_custNameController.text.isEmpty ||
        _custAddressController.text.isEmpty ||
        number.number.isEmpty) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: MyTheme.cardBackground,
            title: Text(
              'Error',
              style: TextStyle(
                color: MyTheme.accent,
                fontWeight: FontWeight.bold,
              ),
            ),
            content: Text(
              'Please fill in all required fields.',
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
    } else {
      try {
        if (number.number.isNotEmpty && !number.isValidNumber()) {
          throw Exception();
        }
      } on Exception {
        showSnackBar(context, "Invalid Mobile Number.");
        return;
      }

      // Validate email
      final RegExp emailRegex =
          RegExp(r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
      if (_custEmailController.text.isNotEmpty &&
          !emailRegex.hasMatch(_custEmailController.text)) {
        showSnackBar(context, "Invalid Email.");
        return;
      }

      // Generate and preview invoice
      String pdfPath =
          await generateInvoicePdf(widget.invoiceItems, widget.totalAmount);
      if (pdfPath.isNotEmpty) {
        // Navigate to PDF preview screen
        await Get.to(() => PDFPreviewScreen(
            pdfPath: pdfPath,
            whatsappNo: number.completeNumber,
            invoiceData: invoiceData!));
      } else {
        // Show error message if PDF generation fails
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: MyTheme.cardBackground,
              title: Text(
                'Error',
                style: TextStyle(
                  color: MyTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Failed to generate invoice PDF.',
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
  }

  Future<String> generateInvoicePdf(
      Map<String, dynamic> invoiceItems, double totalAmount) async {
    List<dynamic> invoiceItemsList = invoiceItems.values.toList();
    invoiceItemsList.sort((a, b) => b[6].compareTo(a[6]));
    invoiceItemsList = invoiceItemsList
        .map((item) => [
              item[2].toString(),
              item[5].toString(),
              item[3].toStringAsFixed(2),
              item[6].toStringAsFixed(2),
              item[1].toString()
            ])
        .toList();

    double discount = 50.0;
    double discountLessTotal = totalAmount - discount;
    double taxRatePercent = 12.0;
    double taxOnTotal = (taxRatePercent * discountLessTotal) / 100;
    double finalTotal = discountLessTotal + taxOnTotal;

    String generateInvoiceNumber() {
      DateTime timestamp = DateTime.now();
      String id = GetStorage().read('id').toString();
      String year = timestamp.year.toString().padLeft(4, '0');
      String month = timestamp.month.toString().padLeft(2, '0');
      String day = timestamp.day.toString().padLeft(2, '0');
      String hour = timestamp.hour.toString().padLeft(2, '0');
      String minute = timestamp.minute.toString().padLeft(2, '0');
      String second = timestamp.second.toString().padLeft(2, '0');
      return 'INV$id$year$month$day$hour$minute$second';
    }

    String invoiceNo = generateInvoiceNumber();

    String invoiceDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String dueDate = DateFormat('dd/MM/yyyy')
        .format(DateTime.now().add(const Duration(days: 20)));

    GetStorage box = GetStorage();
    String shopName = box.read("shopName") ?? "";
    String shopAddress = box.read("shopAddress") ?? "";
    String shopEmail = box.read("shopEmail") ?? "";
    String shopWebLink = box.read("shopWebsite") ?? "";
    String shopPhone = box.read("shopPhone") ?? "";
    String shopGSTNo = box.read("shopGSTNo") ?? "";
    String shopTerms = box.read("shopTerms") ?? "";

    if (shopName.isEmpty || shopAddress.isEmpty) {
      showSnackBar(context, "Shop Name and Shop Address are required.");
      return "";
    }

    if (shopGSTNo.trim() != "") {
      shopGSTNo = "GST No :  $shopGSTNo";
    }

    String custName = _custNameController.text.trim();
    String custAddress = _custAddressController.text.trim();
    String custPhone = number.completeNumber.contains('+')
        ? number.completeNumber
        : '+${number.completeNumber}';
    String custEmail = _custEmailController.text.trim();

    invoiceData = {
      'invoice_no': invoiceNo,
      'shop_id': GetStorage().read("id").toString(),
      'shop_name': shopName,
      'shop_address': shopAddress,
      'shop_email': shopEmail,
      'shop_phone': shopPhone,
      'shop_gst_no': shopGSTNo,
      'cust_name': custName,
      'cust_address': custAddress,
      'cust_phone': custPhone,
      'cust_email': custEmail,
      'invoice_date': DateFormat('yyyy-MM-dd').format(DateTime.now()),
      'due_date': DateFormat('yyyy-MM-dd')
          .format(DateTime.now().add(const Duration(days: 20))),
      'subtotal': widget.totalAmount,
      'discount': discount,
      'tax_rate': taxRatePercent,
      'total_amount': finalTotal,
      'products': invoiceItemsList,
    };

    final pdf = pw.Document(
        title: 'Invoice', author: 'InvocifyPro', creator: "InvocifyPro");

    PdfImage? logoImage;

    Uint8List? logobytes;
    try {
      logobytes = File(
              '${(await getApplicationDocumentsDirectory()).path}/shop_logo_user.png')
          .readAsBytesSync();
    } catch (e) {
      // logobytes = null;
      ByteData bytes =
          await rootBundle.load('assets/images/invoice/shop_logo.png');
      logobytes = bytes.buffer.asUint8List();
    }

    try {
      logoImage = PdfImage.file(
        pdf.document,
        bytes: logobytes,
      );
    } catch (error) {
      print("Shop logo load error : $error");
      logobytes = null;
      logoImage = null;
    }

    int rowindex = -1;
    double maxwidth = 280;

    final invoice = [
      pw.Column(
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(shopName,
                        style: const pw.TextStyle(fontSize: 24)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(shopAddress),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(shopEmail),
                  ),
                  shopEmail.isNotEmpty ? pw.SizedBox(height: 8) : pw.SizedBox(),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(shopPhone),
                  ),
                  shopPhone.isNotEmpty ? pw.SizedBox(height: 8) : pw.SizedBox(),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(shopWebLink),
                  ),
                  shopWebLink.isNotEmpty
                      ? pw.SizedBox(height: 8)
                      : pw.SizedBox(),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(shopGSTNo),
                  ),
                  pw.SizedBox(height: 40),
                  pw.Text('BILL TO', style: const pw.TextStyle(fontSize: 16)),
                  pw.SizedBox(height: 5),
                  pw.Container(
                      color: PdfColors.grey, height: 2, width: maxwidth),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(custName),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(custAddress),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(custPhone),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(custEmail),
                  ),
                  pw.SizedBox(height: 30),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('INVOICE', style: const pw.TextStyle(fontSize: 24)),
                  pw.SizedBox(height: 15),
                  pw.Container(
                    height: 100,
                    width: 100,
                    child: logobytes != null && logoImage != null
                        ? pw.Image(pw.ImageProxy(logoImage))
                        : pw.Container(),
                  ),
                  pw.SizedBox(height: 15),
                  pw.Row(
                    children: [
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('Invoice No:'),
                            pw.SizedBox(height: 18),
                            pw.Text('Invoice Date:'),
                            pw.SizedBox(height: 5),
                            pw.Text('Due Date:'),
                            pw.SizedBox(height: 10),
                          ]),
                      pw.SizedBox(width: 10),
                      pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              constraints:
                                  const pw.BoxConstraints(maxWidth: 100),
                              child: pw.Text(invoiceNo),
                            ),
                            pw.SizedBox(height: 5),
                            pw.Text(invoiceDate),
                            pw.SizedBox(height: 5),
                            pw.Text(dueDate),
                            pw.SizedBox(height: 10),
                          ]),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      pw.Table(
        border: pw.TableBorder.all(),
        tableWidth: pw.TableWidth.max,
        children: [
          pw.TableRow(
            repeat: true,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                alignment: pw.Alignment.center,
                child: pw.Text('Description'),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                alignment: pw.Alignment.center,
                child: pw.Text('Quantity'),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                alignment: pw.Alignment.center,
                child: pw.Text('Selling Price'),
              ),
              pw.Container(
                padding: const pw.EdgeInsets.all(5),
                alignment: pw.Alignment.center,
                child: pw.Text('Total'),
              ),
            ],
          ),
          // for (int line = 0; line < 9; line++)
          ...invoiceItemsList.map(
            (item) {
              rowindex++;
              return pw.TableRow(
                decoration: rowindex.isEven
                    ? const pw.BoxDecoration(color: PdfColors.grey300)
                    : const pw.BoxDecoration(),
                children: [
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(item[0]),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.center,
                    child: pw.Text(item[1]),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(item[2]),
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.all(5),
                    alignment: pw.Alignment.centerRight,
                    child: pw.Text(item[3]),
                  ),
                ],
              );
            },
          ).toList(),
        ],
      ),
      pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
        pw.Column(children: [
          pw.Text('Thank you for your business!'),
        ]),
        pw.Column(children: [
          pw.Row(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.start,
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.SizedBox(height: 5),
                  pw.Padding(
                      child: pw.Text('SUBTOTAL'),
                      padding: const pw.EdgeInsets.only(right: 10)),
                  pw.SizedBox(height: 12),
                  pw.Padding(
                      child: pw.Text('DISCOUNT'),
                      padding: const pw.EdgeInsets.only(right: 10)),
                  pw.SizedBox(height: 12),
                  pw.Padding(
                      child: pw.Text('SUBTOTAL LESS DISCOUNT'),
                      padding: const pw.EdgeInsets.only(right: 10)),
                  pw.SizedBox(height: 12),
                  pw.Padding(
                      child: pw.Text('TAXRATE'),
                      padding: const pw.EdgeInsets.only(right: 10)),
                  pw.SizedBox(height: 12),
                  pw.Padding(
                      child: pw.Text('TOTAL TAX'),
                      padding: const pw.EdgeInsets.only(right: 10)),
                  pw.SizedBox(height: 5),
                  pw.Container(color: PdfColors.grey, height: 2, width: 100),
                  pw.SizedBox(height: 5),
                  pw.Padding(
                      child: pw.Text('Balance Due'),
                      padding: const pw.EdgeInsets.only(right: 10)),
                  pw.SizedBox(height: 10),
                ]),
            pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
              pw.SizedBox(height: 5),
              pw.Text(totalAmount.toStringAsFixed(2)),
              pw.SizedBox(height: 5),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 5),
              pw.Text(discount.toStringAsFixed(2)),
              pw.SizedBox(height: 5),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 5),
              pw.Text(discountLessTotal.toStringAsFixed(2)),
              pw.SizedBox(height: 5),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 5),
              pw.Text("${taxRatePercent.toStringAsFixed(2)}%"),
              pw.SizedBox(height: 5),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 5),
              pw.Text(taxOnTotal.toStringAsFixed(2)),
              pw.SizedBox(height: 5),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 5),
              pw.Text(finalTotal.toStringAsFixed(2)),
              pw.SizedBox(height: 10),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 10),
            ]),
          ]),
        ]),
      ]),
      pw.Expanded(child: pw.SizedBox()),
      pw.Column(
        mainAxisAlignment: pw.MainAxisAlignment.end,
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Terms & Conditions',
              style: const pw.TextStyle(fontSize: 16)),
          pw.SizedBox(height: 3),
          pw.Container(color: PdfColors.grey, height: 2, width: 300),
          pw.SizedBox(height: 3),
          pw.Text(shopTerms),
          pw.SizedBox(height: 15),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [pw.Text('Invoice generated by InvocifyPro')],
          ),
        ],
      ),
    ];

    pdf.addPage(
      pw.MultiPage(
          pageFormat: PdfPageFormat.a4, build: (pw.Context context) => invoice),
    );

    final directory = await getApplicationCacheDirectory();
    Directory appDocDir = await Directory('${directory.path}/invoiceifypro')
        .create(recursive: true);

    final file = File('${appDocDir.path}/invoice.pdf');
    // print('File path: ${appDocDir.path}/invoice.pdf');

    file.writeAsBytesSync(await pdf.save());

    // Printing.sharePdf(bytes: await file.readAsBytes(), filename: 'invoice.pdf');
    return '${appDocDir.path}/invoice.pdf';
  }

  // pw.Widget _contentTable(pw.Context context, List<dynamic> invoiceItemsList) {
  //   _contentTable(context, invoiceItemsList);

  //   const tableHeadersTitle = [
  //     'Description',
  //     'Quantity',
  //     'Selling Price',
  //     'Total'
  //   ];
  //   const tableHeadersIndex = [2, 5, 3, 6];

  //   return pw.TableHelper.fromTextArray(
  //     border: null,
  //     tableWidth: pw.TableWidth.max,
  //     cellAlignment: pw.Alignment.centerLeft,
  //     headerDecoration: const pw.BoxDecoration(
  //       borderRadius: pw.BorderRadius.all(pw.Radius.circular(2)),
  //       color: PdfColors.grey800,
  //     ),
  //     headerHeight: 25,
  //     cellHeight: 30,
  //     cellAlignments: {
  //       0: pw.Alignment.centerLeft,
  //       1: pw.Alignment.center,
  //       2: pw.Alignment.centerRight,
  //       3: pw.Alignment.centerRight,
  //     },
  //     headerStyle: pw.TextStyle(
  //       color: PdfColors.white,
  //       fontSize: 10,
  //       fontWeight: pw.FontWeight.bold,
  //     ),
  //     cellStyle: const pw.TextStyle(
  //       color: PdfColors.grey800,
  //       fontSize: 10,
  //     ),
  //     rowDecoration: const pw.BoxDecoration(
  //       border: pw.Border(
  //         bottom: pw.BorderSide(
  //           color: PdfColors.grey900,
  //           width: .5,
  //         ),
  //       ),
  //     ),
  //     headers: List<String>.generate(
  //       tableHeadersTitle.length,
  //       (col) => tableHeadersTitle[col],
  //     ),
  //     data: List<List<String>>.generate(
  //       invoiceItemsList.length * 30,
  //       (row) => List<String>.generate(
  //         tableHeadersIndex.length,
  //         (col) => invoiceItemsList[0][tableHeadersIndex[col]].toString(),
  //       ),
  //     ),
  //   );
  // }
}
