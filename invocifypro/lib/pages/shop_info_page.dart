import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'dart:ui' as ui;

import 'package:crop_your_image/crop_your_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl_phone_field/country_picker_dialog.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:intl_phone_field/phone_number.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/theme.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class ShopInfoPage extends StatefulWidget {
  const ShopInfoPage({Key? key});

  @override
  _ShopInfoPageState createState() => _ShopInfoPageState();
}

class _ShopInfoPageState extends State<ShopInfoPage> {
  final TextEditingController _shopNameController = TextEditingController();
  final TextEditingController _shopAddressController = TextEditingController();
  final TextEditingController _shopEmailController = TextEditingController();
  final TextEditingController _shopWebsiteController = TextEditingController();
  final TextEditingController _shopPhoneController = TextEditingController();
  final TextEditingController _shopGSTNoController = TextEditingController();
  final TextEditingController _shopTermsController = TextEditingController();

  String? imagePath;
  Uint8List? imageBytes;
  File? image;
  ui.Image? imageSize;
  final _controller = CropController();
  bool openImageCroper = false;

  double left = 0;
  double top = 0;
  final double targetSize = 150;

  late PhoneNumber number;

  @override
  void initState() {
    super.initState();
    GetStorage box = GetStorage();
    _shopNameController.text = box.read("shopName") ?? "";
    _shopAddressController.text = box.read("shopAddress") ?? "";
    _shopEmailController.text = box.read("shopEmail") ?? "";
    _shopWebsiteController.text = box.read("shopWebsite") ?? "";

    number = PhoneNumber.fromCompleteNumber(
        completeNumber: box.read("shopPhone") ?? "");
    print(number.completeNumber);
    _shopPhoneController.text = number.number;

    _shopGSTNoController.text = box.read("shopGSTNo") ?? "";
    _shopTermsController.text = box.read("shopTerms") ?? "";
    loadLogoImage(init: true);
  }

