import 'dart:convert';

import 'package:bcrypt/bcrypt.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/pages/login_page.dart';
import 'package:invocifypro/theme.dart';
import 'package:http/http.dart' as http;

class NewPasswordPage extends StatefulWidget {
  final String email;
  const NewPasswordPage({super.key, required this.email});

  @override
  State<NewPasswordPage> createState() => _NewPasswordPageState();
}

class _NewPasswordPageState extends State<NewPasswordPage> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: MyTheme.background,
        surfaceTintColor: MyTheme.background,
        centerTitle: true,
        leading: IconButton(
            onPressed: () {
              Get.back();
            },
            icon: Icon(
              Icons.arrow_back,
              color: MyTheme.accent,
              size: 28,
            )),
        title: const Text(
          'Forgot Password',
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
              TextField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {
                        _obscureNewPassword = !_obscureNewPassword;
                      }),
                      icon: Icon(_obscureNewPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                    ),
                    labelText: 'New Password',
                    labelStyle: TextStyle(color: MyTheme.textColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey))),
                obscureText: _obscureNewPassword,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.next,
                style: TextStyle(color: MyTheme.textColor),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                    suffixIcon: IconButton(
                      onPressed: () => setState(() {
                        _obscureConfirmPassword = !_obscureConfirmPassword;
                      }),
                      icon: Icon(_obscureConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined),
                    ),
                    labelText: 'Confirm New Password',
                    labelStyle: TextStyle(color: MyTheme.textColor),
                    border: const OutlineInputBorder(),
                    focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey))),
                obscureText: _obscureConfirmPassword,
                onTapOutside: (event) =>
                    FocusManager.instance.primaryFocus?.unfocus(),
                keyboardType: TextInputType.text,
                textInputAction: TextInputAction.done,
                style: TextStyle(color: MyTheme.textColor),
              ),
              const SizedBox(height: 40),
              customButton(
                label: 'Reset Password',
                onTap: () async {
                  if (_validateFields()) {
                    EasyLoading.show(status: 'Please Wait ...');
                    var response = await http.post(
                        Uri.parse(ApiConstants.changePasswordUrl),
                        headers: {'Content-Type': 'application/json'},
                        body: json.encode({
                          "email": widget.email,
                          "newPassword":
                              _hashPassword(_newPasswordController.text),
                        }));
                    // print(response.body);
                    if (response.statusCode == 200) {
                      showSnackBar(
                          context, json.decode(response.body)['message'],
                          isError: false);
                    } else {
                      showSnackBar(
                          context, json.decode(response.body)['message']);
                    }
                    Get.offAll(const LoginPage());
                    EasyLoading.dismiss();
                  }
                },
                isExpanded: true,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String labelText,
      List<TextInputFormatter> inputFormatters,
      {required VoidCallback changePassVisibility,
      bool obscureText = false,
      bool nextFocus = true}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
          suffixIcon: obscureText
              ? IconButton(
                  onPressed: changePassVisibility,
                  icon: Icon(obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined),
                )
              : null,
          labelText: labelText,
          labelStyle: TextStyle(color: MyTheme.textColor),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey))),
      obscureText: obscureText,
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      inputFormatters: inputFormatters,
      keyboardType: TextInputType.text,
      textInputAction: nextFocus ? TextInputAction.next : TextInputAction.done,
      style: TextStyle(color: MyTheme.textColor),
    );
  }

  bool _validateFields() {
    if (_newPasswordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      showSnackBar(context, 'Please fill in all fields.');
      return false;
    }

    if (_newPasswordController.text != _confirmPasswordController.text) {
      showSnackBar(context, 'New password and confirm password do not match.');
      return false;
    }

    // Add password requirements validation
    if (!_isPasswordValid(_newPasswordController.text)) {
      showSnackBar(
        context,
        'Password must meet the following requirements:\n- At least 1 lowercase character\n- At least 1 uppercase character\n- At least 1 digit\n- At least 1 special character\n- Min length: 6 characters\n- Max length: 16 characters.',
      );
      return false;
    }

    return true;
  }

  bool _isPasswordValid(String password) {
    // Password validation using a regular expression
    String pattern =
        r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[!@#$%^&*(),.?":{}|<>])([A-Za-z\d!@#$%^&*(),.?":{}|<>]){6,16}$';
    RegExp regExp = RegExp(pattern);
    return regExp.hasMatch(password);
  }

  String _hashPassword(String password) {
    // Hash the password using bcrypt with the generated salt
    String hashedPassword =
        BCrypt.hashpw(password, "\$2a\$10\$BL1hMSsLLqSColkUJZyBwu");

    return hashedPassword;
  }
}
