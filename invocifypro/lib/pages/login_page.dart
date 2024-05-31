// ignore_for_file: use_build_context_synchronously

import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/Utils/email_service.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/pages/home_page.dart';
import 'package:invocifypro/pages/new_password_page.dart';
import 'package:invocifypro/pages/otp_varification_page.dart';
import 'package:invocifypro/pages/registration_page.dart';
import 'package:invocifypro/theme.dart';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController =
      TextEditingController(text: "meet.butani2702@gmail.com");
  final TextEditingController _passwordController =
      TextEditingController(text: "Meet@123");

  bool passVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyTheme.background,
        surfaceTintColor: MyTheme.background,
        centerTitle: true,
        title: const Text(
          'Login',
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      backgroundColor: MyTheme.background,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildTextField(
                _emailController,
                'Email',
                [FilteringTextInputFormatter.deny(RegExp(r'\s'))],
              ),
              const SizedBox(height: 15),
              _buildTextField(
                _passwordController,
                'Password',
                [],
                obscureText: true,
                nextFocus: false, // Set nextFocus to null for the last field
              ),
              const SizedBox(height: 40),
              customButton(
                label: 'Login',
                onTap: () async {
                  // print("Login Clicked");
                  if (_validateFields()) {
                    await login();
                  }
                },
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () async {
                      EasyLoading.show(status: 'Please Wait ...');

                      EmailService emailService = EmailService();
                      String otp = OTP.generateTOTPCodeString(
                          EmailService.secret,
                          DateTime.now().millisecondsSinceEpoch);

                      bool mailStatus =
                          await emailService.sendOTPToChangePassword(
                              _emailController.text.trim(), otp);

                      EasyLoading.dismiss();

                      if (mailStatus) {
                        showSnackBar(context, 'Email sent successfully',
                            isError: false);
                        Get.to(OtpVerificationPage(
                            email: _emailController.text.trim(),
                            otp: otp,
                            onOtpVerify: () async {
                              // showSnackBar(context, "OTP Verified Successfully");
                              Get.off(NewPasswordPage(
                                email: _emailController.text.trim(),
                              ));
                            }));
                      } else {
                        showSnackBar(context,
                            'Failed to send email. Please try again later.');
                      }
                    },
                    child: Text(
                      "Forgot Password",
                      style: TextStyle(color: MyTheme.accent),
                    ),
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Don't have an account?",
                    style: TextStyle(color: MyTheme.textColor),
                  ),
                  TextButton(
                    onPressed: () {
                      Get.to(() => const RegistrationPage());
                      // Get.back();
                    },
                    style:
                        TextButton.styleFrom(padding: const EdgeInsets.all(5)),
                    child: Text(
                      "Register now",
                      style: TextStyle(color: MyTheme.accent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      List<TextInputFormatter> inputFormatters,
      {bool obscureText = false, bool nextFocus = true}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          suffixIcon: obscureText
              ? IconButton(
                  onPressed: () => setState(() => passVisible = !passVisible),
                  icon: Icon(passVisible
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                )
              : null,
          labelText: labelText,
          labelStyle: TextStyle(color: MyTheme.textColor),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey))),
      obscureText: obscureText && !passVisible,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      inputFormatters: inputFormatters,
      keyboardType: TextInputType.emailAddress,
      textInputAction: nextFocus ? TextInputAction.next : TextInputAction.done,
      style: TextStyle(color: MyTheme.textColor),
    );
  }

  Future<void> login() async {
    EasyLoading.show(status: 'Please Wait ...');
    try {
      var response = await http.post(Uri.parse(ApiConstants.loginUrl),
          headers: {
            'Content-Type': 'application/json',
          },
          body: json.encode({
            'email': _emailController.text,
            'password': _hashPassword(_passwordController.text),
          }));
      // print(response.body);
      Map<String, dynamic> responseBody = json.decode(response.body);
      if (responseBody['ok']) {
        if (kDebugMode) {
          print(responseBody['data']);
        }
        GetStorage gs = GetStorage();
        gs.write("isLogin", true);
        gs.write("id", responseBody['data']['id']);
        // gs.write("shopName", responseBody['data']['shopName']);
        gs.write("email", responseBody['data']['email']);

        response = await http.get(
            Uri.parse(ApiConstants.getShopInfoUrl +
                responseBody['data']['id'].toString()),
            headers: {
              'Content-Type': 'application/json',
            });
        if (response.statusCode == 200) {}
        responseBody = json.decode(response.body);
        if (responseBody["shopInfo"] != null) {
          gs.write('shopName', responseBody["shopInfo"]["shop_name"] ?? "");
          gs.write(
              'shopAddress', responseBody["shopInfo"]["shop_address"] ?? "");
          gs.write('shopEmail', responseBody["shopInfo"]["shop_email"] ?? "");
          gs.write(
              'shopWebsite', responseBody["shopInfo"]["shop_website"] ?? "");
          gs.write('shopPhone', responseBody["shopInfo"]["shop_phone"] ?? "");
          gs.write('shopGSTNo', responseBody["shopInfo"]["shop_gst_no"] ?? "");
          gs.write('shopTerms', responseBody["shopInfo"]["shop_terms"] ?? "");
        }

        await Get.off(const HomePage());
      }
      EasyLoading.dismiss();
      showSnackBar(context, responseBody['message']);
    } catch (error) {
      EasyLoading.dismiss();
      showSnackBar(
        context,
        "An error occurred. Please check your internet connection and try again.",
      );

      if (kDebugMode) {
        print("Errore Occured in login : $error");
      }
    }
  }

  // bool verifyPassword(String password, String hashedPassword) {
  //   // Verify the password against the hashed password
  //   return BCrypt.checkpw(password, hashedPassword);
  // }

  String _hashPassword(String password) {
    // Hash the password using bcrypt with the generated salt
    String hashedPassword =
        BCrypt.hashpw(password, "\$2a\$10\$BL1hMSsLLqSColkUJZyBwu");

    return hashedPassword;
  }

  bool _validateFields() {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showSnackBar(context, 'Please fill in all fields.');
      return false;
    }

    // Add email format validation
    if (!_isEmailValid(_emailController.text)) {
      showSnackBar(
        context,
        'Invalid email format. Please enter a valid email address.',
      );
      return false;
    }

    // Add password requirements validation
    if (!_isPasswordValid(_passwordController.text)) {
      showSnackBar(
        context,
        'Password must meet the following requirements:\n- At least 1 lowercase character\n- At least 1 uppercase character\n- At least 1 digit\n- At least 1 special character\n- Min length: 6 characters\n- Max length: 16 characters.',
      );
      return false;
    }

    return true;
  }

  bool _isEmailValid(String email) {
    // Email validation using a regular expression
    String pattern = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(email);
  }

  bool _isPasswordValid(String password) {
    // Password validation using a regular expression
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])([A-Za-z\d!@#$%^&*(),.?":{}|<>]){6,16}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(password);
  }
}