  Future<void> loadLogoImage({bool init = false}) async {
    imagePath =
        '${(await getApplicationDocumentsDirectory()).path}/shop_logo_user.png';
    setState(() {
      // imagePath = File(imagePath!).readAsBytesSync().isEmpty ? null : imagePath;
      try {
        imageBytes = File(imagePath!).readAsBytesSync();
      } catch (e) {
        imageBytes = null;
      }
    });

    if (init && imageBytes == null) {
      String imageUrl =
          "${ApiConstants.getShopLogoUrl}${GetStorage().read("email") ?? "noemail"}.png";
      print(imageUrl);

      // Fetch image bytes from the URL
      var response = await http.get(Uri.parse(imageUrl));

      if (response.statusCode == 200) {
        // Convert the response body to Uint8List and store it in imageBytes
        setState(() {
          imageBytes = response.bodyBytes;
        });
        await File(imagePath!).writeAsBytes(imageBytes!);
        print("Image bytes fetched successfully");
      } else {
        // Handle errors
        print("Failed to fetch image bytes: ${response.reasonPhrase}");
      }
      return;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MyTheme.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Visibility(
              visible: !openImageCroper,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildShopLogoField(),
                  const SizedBox(height: 15),
                  _buildTextField(_shopNameController, 'Shop Name',
                      isRequired: true),
                  const SizedBox(height: 15),
                  _buildTextField(_shopAddressController, 'Shop Address',
                      isRequired: true,
                      keyboardType: TextInputType.streetAddress),
                  const SizedBox(height: 15),
                  _buildTextField(_shopEmailController, 'Shop Email',
                      isRequired: false,
                      keyboardType: TextInputType.emailAddress),
                  const SizedBox(height: 15),
                  IntlPhoneField(
                    controller: _shopPhoneController,
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
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
                          color: MyTheme.textColor.withAlpha(150),
                          fontSize: 14),
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
                  // _buildTextField(_shopPhoneController, 'Shop Phone',
                  //     isRequired: false, keyboardType: TextInputType.phone),
                  const SizedBox(height: 15),
                  _buildTextField(_shopWebsiteController, 'Shop Website',
                      isRequired: false, keyboardType: TextInputType.url),
                  const SizedBox(height: 15),
                  _buildTextField(_shopGSTNoController, 'Shop GST No',
                      isRequired: false),
                  const SizedBox(height: 15),
                  _buildTermsField(),
                  const SizedBox(height: 40),
                  customButton(
                    label: 'Save',
                    onTap: () {
                      if (_shopNameController.text.isEmpty) {
                        showSnackBar(context, "Shop Name Required");
                        return;
                      }

                      if (_shopAddressController.text.isEmpty) {
                        showSnackBar(context, "Shop Address Required");
                        return;
                      }

                      try {
                        if (number.number.isNotEmpty &&
                            !number.isValidNumber()) {
                          throw Exception();
                        }
                      } on Exception {
                        showSnackBar(context, "Invalid Phone Number.");
                        return;
                      }

                      // Validate email
                      final RegExp emailRegex = RegExp(
                          r'^[\w-]+(\.[\w-]+)*@([\w-]+\.)+[a-zA-Z]{2,7}$');
                      if (_shopEmailController.text.isNotEmpty &&
                          !emailRegex.hasMatch(_shopEmailController.text)) {
                        showSnackBar(context, "Invalid Email.");
                        return;
                      }

                      // Validate website
                      final RegExp websiteRegex =
                          RegExp(r'^(http|https)://[^/]+(/[^/]+)*$');
                      if (_shopWebsiteController.text.isNotEmpty &&
                          !websiteRegex.hasMatch(_shopWebsiteController.text)) {
                        showSnackBar(context, "Invalid Website link.");
                        return;
                      }

                      // Validate GST number
                      final RegExp gstRegex = RegExp(
                          r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$');
                      if (_shopGSTNoController.text.isNotEmpty &&
                          !gstRegex.hasMatch(_shopGSTNoController.text)) {
                        showSnackBar(context, "Invalid GST Number.");
                        return;
                      }

                      _storeShopInfo(context);
                    },
                    isExpanded: true,
                  ),
                ],
              ),
            ),
            openImageCroper
                ? SizedBox(
                    height: MediaQuery.of(context).size.height - 140,
                    child: Stack(
                      children: [
                        Container(
                          constraints: BoxConstraints(
                            maxWidth: min(imageSize!.width.toDouble(),
                                MediaQuery.of(context).size.width * 1),
                            maxHeight: min(imageSize!.height.toDouble(),
                                MediaQuery.of(context).size.height * .7),
                          ),
                          child: Crop(
                            image: image!.readAsBytesSync(),
                            controller: _controller,
                            aspectRatio: 1 / 1,
                            fixCropRect: true,
                            interactive: true,
                            baseColor: MyTheme.background,
                            initialArea: Rect.fromLTWH(
                                left, top, targetSize * 2, targetSize * 2),
                            onCropped: (croppedImage) async {
                              await File(imagePath!).writeAsBytes(croppedImage);
                              setState(() {
                                openImageCroper = false;
                              });
                              await loadLogoImage();
                              await _uploadShopLogo();
                            },
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              IconButton(
                                  onPressed: () {
                                    setState(() {
                                      openImageCroper = false;
                                      image = null;
                                    });
                                  },
                                  style: IconButton.styleFrom(
                                    backgroundColor: MyTheme.background,
                                  ),
                                  icon: Icon(
                                    Icons.close,
                                    color: MyTheme.accent,
                                    size: 28,
                                  )),
                              IconButton(
                                  onPressed: () {
                                    _controller.crop();
                                  },
                                  style: IconButton.styleFrom(
                                      backgroundColor: MyTheme.background),
                                  icon: Icon(
                                    Icons.done,
                                    color: MyTheme.accent,
                                    size: 28,
                                  ))
                            ],
                          ),
                        )
                      ],
                    ),
                  )
                : const SizedBox()
          ],
        ),
      ),
    );
  }

  Widget _buildShopLogoField() {
    return Center(
      child: Stack(
        alignment: Alignment.bottomRight,
        children: [
          Container(
            width: targetSize,
            height: targetSize,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: MyTheme.cardBackground,
            ),
            margin: const EdgeInsets.fromLTRB(0, 0, 10, 10),
            child: imageBytes == null
                ? Center(
                    child: Text(
                    'No Image',
                    style: TextStyle(color: MyTheme.textColor),
                  ))
                : Image.memory(imageBytes!, fit: BoxFit.cover),
          ),
          IconButton(
            onPressed: _pickAndCropImage,
            style: IconButton.styleFrom(backgroundColor: MyTheme.background),
            icon: Icon(
              Icons.edit,
              size: 28,
              color: MyTheme.accent,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndCropImage() async {
    final pickedFile =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      image = File(pickedFile.path);
      imageSize = await decodeImageFromList(image!.readAsBytesSync());
      left = (imageSize!.width / 2.0) - targetSize;
      top = (imageSize!.height / 2.0) - targetSize;
      setState(() {
        openImageCroper = true;
      });
    }
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

  Widget _buildTermsField() {
    return TextField(
      controller: _shopTermsController,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      decoration: InputDecoration(
        labelText: 'Terms and Conditions',
        labelStyle: TextStyle(color: MyTheme.textColor),
        border: const OutlineInputBorder(),
        focusedBorder: const OutlineInputBorder(
            borderSide: BorderSide(color: Colors.grey)),
      ),
      keyboardType: TextInputType.multiline,
      maxLines: null,
      style: TextStyle(color: MyTheme.textColor),
    );
  }

  Future<void> _storeShopInfo(BuildContext context) async {
    EasyLoading.show(status: 'Please Wait ...');

    // Prepare the request body
    final Map<String, dynamic> requestBody = {
      'userId': GetStorage().read("id").toString(),
      'shopName': _shopNameController.text,
      'shopAddress': _shopAddressController.text,
      'shopEmail': _shopEmailController.text,
      'shopWebsite': _shopWebsiteController.text,
      'shopPhone': number.completeNumber,
      'shopGSTNo': _shopGSTNoController.text,
      'shopTerms': _shopTermsController.text,
    };

    // Perform the HTTP POST request to store shop information
    final response = await http.post(
      Uri.parse(ApiConstants.storeShopInfoUrl),
      headers: {
        'Content-Type': 'application/json',
      },
      body: json.encode(requestBody),
    );

    EasyLoading.dismiss();

    if (response.statusCode == 200) {
      // Shop information stored successfully
      GetStorage gs = GetStorage();
      gs.write('shopName', _shopNameController.text);
      gs.write('shopAddress', _shopAddressController.text);
      gs.write('shopEmail', _shopEmailController.text);
      gs.write('shopWebsite', _shopWebsiteController.text);
      gs.write('shopPhone', number.completeNumber);
      gs.write('shopGSTNo', _shopGSTNoController.text);
      gs.write('shopTerms', _shopTermsController.text);

      showSnackBar(context, 'Shop information stored successfully',
          isError: false);

      print('Shop information stored successfully');
    } else {
      // Failed to store shop information
      showSnackBar(context,
          'Failed to store shop information. check internet connection.');
      print('Failed to store shop information: ${response.reasonPhrase}');
    }
  }

  Future<void> _uploadShopLogo() async {
    if (image == null) {
      // No logo image selected
      return;
    }

    // Prepare the multipart request
    final Uri uri = Uri.parse(ApiConstants.uploadShopLogoUrl);
    final request = http.MultipartRequest('POST', uri)
      ..fields['email'] = GetStorage().read("email") ?? "noemail"
      ..files.add(await http.MultipartFile.fromPath('logo',
          '${(await getApplicationDocumentsDirectory()).path}/shop_logo_user.png'));
    // ..files.add(await http.MultipartFile.fromPath('logo', image!.path));

    // Send the request
    final response = await request.send();

    if (response.statusCode == 200) {
      // Logo uploaded successfully
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);
      final imagePath = jsonResponse['imagePath'];
      print('Logo uploaded successfully. Image path: $imagePath');
    } else {
      // Failed to upload logo
      print(response.statusCode);
      print(response.reasonPhrase);
      print('Failed to upload logo: ${response.reasonPhrase}');
    }
  }
}
