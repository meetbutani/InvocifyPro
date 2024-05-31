import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:http/http.dart' as http;
import 'package:invocifypro/models/invoice_model.dart';
import 'package:invocifypro/pages/pdf_preview_screen.dart';
import 'package:invocifypro/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class SavedInvoicesPage extends StatefulWidget {
  const SavedInvoicesPage({super.key});

  @override
  State<SavedInvoicesPage> createState() => _SavedInvoicesPageState();
}

class _SavedInvoicesPageState extends State<SavedInvoicesPage> {
  List<Invoice> invoices = [];
  List<Invoice> filteredInvoices = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    fetchInvoices();
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 75,
        backgroundColor: MyTheme.background,
        title: Padding(
          padding: const EdgeInsets.only(top: 10),
          child: TextField(
            controller: searchController,
            onTapOutside: (event) =>
                FocusManager.instance.primaryFocus?.unfocus(),
            style: TextStyle(color: MyTheme.textColor, fontSize: 16),
            decoration: InputDecoration(
              labelText: 'Search invoices...',
              labelStyle: TextStyle(color: MyTheme.textColor, fontSize: 16),
              alignLabelWithHint: true,
              border: const OutlineInputBorder(),
              focusedBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.grey),
              ),
            ),
            onChanged: (value) {
              if (value.trim().isEmpty || value.trim().length < 2) {
                _debounceTimer?.cancel();
                setState(() {
                  filteredInvoices = invoices;
                });
              } else {
                _debounceTimer?.cancel();

                _debounceTimer = Timer(const Duration(milliseconds: 1000), () {
                  filterInvoices(value);
                });
              }
            },
          ),
        ),
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       if (searchController.text.trim().isNotEmpty) {
        //         filterInvoices(searchController.text);
        //       } else {
        //         setState(() {
        //           filteredInvoices = invoices;
        //         });
        //       }
        //     },
        //     icon: Icon(
        //       Icons.search_rounded,
        //       color: MyTheme.accent,
        //       size: 30,
        //     ),
        //   ),
        //   const SizedBox(width: 10),
        // ],
      ),
      backgroundColor: MyTheme.background,
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchInvoices(),
              child: ListView.builder(
                itemCount: filteredInvoices.length,
                itemBuilder: (context, index) {
                  return Container(
                    child: Card(
                      color: MyTheme.cardBackground,
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: ListTile(
                        title: Text(
                          filteredInvoices[index].invoiceNo,
                          style: TextStyle(
                            color: MyTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              filteredInvoices[index].custName,
                              style: TextStyle(
                                color: MyTheme.textColor.withOpacity(.8),
                              ),
                            ),
                            Row(
                              children: [
                                Text(
                                  'Amount: ${filteredInvoices[index].totalAmount}',
                                  style: TextStyle(
                                    color: MyTheme.textColor.withOpacity(.8),
                                  ),
                                ),
                                const Expanded(child: SizedBox()),
                                const SizedBox(width: 10),
                                SizedBox(
                                  width: 115,
                                  child: Text(
                                    DateFormat('dd/MM/yyyy').format(
                                        filteredInvoices[index].invoiceDate),
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            // Include other invoice details here
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.print,
                            color: MyTheme.accent,
                          ),
                          onPressed: () async {
                            // Add a button to edit the invoice
                            Get.to(PDFPreviewScreen(
                              pdfPath: await generateInvoicePdf(
                                  filteredInvoices[index]),
                              whatsappNo: filteredInvoices[index].custPhone,
                            ));
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> fetchInvoices() async {
    EasyLoading.show(status: 'Please Wait ...');

    // Make HTTP request to fetch invoices
    var response = await http.get(Uri.parse(
        ApiConstants.getAllInvoicesUrl + GetStorage().read('id').toString()));

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      // Parse JSON response and update invoices list
      List<dynamic> data = json.decode(response.body)['invoices'];

      setState(() {
        invoices = data.map((json) => Invoice.fromJson(json)).toList();
        filteredInvoices = List.from(invoices);
      });
    } else {
      showSnackBar(context, json.decode(response.body)['message']);
      // Handle errors
      if (kDebugMode) {
        print('Failed to load invoices: ${response.reasonPhrase}');
      }
    }
  }

  void filterInvoices(String query) {
    if (kDebugMode) {
      print("filter called");
    }
    setState(() {
      filteredInvoices = invoices.where((invoice) {
        return invoice.invoiceNo
                .toLowerCase()
                .contains(query.trim().toLowerCase()) ||
            invoice.custName.toLowerCase().contains(query.trim().toLowerCase());
      }).toList();
      if (kDebugMode) {
        print(filteredInvoices.toString());
      }
    });
  }

  Future<String> generateInvoicePdf(Invoice invoiceData) async {
    if (kDebugMode) {
      print(invoiceData.products);
    }
    List<dynamic> invoiceItemsList = invoiceData.products;
    // invoiceItemsList.sort((a, b) => b[3].compareTo(a[3]));

    double discountLessTotal = invoiceData.totalAmount - invoiceData.discount;
    double taxOnTotal = (invoiceData.taxRate * discountLessTotal) / 100;
    double finalTotal = discountLessTotal + taxOnTotal;

    String invoiceDate =
        DateFormat('dd/MM/yyyy').format(invoiceData.invoiceDate);
    String dueDate = DateFormat('dd/MM/yyyy').format(invoiceData.dueDate);

    GetStorage box = GetStorage();
    String shopWebLink = box.read("shopWebsite") ?? "";
    String shopGSTNo = "";
    String shopTerms = box.read("shopTerms") ?? "";

    if (invoiceData.shopGstNo.trim() != "") {
      shopGSTNo = "GST No :  ${invoiceData.shopGstNo.trim()}";
    }

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
      if (kDebugMode) {
        print("Shop logo load error : $error");
      }
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
                    child: pw.Text(invoiceData.shopName,
                        style: const pw.TextStyle(fontSize: 24)),
                  ),
                  pw.SizedBox(height: 10),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(invoiceData.shopAddress),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(invoiceData.shopEmail),
                  ),
                  invoiceData.shopEmail.isNotEmpty
                      ? pw.SizedBox(height: 8)
                      : pw.SizedBox(),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(invoiceData.shopPhone),
                  ),
                  invoiceData.shopPhone.isNotEmpty
                      ? pw.SizedBox(height: 8)
                      : pw.SizedBox(),
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
                    child: pw.Text(invoiceData.custName),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(invoiceData.custAddress),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(invoiceData.custPhone),
                  ),
                  pw.SizedBox(height: 5),
                  pw.Container(
                    width: maxwidth,
                    child: pw.Text(invoiceData.custEmail),
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
                              child: pw.Text(invoiceData.invoiceNo),
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
              pw.Text(invoiceData.subtotal.toStringAsFixed(2)),
              pw.SizedBox(height: 5),
              pw.Container(
                  color: PdfColors.grey,
                  height: 2,
                  constraints: const pw.BoxConstraints(minWidth: 80)),
              pw.SizedBox(height: 5),
              pw.Text(invoiceData.discount.toStringAsFixed(2)),
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
              pw.Text("${invoiceData.taxRate.toStringAsFixed(2)}%"),
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
}
