import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_swipe_action_cell/flutter_swipe_action_cell.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/pages/customer_detail_page.dart';
import 'package:invocifypro/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:printing/printing.dart';
import 'package:scan/scan.dart';
import 'package:http/http.dart' as http;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class InvoiceGeneratorPage extends StatefulWidget {
  const InvoiceGeneratorPage({super.key});

  @override
  State<InvoiceGeneratorPage> createState() => _InvoiceGeneratorPageState();
}

class _InvoiceGeneratorPageState extends State<InvoiceGeneratorPage> {
  bool openScanner = false;
  ScanController controller = ScanController();
  RxBool isFlashOn = false.obs;
  bool _sheetOpened = true;
  late DraggableScrollableController dragSheetController =
      DraggableScrollableController();
  Timer timer = Timer(Duration.zero, () {});

  Map<String, dynamic> invoiceItems = <String, dynamic>{};
  List<dynamic> invoiceItemsList = [];
  List<dynamic> allProductList = [];

  double totalAmount = 0.0;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loadAllProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background,
      body: Column(
        children: [
          Expanded(
            child: Container(
              color: MyTheme.background,
              padding: const EdgeInsets.fromLTRB(0, 10, 0, 10),
              child: ListView.builder(
                itemCount: invoiceItemsList.length,
                itemBuilder: (context, index) {
                  return SwipeActionCell(
                    key: ObjectKey(invoiceItemsList[index][0]),
                    trailingActions: <SwipeAction>[
                      SwipeAction(
                          // title: "delete",
                          icon: const Icon(
                            Icons.delete,
                            color: Colors.white,
                            size: 32,
                          ),
                          onTap: (CompletionHandler handler) async {
                            /// await handler(true) : will delete this row
                            /// And after delete animation,setState will called to
                            /// sync your data source with your UI
                            await handler(true);

                            allProductList[invoiceItemsList[index][8]][3] =
                                (invoiceItemsList[index][4] +
                                    invoiceItemsList[index][5]);

                            totalAmount -= invoiceItemsList[index][6];

                            invoiceItems.remove(invoiceItemsList[index][1]);
                            invoiceItemsList.removeAt(index);
                            setState(() {});
                          },
                          color: Colors.red),
                    ],
                    backgroundColor: MyTheme.background,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 0, 10, 0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: 68,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    invoiceItemsList[index][2],
                                    // "Balaji sev murmura 60 gram",
                                    style: TextStyle(color: MyTheme.textColor),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        // "450.0 x ",
                                        "${invoiceItemsList[index][3]} x ",
                                        style:
                                            TextStyle(color: MyTheme.textColor),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          if (invoiceItemsList[index][5] == 1) {
                                            return;
                                          }
                                          setState(() {
                                            invoiceItemsList[index][5]--;
                                            invoiceItemsList[index][4]++;
                                            allProductList[
                                                    invoiceItemsList[index][8]]
                                                [3]++;
                                            invoiceItemsList[index][6] -=
                                                invoiceItemsList[index][3];

                                            totalAmount -=
                                                invoiceItemsList[index][3];

                                            invoiceItemsList[index][7].text =
                                                invoiceItemsList[index][5]
                                                    .toString();

                                            invoiceItems[invoiceItemsList[index]
                                                    [1]][5] =
                                                invoiceItemsList[index][5];
                                            invoiceItems[invoiceItemsList[index]
                                                    [1]][6] =
                                                invoiceItemsList[index][6];
                                          });
                                        },
                                        icon: Icon(
                                          Icons.remove_circle,
                                          color: MyTheme.accent,
                                        ),
                                      ),
                                      SizedBox(
                                        width: 40,
                                        child: TextField(
                                          controller: invoiceItemsList[index]
                                              [7],
                                          style: TextStyle(
                                              color: MyTheme.textColor),
                                          textAlign: TextAlign.center,
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                          ),
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly
                                          ],
                                          keyboardType: TextInputType.number,
                                          onTapOutside: (event) => FocusManager
                                              .instance.primaryFocus
                                              ?.unfocus(),
                                          onChanged: (data) {
                                            if (data == "0") {
                                              setState(() {
                                                allProductList[
                                                        invoiceItemsList[index]
                                                            [8]][3] =
                                                    (invoiceItemsList[index]
                                                                [4] +
                                                            invoiceItemsList[
                                                                index][5]) -
                                                        1;

                                                invoiceItemsList[index][4] =
                                                    (invoiceItemsList[index]
                                                                [4] +
                                                            invoiceItemsList[
                                                                index][5]) -
                                                        1;

                                                totalAmount -=
                                                    (invoiceItemsList[index]
                                                            [5] *
                                                        invoiceItemsList[index]
                                                            [3]);

                                                invoiceItemsList[index][5] = 1;
                                                invoiceItemsList[index][6] =
                                                    invoiceItemsList[index][3];

                                                invoiceItemsList[index][7]
                                                        .text =
                                                    invoiceItemsList[index][5]
                                                        .toString();

                                                invoiceItems[
                                                        invoiceItemsList[index]
                                                            [1]][4] =
                                                    invoiceItemsList[index][4];
                                                invoiceItems[
                                                        invoiceItemsList[index]
                                                            [1]][5] =
                                                    invoiceItemsList[index][5];
                                                invoiceItems[
                                                        invoiceItemsList[index]
                                                            [1]][6] =
                                                    invoiceItemsList[index][6];

                                                totalAmount +=
                                                    invoiceItemsList[index][6];
                                              });
                                            } else {
                                              setState(() {
                                                int newCurrentStock =
                                                    (invoiceItemsList[index]
                                                                [4] +
                                                            invoiceItemsList[
                                                                index][5]) -
                                                        (int.tryParse(data) ??
                                                            1);

                                                if (newCurrentStock >= 0 &&
                                                    newCurrentStock <=
                                                        (invoiceItemsList[index]
                                                                [4] +
                                                            invoiceItemsList[
                                                                index][5])) {
                                                  allProductList[
                                                          invoiceItemsList[
                                                              index][8]][3] =
                                                      newCurrentStock;
                                                  invoiceItemsList[index][4] =
                                                      newCurrentStock;

                                                  // data = newCurrentStock.toString();
                                                } else if (newCurrentStock <
                                                    0) {
                                                  allProductList[
                                                      invoiceItemsList[index]
                                                          [8]][3] = 0;

                                                  data =
                                                      (invoiceItemsList[index]
                                                                  [4] +
                                                              invoiceItemsList[
                                                                  index][5])
                                                          .toString();

                                                  invoiceItemsList[index][4] =
                                                      0;
                                                  showSnackBar(context,
                                                      "Only $data available.");
                                                } else {
                                                  allProductList[
                                                              invoiceItemsList[
                                                                      index]
                                                                  [8]]
                                                          [3] =
                                                      (invoiceItemsList[index]
                                                                  [4] +
                                                              invoiceItemsList[
                                                                  index][5]) -
                                                          1;

                                                  data = "1";

                                                  invoiceItemsList[index][4] =
                                                      (invoiceItemsList[index]
                                                                  [4] +
                                                              invoiceItemsList[
                                                                  index][5]) -
                                                          1;
                                                }

                                                totalAmount -=
                                                    (invoiceItemsList[index]
                                                            [5] *
                                                        invoiceItemsList[index]
                                                            [3]);

                                                invoiceItemsList[index][5] =
                                                    int.tryParse(data) ?? 1;
                                                invoiceItemsList[index][6] =
                                                    invoiceItemsList[index][5] *
                                                        invoiceItemsList[index]
                                                            [3];

                                                invoiceItemsList[index][7]
                                                        .text =
                                                    invoiceItemsList[index][5]
                                                        .toString();

                                                invoiceItems[
                                                        invoiceItemsList[index]
                                                            [1]][5] =
                                                    invoiceItemsList[index][5];
                                                invoiceItems[
                                                        invoiceItemsList[index]
                                                            [1]][6] =
                                                    invoiceItemsList[index][6];

                                                totalAmount +=
                                                    invoiceItemsList[index][6];
                                              });
                                            }

                                            // Set the cursor position to the end of the text
                                            invoiceItemsList[index][7]
                                                    .selection =
                                                TextSelection.collapsed(
                                                    offset:
                                                        invoiceItemsList[index]
                                                                [7]
                                                            .text
                                                            .length);
                                            // TextSelection(
                                            //     baseOffset: 0,
                                            //     extentOffset:
                                            //         invoiceItemsList[index][7]
                                            //             .text
                                            //             .length);
                                          },
                                          onTap: () {
                                            dragSheetController.animateTo(
                                              0,
                                              duration: const Duration(
                                                  milliseconds: 500),
                                              curve: Curves.ease,
                                            );
                                          },
                                        ),
                                      ),
                                      IconButton(
                                        onPressed: () {
                                          if (invoiceItemsList[index][4] == 0) {
                                            return;
                                          }
                                          setState(() {
                                            invoiceItemsList[index][5]++;
                                            invoiceItemsList[index][4]--;
                                            allProductList[
                                                    invoiceItemsList[index][8]]
                                                [3]--;

                                            invoiceItemsList[index][6] +=
                                                invoiceItemsList[index][3];

                                            totalAmount +=
                                                invoiceItemsList[index][3];

                                            invoiceItemsList[index][7].text =
                                                invoiceItemsList[index][5]
                                                    .toString();

                                            invoiceItems[invoiceItemsList[index]
                                                    [1]][5] =
                                                invoiceItemsList[index][5];
                                            invoiceItems[invoiceItemsList[index]
                                                    [1]][6] =
                                                invoiceItemsList[index][6];
                                          });
                                        },
                                        icon: Icon(
                                          Icons.add_circle,
                                          color: MyTheme.accent,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Text(
                            "+${invoiceItemsList[index][6]}",
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          Container(
            constraints: const BoxConstraints(maxHeight: 450),
            child: NotificationListener<DraggableScrollableNotification>(
              onNotification: (DSNotification) {
                if (DSNotification.extent == 1.0) {
                  setState(() {
                    _sheetOpened = true;
                  });
                } else {
                  setState(() {
                    _sheetOpened = false;
                  });
                }
                return true;
              },
              child: DraggableScrollableSheet(
                initialChildSize: 1,
                // snapAnimationDuration: Duration(milliseconds: 1),
                controller: dragSheetController,
                expand: false,
                snap: true,
                minChildSize: 0.1,
                builder: (context, scrollController) {
                  // print(scrollController.position);
                  return Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      SingleChildScrollView(
                        controller: scrollController,
                        child: Container(
                          color: MyTheme.cardBackground,
                          // constraints: const BoxConstraints(minHeight: 48),
                          child: invoiceItemsList.isNotEmpty
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.center,
                                  children: [
                                    TextButton(
                                      onPressed: () {
                                        clearOrder(context);
                                      },
                                      style: TextButton.styleFrom(),
                                      child: const Text(
                                        "Clear Order",
                                        style: TextStyle(color: Colors.red),
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.fromLTRB(
                                          15, 0, 15, 0),
                                      child: Row(
                                        children: [
                                          Text(
                                            "Items : ",
                                            style: TextStyle(
                                                color: MyTheme.textColor),
                                          ),
                                          Text(
                                            "${invoiceItemsList.length}",
                                            style: TextStyle(
                                                color: MyTheme.accent),
                                          ),
                                        ],
                                      ),
                                    )
                                  ],
                                )
                              : const SizedBox(
                                  height: 48,
                                  width: double.infinity,
                                ),
                        ),
                      ),
                      openScanner
                          ? Container(
                              margin: const EdgeInsets.only(top: 48),
                              child: Scaffold(
                                appBar: _buildBarcodeScannerAppBar(),
                                body: _sheetOpened
                                    ? _buildBarcodeScannerBody()
                                    : Container(color: MyTheme.cardBackground),
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.only(top: 48),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: RefreshIndicator(
                                      onRefresh: () async {
                                        if (allProductList.isEmpty) {
                                          loadAllProducts();
                                        }
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5),
                                        child: GridView.builder(
                                            itemCount: allProductList.length,
                                            gridDelegate:
                                                const SliverGridDelegateWithFixedCrossAxisCount(
                                              mainAxisExtent: 92,
                                              crossAxisCount: 2,
                                            ),
                                            itemBuilder: (context, index) {
                                              return Card(
                                                color: MyTheme.cardBackground,
                                                child: ElevatedButton(
                                                  onPressed: () {
                                                    var product =
                                                        allProductList[index];
                                                    if (invoiceItems[
                                                            product[0]] !=
                                                        null) {
                                                      if (allProductList[index]
                                                              [3] >
                                                          0) {
                                                        allProductList[index]
                                                            [3]--;
                                                      } else {
                                                        showSnackBar(context,
                                                            "Stock is 0.");
                                                        // showSnackBar(context,
                                                        //     "Stock is 0 but added in bill.");
                                                        return;
                                                      }

                                                      invoiceItems[product[0]]
                                                          [0] = DateTime
                                                              .now()
                                                          .millisecondsSinceEpoch;
                                                      invoiceItems[product[0]]
                                                          [5]++;
                                                      invoiceItems[product[0]]
                                                          [4]--;
                                                      invoiceItems[product[0]]
                                                              [6] +=
                                                          invoiceItems[
                                                              product[0]][3];

                                                      totalAmount +=
                                                          invoiceItems[
                                                              product[0]][3];

                                                      invoiceItems[product[0]]
                                                              [7]
                                                          .text = invoiceItems[
                                                              product[0]][5]
                                                          .toString();

                                                      setState(() {
                                                        invoiceItemsList =
                                                            invoiceItems.values
                                                                .toList();
                                                        invoiceItemsList.sort(
                                                            (a, b) => b[0]
                                                                .compareTo(
                                                                    a[0]));
                                                      });
                                                      return;
                                                    }

                                                    if (allProductList[index]
                                                            [3] >
                                                        0) {
                                                      allProductList[index]
                                                          [3]--;
                                                    } else {
                                                      showSnackBar(context,
                                                          "Stock is 0.");
                                                      // showSnackBar(context,
                                                      //     "Stock is 0 but added in bill.");
                                                      return;
                                                    }

                                                    invoiceItems.addAll({
                                                      // DateTime.now().millisecond: [
                                                      product[0].toString(): [
                                                        DateTime.now()
                                                            .millisecondsSinceEpoch,
                                                        product[0],
                                                        product[1],
                                                        double.tryParse(
                                                            product[2]),
                                                        product[3],
                                                        1,
                                                        double.tryParse(
                                                            product[2]),
                                                        TextEditingController(
                                                            text: "1"),
                                                        index
                                                      ]
                                                    });

                                                    totalAmount +=
                                                        double.tryParse(
                                                                product[2]) ??
                                                            0;

                                                    setState(() {
                                                      invoiceItemsList =
                                                          invoiceItems.values
                                                              .toList();
                                                      invoiceItemsList.sort((a,
                                                              b) =>
                                                          b[0].compareTo(a[0]));
                                                    });
                                                  },
                                                  style:
                                                      ElevatedButton.styleFrom(
                                                          backgroundColor: MyTheme
                                                              .cardBackground,
                                                          shape:
                                                              RoundedRectangleBorder(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        10),
                                                          ),
                                                          // ignore: prefer_const_constructors
                                                          padding:
                                                              const EdgeInsets
                                                                  .symmetric(
                                                                  horizontal:
                                                                      15,
                                                                  vertical: 8)),
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      SizedBox(
                                                        height: 48,
                                                        child: Text(
                                                          allProductList[index]
                                                              [1],
                                                          maxLines: 2,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                          style: TextStyle(
                                                              color: MyTheme
                                                                  .textColor),
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Text(
                                                            allProductList[
                                                                index][2],
                                                            style: TextStyle(
                                                                color: MyTheme
                                                                    .accent),
                                                          ),
                                                          Text(
                                                            allProductList[
                                                                    index][3]
                                                                .toString(),
                                                            style:
                                                                const TextStyle(
                                                                    color: Colors
                                                                        .green),
                                                          )
                                                        ],
                                                      )
                                                    ],
                                                  ),
                                                ),
                                              );
                                            }),
                                      ),
                                    ),
                                  ),
                                  // Column(
                                  //   children: [
                                  //     const SizedBox(height: 10),
                                  //     IconButton(
                                  //       onPressed: () {},
                                  //       icon: Icon(
                                  //         Icons.search,
                                  //         color: MyTheme.accent,
                                  //         size: 32,
                                  //       ),
                                  //     ),
                                  //     const SizedBox(height: 10),
                                  //     IconButton(
                                  //       onPressed: () {},
                                  //       icon: Icon(
                                  //         Icons.add,
                                  //         color: MyTheme.accent,
                                  //         size: 32,
                                  //       ),
                                  //     ),
                                  //   ],
                                  // )
                                ],
                              ),
                            ),
                      Container(
                        margin: const EdgeInsets.only(top: 22),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        width: 40,
                        height: 4,
                      ),
                      // TextField(
                      //   // controller: controller,
                      //   onTapOutside: (event) =>
                      //       FocusManager.instance.primaryFocus?.unfocus(),
                      //   decoration: InputDecoration(
                      //     labelText: "Search item",
                      //     labelStyle: TextStyle(color: MyTheme.textColor),
                      //     border: const OutlineInputBorder(),
                      //     focusedBorder: const OutlineInputBorder(
                      //         borderSide: BorderSide(color: Colors.grey)),
                      //   ),
                      //   style: TextStyle(color: MyTheme.textColor),
                      // ),
                    ],
                  );
                },
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 4, 8),
                  child: IconButton(
                    onPressed: () {
                      timer.cancel();
                      setState(() {
                        openScanner = !openScanner;
                      });
                    },
                    style: IconButton.styleFrom(
                      side: BorderSide(color: MyTheme.cardBackground, width: 3),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    icon: Icon(
                      openScanner ? Icons.menu : Icons.qr_code_scanner,
                      size: 38,
                      color: MyTheme.accent,
                    ),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(4, 0, 8, 0),
                  child: ElevatedButton(
                    onPressed: () {
                      if (invoiceItems.isNotEmpty) {
                        // generateInvoicePdf(invoiceItems, totalAmount);
                        Get.to(CustomerDetailPage(invoiceItems, totalAmount));
                      } else {
                        showSnackBar(context, "Add Items to generate invoice.");
                      }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 0),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10))),
                    child: Row(
                      children: [
                        Expanded(
                          child: Center(
                            child: SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Text(
                                // "0.0",
                                totalAmount.toStringAsFixed(2),
                                maxLines: 1,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 30,
                                  height: 1.8,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(
                          width: 5,
                        ),
                        Text(
                          "Bill",
                          style:
                              TextStyle(color: MyTheme.textColor, fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  AppBar _buildBarcodeScannerAppBar() {
    return AppBar(
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(4),
        child: Container(color: MyTheme.accent, height: 4.0),
      ),
      title: GestureDetector(
        onTap: () {
          controller.pause();
          controller.resume();
        },
        child: Text(
          'Scan Product Barcode',
          style: TextStyle(color: MyTheme.textColor),
        ),
      ),
      elevation: 0.0,
      backgroundColor: MyTheme.cardBackground,
      // leading: GestureDetector(
      //   onTap: () {
      //     // Get.back();
      //   },
      //   child: Center(
      //     child: Icon(
      //       Icons.cancel,
      //       color: MyTheme.accent,
      //     ),
      //   ),
      // ),
      actions: [
        Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.only(right: 16.0),
          child: GestureDetector(
            onTap: () {
              isFlashOn.value = !isFlashOn.value;
              controller.toggleTorchMode();
            },
            child: Obx(
              () => Icon(
                isFlashOn.value ? Icons.flashlight_off : Icons.flashlight_on,
                color: MyTheme.accent,
                size: 28,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBarcodeScannerBody() {
    timer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (kDebugMode) {
        print("timer created");
      }
      timer.cancel();
      controller.pause();
      controller.resume();
    });
    return ScanView(
      controller: controller,
      scanAreaScale: .7,
      scanLineColor: MyTheme.accent,
      onCapture: (data) async {
        if (kDebugMode) {
          print("Product QR: $data");
        }
        // Timer(const Duration(milliseconds: 1500), () {
        //   controller.resume();
        // });
        if (timer.isActive) {
          if (kDebugMode) {
            print("timer cancel");
          }
          timer.cancel();
        }

        if (invoiceItems[data] != null) {
          if (invoiceItems[data][4] > 0) {
            invoiceItems[data][4]--;
          } else {
            showSnackBar(context, "Stock is 0.");
            // showSnackBar(context,
            //     "Stock is 0 but added in bill.");
            setState(() {});
            return;
          }

          allProductList[invoiceItems[data][8]][3]--;

          invoiceItems[data][0] = DateTime.now().millisecondsSinceEpoch;
          invoiceItems[data][5]++;
          invoiceItems[data][6] += invoiceItems[data][3];

          totalAmount += invoiceItems[data][3];

          invoiceItems[data][7].text = invoiceItems[data][5].toString();

          setState(() {
            invoiceItemsList = invoiceItems.values.toList();
            invoiceItemsList.sort((a, b) => b[0].compareTo(a[0]));
          });
          return;
        }

        try {
          EasyLoading.show(status: 'Please Wait ...');

          // Check if the QR code already exists
          var productData = await http.post(
            Uri.parse(ApiConstants.getProductDataUrl),
            headers: {
              'Content-Type': 'application/json',
            },
            body: json.encode(
                {'qrCode': data, 'userid': await GetStorage().read("id")}),
          );

          var qrCodeData = json.decode(productData.body);
          if (productData.statusCode == 200) {
            showSnackBar(context, qrCodeData["message"]);
            if (qrCodeData['exists']) {
              // print("qrCodeData $qrCodeData");
              if (qrCodeData["data"]["currentStock"] > 0) {
                qrCodeData["data"]["currentStock"]--;
              } else {
                showSnackBar(context, "Stock is 0.");
                // showSnackBar(context,
                //     "Stock is 0 but added in bill.");
                setState(() {});
                EasyLoading.dismiss();
                return;
              }

              int indexFromAllProducts = allProductList.indexWhere(
                  (product) => product[0] == qrCodeData["data"]["qrCode"]);

              allProductList[indexFromAllProducts][3]--;

              invoiceItems.addAll({
                // DateTime.now().millisecond: [
                qrCodeData["data"]["qrCode"]: [
                  DateTime.now().millisecondsSinceEpoch,
                  qrCodeData["data"]["qrCode"],
                  qrCodeData["data"]["productName"],
                  double.tryParse(qrCodeData["data"]["sellingPrice"]),
                  qrCodeData["data"]["currentStock"],
                  1,
                  double.tryParse(qrCodeData["data"]["sellingPrice"]),
                  TextEditingController(text: "1"),
                  indexFromAllProducts
                ]
              });

              totalAmount +=
                  double.tryParse(qrCodeData["data"]["sellingPrice"]) ?? 0;

              setState(() {
                invoiceItemsList = invoiceItems.values.toList();
                invoiceItemsList.sort((a, b) => b[0].compareTo(a[0]));
              });
            } else {
              setState(() {});
            }
          } else {
            // Handle errors
            setState(() {});
            showSnackBar(context, qrCodeData["message"]);
            if (kDebugMode) {
              print('Error checking QR Code: ${productData.reasonPhrase}');
            }
          }
          EasyLoading.dismiss();
          return;
        } catch (error) {
          EasyLoading.dismiss();
          if (kDebugMode) {
            print("Error occur: $error");
          }
          showSnackBar(
            context,
            "An error occurred. Please check your internet connection and try again.",
          );
        }

        if (kDebugMode) {
          print("timer reset.");
        }

        timer = Timer.periodic(const Duration(seconds: 5), (_) {
          controller.pause();
          controller.resume();
        });
        // setState(() {});
      },
    );
  }

  Future<void> loadAllProducts() async {
    allProductList.clear();
    try {
      EasyLoading.show(status: 'Please Wait ...');

      // Check if the QR code already exists
      var allProductData = await http.post(
        Uri.parse(ApiConstants.getAllProductDataUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({'userid': await GetStorage().read("id")}),
      );

      var productsData = json.decode(allProductData.body);
      // print(productsData["data"]);
      if (allProductData.statusCode == 200) {
        if (productsData['exists']) {
          showSnackBar(context, productsData["message"], isError: false);
          for (var product in productsData["data"]) {
            allProductList.add([
              product["qrCode"],
              product["productName"],
              product["sellingPrice"],
              product["currentStock"]
            ]);
          }
          setState(() {});
        } else {
          showSnackBar(context, productsData["message"]);
        }
      } else {
        // Handle errors
        showSnackBar(context, productsData["message"]);
        if (kDebugMode) {
          print('Error getting products: ${allProductData.reasonPhrase}');
        }
      }
      EasyLoading.dismiss();
      return;
    } catch (error) {
      EasyLoading.dismiss();
      if (kDebugMode) {
        print("Error occur: $error");
      }
      showSnackBar(
        context,
        "An error occurred. Please check your internet connection and try again.",
      );
    }
  }

  void clearOrder(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: MyTheme.cardBackground,
          title: Text(
            'Confirm Clear Order',
            style: TextStyle(
              color: MyTheme.accent,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to clear the order and map?',
            style: TextStyle(color: MyTheme.textColor),
          ),
          actions: [
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
              onPressed: () {
                invoiceItems.clear();
                invoiceItemsList.clear();
                totalAmount = 0.0;
                loadAllProducts();
                Get.back();
              },
              child: const Text('Clear Order',
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> generateInvoicePdf(
      Map<String, dynamic> invoiceItems, double totalAmount) async {
    List<dynamic> invoiceItemsList = invoiceItems.values.toList();
    invoiceItemsList.sort((a, b) => b[6].compareTo(a[6]));

    double discount = 50.0;
    double discountLessTotal = totalAmount - discount;
    double taxRatePercent = 12.0;
    double taxOnTotal = (taxRatePercent * discountLessTotal) / 100;
    double finalTotal = discountLessTotal + taxOnTotal;

    String invoiceNo = '#INV02081';
    String invoiceDate = DateFormat('dd/MM/yyyy').format(DateTime.now());
    String dueDate = DateFormat('dd/MM/yyyy')
        .format(DateTime.now().add(const Duration(days: 20)));

    // String shopName = 'InvocifyPro Pvt Limited';
    // String shopAddress =
    //     'G-3, Vishala west, Kathawada GIDC, Ahmedabad, gujarat, India - 382350';
    // String shopEmail = 'support@invocifypro.com';
    // String shopWebLink = 'www.invocifypro.com';
    // String shopPhone = '+91 93270 52373';
    // String shopGSTNo = '8598ZA47SDRG45Z';

    GetStorage box = GetStorage();
    String shopName = box.read("shopName") ?? "";
    String shopAddress = box.read("shopAddress") ?? "";
    String shopEmail = box.read("shopEmail") ?? " ";
    String shopWebLink = box.read("shopWebsite") ?? " ";
    String shopPhone = box.read("shopPhone") ?? " ";
    String shopGSTNo = box.read("shopGSTNo") ?? " ";

    if (shopName.isEmpty || shopAddress.isEmpty) {
      showSnackBar(context, "Shop Name and Shop Address are required.");
      return;
    }

    if (shopGSTNo == " ") {
      shopGSTNo = "GST No :  $shopGSTNo";
    }

    String custName = 'Meet Butani';
    String custAddress =
        'E-301 Miramanan Residency, nikol, Ahmedabad, Gujarat, India - 382350';
    String custPhone = '+91 93270 52373';
    String custEmail = 'meet.butani2702@gmail.com';

    List<String> termsIntructions = [
      'Please pay within 20 days by UPI (bob@invocifypro)',
      'purchased products have 5 year warranty.',
    ];

    final pdf = pw.Document(creator: "InvocifyPro");

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

    // ByteData bytes =
    //     await rootBundle.load('assets/images/invoice/shop_logo.png');
    // Uint8List? logobytes = bytes.buffer.asUint8List();

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

    final invoice = pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
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
                      width: 300,
                      child: pw.Text(shopName,
                          style: const pw.TextStyle(fontSize: 24)),
                    ),
                    pw.SizedBox(height: 10),
                    pw.Container(
                      width: 300,
                      child: pw.Text(shopAddress),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: 300,
                      child: pw.Text(shopEmail),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: 300,
                      child: pw.Text(shopWebLink),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: 300,
                      child: pw.Text(shopPhone),
                    ),
                    pw.SizedBox(height: 8),
                    pw.Container(
                      width: 300,
                      child: pw.Text(shopGSTNo),
                    ),
                    pw.SizedBox(height: 40),
                    pw.Text('BILL TO', style: const pw.TextStyle(fontSize: 16)),
                    pw.SizedBox(height: 5),
                    // pw.Expanded(
                    //   child:
                    pw.Container(color: PdfColors.grey, height: 2, width: 250),
                    // ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 300,
                      child: pw.Text(custName),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 300,
                      child: pw.Text(custAddress),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 300,
                      child: pw.Text(custPhone),
                    ),
                    pw.SizedBox(height: 5),
                    pw.Container(
                      width: 300,
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
                              pw.SizedBox(height: 5),
                              pw.Text('Invoice Date:'),
                              pw.SizedBox(height: 5),
                              pw.Text('Due Date:'),
                              pw.SizedBox(height: 10),
                            ]),
                        pw.SizedBox(width: 10),
                        pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text(invoiceNo),
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
                      child: pw.Text(item[2]),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      alignment: pw.Alignment.center,
                      child: pw.Text(item[5].toString()),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(item[3].toStringAsFixed(2)),
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(5),
                      alignment: pw.Alignment.centerRight,
                      child: pw.Text(item[6].toStringAsFixed(2)),
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
              pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
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
        pw.Expanded(
          // flex: 1,
          child: pw.Column(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Terms & Instructions',
                  style: const pw.TextStyle(fontSize: 16)),
              pw.SizedBox(height: 3),
              pw.Container(color: PdfColors.grey, height: 2, width: 300),
              pw.SizedBox(height: 3),
              pw.Text(termsIntructions[0]),
              pw.SizedBox(height: 5),
              pw.Text(termsIntructions[1]),
              pw.SizedBox(height: 15),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [pw.Text('Invoice generated by InvocifyPro')],
              ),
            ],
          ),
        ),
      ],
    );

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return invoice;
        },
      ),
    );

    final directory = await getApplicationCacheDirectory();
    Directory appDocDir = await Directory('${directory.path}/invoiceifypro')
        .create(recursive: true);

    final file = File('${appDocDir.path}/invoice.pdf');
    if (kDebugMode) {
      print('File path: ${appDocDir.path}/invoice.pdf');
    }

    await file.writeAsBytes(await pdf.save());

    Printing.sharePdf(bytes: await file.readAsBytes(), filename: 'invoice.pdf');
  }

  // Future<void> generateInvoicePdf(Map<String, dynamic> invoiceItems) async {
  //   final pdf = pw.Document();

  //   pdf.addPage(
  //     pw.Page(
  //       build: (pw.Context context) {
  //         return pw.Column(
  //           children: [
  //             pw.Text('Invoice', style: pw.TextStyle(fontSize: 24)),
  //             pw.SizedBox(height: 20),
  //             pw.Table(
  //               children: [
  //                 pw.TableRow(
  //                   children: [
  //                     pw.Text('Product Name'),
  //                     pw.Text('QR Code'),
  //                     pw.Text('Selling Price'),
  //                     pw.Text('Current Stock'),
  //                     pw.Text('Quantity'),
  //                     pw.Text('Total'),
  //                   ],
  //                 ),
  //                 ...invoiceItems.values.map(
  //                   (item) {
  //                     return pw.TableRow(
  //                       children: [
  //                         pw.Text(item[2]),
  //                         pw.Text(item[1].toString()),
  //                         pw.Text(item[3].toString()),
  //                         pw.Text(item[4].toString()),
  //                         pw.Text(item[5].toString()),
  //                         pw.Text(item[6].toString()),
  //                       ],
  //                     );
  //                   },
  //                 ).toList(),
  //               ],
  //             ),
  //           ],
  //         );
  //       },
  //     ),
  //   );

  //   final directory = await getApplicationDocumentsDirectory();
  //   final file = File('${directory.path}/invoice.pdf');

  //   await file.writeAsBytes(await pdf.save());

  //   Printing.sharePdf(bytes: await file.readAsBytes(), filename: 'invoice.pdf');
  // }
}
