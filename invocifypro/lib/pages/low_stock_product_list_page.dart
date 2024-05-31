import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/models/product_model.dart';
import 'package:invocifypro/pages/edit_product_page.dart';
import 'package:invocifypro/theme.dart';
import 'package:scan/scan.dart';
import 'package:http/http.dart' as http;

class LowStockProductsListPage extends StatefulWidget {
  const LowStockProductsListPage({super.key});

  @override
  State<LowStockProductsListPage> createState() =>
      _LowStockProductsListPageState();
}

class _LowStockProductsListPageState extends State<LowStockProductsListPage> {
  List<Product> products = [];
  List<Product> filteredProducts = [];
  TextEditingController searchController = TextEditingController();
  Timer? _debounceTimer;

  ScanController controller = ScanController();
  RxBool isFlashOn = false.obs;

  @override
  void initState() {
    super.initState();
    fetchProducts(); // Fetch products when the page loads
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchProducts() async {
    EasyLoading.show(status: 'Please Wait ...');

    // Make HTTP request to fetch products
    var response = await http.get(Uri.parse(
        ApiConstants.getLowStockProductsUrl +
            GetStorage().read('id').toString()));

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      // Parse JSON response and update products list
      List<dynamic> data = json.decode(response.body)['products'];

      setState(() {
        products = data.map((json) => Product.fromJson(json)).toList();
        filteredProducts = List.from(products);
      });
    } else {
      showSnackBar(context, json.decode(response.body)['message']);
      // Handle errors
      if (kDebugMode) {
        print('Failed to load products: ${response.reasonPhrase}');
      }
    }
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
              labelText: 'Search products...',
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
                  filteredProducts = products;
                });
              } else {
                _debounceTimer?.cancel();

                _debounceTimer = Timer(const Duration(milliseconds: 800), () {
                  filterProducts(value);
                });
              }
            },
          ),
        ),
        actions: [
          // IconButton(
          //   onPressed: () {
          //     if (searchController.text.trim().isNotEmpty) {
          //       filterProducts(searchController.text);
          //     } else {
          //       setState(() {
          //         filteredProducts = products;
          //       });
          //     }
          //   },
          //   icon: Icon(
          //     Icons.search_rounded,
          //     color: MyTheme.accent,
          //     size: 30,
          //   ),
          // ),
          // const SizedBox(width: 10),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: IconButton(
              onPressed: () {
                _showBarcodeScanner();
              },
              icon: Icon(
                Icons.qr_code_scanner,
                size: 38,
                color: MyTheme.accent,
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      backgroundColor: MyTheme.background,
      body: Column(
        children: [
          const SizedBox(
            height: 20,
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => fetchProducts(),
              child: ListView.builder(
                itemCount: filteredProducts.length,
                itemBuilder: (context, index) {
                  return Container(
                    child: Card(
                      color: MyTheme.cardBackground,
                      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
                      child: ListTile(
                        title: Text(
                          filteredProducts[index].productName,
                          style: TextStyle(
                            color: MyTheme.textColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Code: ${filteredProducts[index].qrCode}',
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 15),
                                  child: Text(
                                    'SP: ${filteredProducts[index].sellingPrice}',
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Current: ${filteredProducts[index].currentStock}',
                                  style: TextStyle(
                                    color: MyTheme.textColor.withOpacity(.8),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 30),
                                  child: Text(
                                    'Alert: ${filteredProducts[index].alertStockLimit}',
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(left: 30),
                                  child: Text(
                                    'Require: ${filteredProducts[index].alertStockLimit - filteredProducts[index].currentStock}',
                                    style: TextStyle(
                                      color: MyTheme.textColor.withOpacity(.8),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: Icon(
                            Icons.edit,
                            color: MyTheme.accent,
                          ),
                          onPressed: () async {
                            // Get.to(EditProductPage(
                            //     productId: filteredProducts[index].qrCode));
                            final result = await Get.to<bool>(EditProductPage(
                                productId: filteredProducts[index].qrCode));

                            if (result != null && result) {
                              await fetchProducts();
                            }
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

  void filterProducts(String query) {
    setState(() {
      filteredProducts = products.where((product) {
        return product.productName
                .toLowerCase()
                .contains(query.toLowerCase()) ||
            product.qrCode.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  _showBarcodeScanner() {
    return showModalBottomSheet(
      isScrollControlled: true,
      context: context,
      builder: (builder) {
        return StatefulBuilder(builder: (BuildContext context, setState) {
          return SizedBox(
              height: MediaQuery.of(context).size.height / 2,
              child: Scaffold(
                appBar: _buildBarcodeScannerAppBar(),
                body: _buildBarcodeScannerBody(),
              ));
        });
      },
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
      leading: GestureDetector(
        onTap: () => Get.back(),
        child: Center(
          child: Icon(
            Icons.cancel,
            color: MyTheme.accent,
          ),
        ),
      ),
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
    return GestureDetector(
      onTap: () {
        controller.pause();
      },
      child: SizedBox(
        height: 400,
        child: ScanView(
          controller: controller,
          scanAreaScale: .7,
          scanLineColor: MyTheme.accent,
          onCapture: (data) async {
            setState(() {
              searchController.text = data;
              filterProducts(data);
              Get.back();
            });
          },
        ),
      ),
    );
  }
}
