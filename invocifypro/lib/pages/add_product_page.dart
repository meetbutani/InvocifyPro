import 'dart:convert';

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
import 'package:html/parser.dart' as htmlParser;
import 'package:html/dom.dart' as htmlDom;
import 'package:scan/scan.dart';

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
  ScanController controller = ScanController();
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
                    'Product QR Code/Unique ID *',
                  ),
                ),
                IconButton(
                  onPressed: () {
                    _showBarcodeScanner();
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
            _buildTextField(_productNameController, 'Product Name',
                isRequired: true),
            const SizedBox(height: 15),
            _buildTextField(_sellingPriceController, 'Selling Price',
                isRequired: true,
                keyboardType:
                    const TextInputType.numberWithOptions(signed: false)),
            const SizedBox(height: 15),
            _buildTextField(_mrpPriceController, 'MRP Price',
                keyboardType:
                    const TextInputType.numberWithOptions(signed: false)),
            const SizedBox(height: 15),
            _buildTextField(_costPriceController, 'Cost Price',
                keyboardType:
                    const TextInputType.numberWithOptions(signed: false)),
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
                keyboardType: TextInputType.number, onlyPositive: true),
            const SizedBox(height: 15),
            _buildTextField(_alertStockLimitController, 'Alert Stock Limit',
                keyboardType: TextInputType.number, onlyPositive: true),
            const SizedBox(height: 40),
            customButton(
              label: 'Save',
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

                storeProduct();
              },
              isExpanded: true,
            ),
          ],
        ),
      ),
    );
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
              _qrCodeController.text = data;
              Get.back();
            });

            try {
              EasyLoading.show(status: 'Please Wait ...');

              // await fetchData(data);

              // Check if the QR code already exists
              var qrDetails = await http.post(
                Uri.parse(ApiConstants.getQRDetailsUrl),
                headers: {
                  'Content-Type': 'application/json',
                },
                body: json.encode({'qrCode': _qrCodeController.text}),
              );

              if (qrDetails.statusCode == 200) {
                var qrCodeData = json.decode(qrDetails.body);
                showSnackBar(context, qrCodeData["message"], isError: false);
                if (qrCodeData['exists']) {
                  _productNameController.text =
                      qrCodeData["data"]["productName"];
                  _mrpPriceController.text = qrCodeData["data"]["mrpPrice"];
                  // _sellingPriceController.text = qrCodeData["data"]["mrpPrice"];
                  // _costPriceController.text = qrCodeData["data"]["mrpPrice"];
                }
              } else {
                // Handle errors
                print('Error checking QR Code: ${qrDetails.reasonPhrase}');
              }
              EasyLoading.dismiss();
              return;
            } catch (error) {
              EasyLoading.dismiss();
              showSnackBar(
                context,
                "An error occurred. Please check your internet connection and try again.",
              );
            }
          },
        ),
      ),
    );
  }

  Future<void> fetchData(String data) async {
    try {
      String gtin = data; //'8906010500375'; // GTIN code
      String url =
          'https://www.gs1.org/services/verified-by-gs1/results?gtin=$gtin';

      http.Response response = await http.get(Uri.parse(url), headers: {
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,image/avif,image/webp,image/apng,*/*;q=0.8',
        'Accept-Encoding': 'gzip, deflate, br',
        'Accept-Language': 'en-US,en;q=0.9',
        'Cache-Control': 'no-cache',
        'Cookie':
            'Drupal.visitor.teamMember=no; gsone_verified_search_terms_1_2=1',
        'Pragma': 'no-cache',
        'Sec-Ch-Ua':
            '"Not A(Brand";v="99", "Brave";v="121", "Chromium";v="121"',
        'Sec-Ch-Ua-Mobile': '?0',
        'Sec-Ch-Ua-Platform': '"Windows"',
        'Sec-Fetch-Dest': 'document',
        'Sec-Fetch-Mode': 'navigate',
        'Sec-Fetch-Site': 'none',
        'Sec-Fetch-User': '?1',
        'Sec-Gpc': '1',
        'Upgrade-Insecure-Requests': '1',
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36'
      });

      if (response.statusCode == 200) {
        // Parse HTML response
        print('Api 1 called succesfull');
        htmlDom.Document document = htmlParser.parse(response.body);
        print('convert sucessful');
        String vfsToken =
            document.querySelector('#vfs-token')?.attributes['value'] ?? '';
        String captchaSid = document
                .querySelector('[name="captcha_sid"]')
                ?.attributes['value'] ??
            '';
        String captchaToken = document
                .querySelector('[name="captcha_token"]')
                ?.attributes['value'] ??
            '';
        String formBuildId = document
                .querySelector('[name="form_build_id"]')
                ?.attributes['value'] ??
            '';

        Map<String, String> postData = {
          'search_type': 'gtin',
          'gtin': gtin,
          'gln': '',
          'country': '',
          'street_address': '',
          'postal_code': '',
          'city': '',
          'company_name': '',
          'other_key_type': '',
          'other_key': '',
          'vfs_token': vfsToken,
          'captcha_sid': captchaSid,
          'captcha_token': captchaToken,
          'captcha_response': '',
          'g-recaptcha-response': '',
          'form_build_id': formBuildId,
          'form_id': 'verified_search_form',
          '_triggering_element_name': 'gtin_submit',
          '_triggering_element_value': 'Search',
          '_drupal_ajax': '1',
          'ajax_page_state%5Btheme%5D': 'gsone_revamp',
          'ajax_page_state%5Btheme_token%5D': '',
          'ajax_page_state%5Blibraries%5D':
              'addtoany%2Faddtoany%2Cback_to_top%2Fback_to_top_icon%2Cback_to_top%2Fback_to_top_js%2Cbootstrap_barrio%2Fbootstrap-icons%2Cbootstrap_barrio%2Fglobal-styling%2Cbootstrap_barrio%2Fmessages_white%2Cbootstrap_barrio%2Fnode%2Cbootstrap_styles%2Fplugin.background_color.build%2Cbootstrap_styles%2Fplugin.margin.build%2Cbootstrap_styles%2Fplugin.padding.build%2Cbootstrap_styles%2Fplugin.scroll_effects.build%2Ccaptcha%2Fbase%2Cckeditor_bootstrap_tabs%2Ftabs%2Ccore%2Fdrupal.states%2Ccore%2Finternal.jquery.form%2Ccore%2Fjquery%2Ccore%2Fjquery.form%2Cfontawesome%2Ffontawesome.svg%2Cfontawesome%2Ffontawesome.svg.shim%2Cgsone_revamp%2Fbootstrap_cdn%2Cgsone_revamp%2Fglobal-styling%2Cgsone_revamp%2Fselect%2Cgsone_revamp%2Fselect-library%2Cgsone_verified_search%2Fverified_search%2Crecaptcha_once%2Frecaptcha_once%2Csystem%2Fbase%2Cviews%2Fviews.module%2Cwebform%2Flibraries.jquery.intl-tel-input'
        };

        http.Response postResponse = await http.post(
          Uri.parse(
              'https://www.gs1.org/services/verified-by-gs1/results?gtin=$gtin&ajax_form=1&_wrapper_format=drupal_ajax'),
          headers: {
            'authority': 'www.gs1.org',
            'method': 'POST',
            'path': '/services/verified-by-gs1/results?',
            'scheme': 'https',
            'Accept': 'application/json, text/javascript, */*; q=0.01',
            'Accept-Encoding': 'gzip, deflate, br',
            'Accept-Language': 'en-US,en;q=0.9',
            'Cache-Control': 'no-cache',
            'Content-Length': '1590',
            'Content-Type': 'application/x-www-form-urlencoded; charset=UTF-8',
            'Cookie':
                'Drupal.visitor.teamMember=no; gsone_verified_search_terms_1_2=1',
            'Origin': 'https://www.gs1.org',
            // 'Pragma': 'no-cache',
            'Referer':
                'https://www.gs1.org/services/verified-by-gs1/results?gtin=$gtin',
            'Sec-Ch-Ua':
                '"Not A(Brand";v="99", "Brave";v="121", "Chromium";v="121"',
            'Sec-Ch-Ua-Mobile': '?0',
            'Sec-Ch-Ua-Platform': '"Windows"',
            'Sec-Fetch-Dest': 'empty',
            'Sec-Fetch-Mode': 'cors',
            'Sec-Fetch-Site': 'same-origin',
            'Sec-Gpc': '1',
            'User-Agent':
                'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36',
            'X-Requested-With': 'XMLHttpRequest'
          },
          body: postData,
        );

        if (postResponse.statusCode == 200) {
          // Process the POST response as needed
          print(response.body.toString());
          // var data = json
          //     .decode(response.body)
          //     .filter((obj) => obj.selector == '#product-container');

          // if (data.length > 0) {
          //   htmlDom.Document document = htmlParser.parse(data[0].data);

          //   String captchaText = document
          //           .querySelector('#product-container .errors ul li')
          //           ?.text ??
          //       'Not Found';
          //   String productDescription = document
          //           .querySelector('table.company tr:eq(2) td strong')
          //           ?.text ??
          //       'Not Found';

          //   print("captchaText: $captchaText");
          //   print("productDescription: $productDescription");
          // }
          // print(postResponse.body);
        } else {
          print('Failed to make POST request');
        }
      } else {
        print('Failed to fetch data');
      }
    } catch (e) {
      print('Error: $e');
    }
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      {TextInputType keyboardType = TextInputType.text,
      bool isRequired = false,
      bool onlyPositive = false}) {
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
      inputFormatters: onlyPositive
          ? [FilteringTextInputFormatter.allow(RegExp(r'^[1-9][0-9]*'))]
          : [],
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
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'qrCode': _qrCodeController.text, 'userid': userId}),
    );

    EasyLoading.dismiss();
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

    EasyLoading.show(status: 'Please Wait ...');

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
    // print(response);
    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      showSnackBar(context, "Product added successfully");

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
}
