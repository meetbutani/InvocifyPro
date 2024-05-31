import 'dart:convert';
import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:invocifypro/Utils/email_service.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/pages/login_page.dart';
import 'package:invocifypro/pages/otp_varification_page.dart';
import 'package:invocifypro/theme.dart';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  // final TextEditingController _shopNameController =
  //     TextEditingController(text: "Meet Shop");
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
          'Shop Registration',
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
              // _buildTextField(
              //   _shopNameController,
              //   'Shop Name',
              //   [],
              //   // [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z ]'))],
              // ),
              // const SizedBox(height: 15),
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
                label: 'Register',
                onTap: () async {
                  if (kDebugMode) {
                    print("Register Clicked");
                  }
                  if (_validateFields()) {
                    await register();
                  }
                },
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Already have an account?",
                    style: TextStyle(color: MyTheme.textColor),
                  ),
                  TextButton(
                    onPressed: () {
                      // Get.to(() => const LoginPage());
                      Get.back();
                    },
                    style:
                        TextButton.styleFrom(padding: const EdgeInsets.all(5)),
                    child: Text(
                      "Login now",
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
      {TextInputType? keyboardType,
      bool obscureText = false,
      bool nextFocus = true}) {
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
      keyboardType: keyboardType,
      textInputAction: nextFocus ? TextInputAction.next : TextInputAction.done,
      style: TextStyle(color: MyTheme.textColor),
    );
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

  Future<void> register() async {
    EasyLoading.show(status: 'Please Wait ...');

    EmailService emailService = EmailService();
    String otp = OTP.generateTOTPCodeString(
        EmailService.secret, DateTime.now().millisecondsSinceEpoch);

    bool mailStatus =
        await emailService.sendEmailOTP(_emailController.text.trim(), otp);

    EasyLoading.dismiss();

    if (mailStatus) {
      showSnackBar(context, 'Email sent successfully', isError: false);
      Get.to(OtpVerificationPage(
          email: _emailController.text.trim(),
          otp: otp,
          onOtpVerify: () async {
            // showSnackBar(context, "OTP Verified Successfully");
            EasyLoading.show(status: 'Please Wait ...');
            var response = await http.post(Uri.parse(ApiConstants.registerUrl),
                headers: {'Content-Type': 'application/json'},
                body: json.encode({
                  // "shopName": _shopNameController.text,
                  "email": _emailController.text,
                  "password": _hashPassword(_passwordController.text),
                }));
            // print(response.body);
            if (response.statusCode == 200) {
              showSnackBar(context, json.decode(response.body)['message'],
                  isError: false);
            } else {
              showSnackBar(context, json.decode(response.body)['message']);
            }
            Get.offAll(const LoginPage());
            EasyLoading.dismiss();
          }));
    } else {
      showSnackBar(context, 'Failed to send email. Please try again later.');
    }
  }

  String _hashPassword(String password) {
    // Hash the password using bcrypt with the generated salt
    String hashedPassword =
        BCrypt.hashpw(password, "\$2a\$10\$BL1hMSsLLqSColkUJZyBwu");

    return hashedPassword;
  }

  bool _validateFields() {
    // if (_shopNameController.text.isEmpty ||
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      showSnackBar(context, 'Please fill in all fields.');
      return false;
    }

    if (!_isEmailValid(_emailController.text)) {
      showSnackBar(
        context,
        'Invalid email format. Please enter a valid email address.',
      );
      return false;
    }

    if (!_isPasswordValid(_passwordController.text)) {
      showSnackBar(
        context,
        'Password must meet the following requirements:\n- At least 1 lowercase character\n- At least 1 uppercase character\n- At least 1 digit\n- At least 1 special character\n- Min length: 6 characters\n- Max length: 16 characters.',
      );
      return false;
    }

    try {
      return true;
    } catch (error) {
      if (kDebugMode) {
        print(error);
      }
      return false;
    }
  }
}
