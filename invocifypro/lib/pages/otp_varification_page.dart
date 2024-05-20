import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:get/get.dart';
import 'package:invocifypro/Utils/email_service.dart';
import 'package:invocifypro/Utils/utils.dart';
import 'package:invocifypro/api_constants.dart';
import 'package:invocifypro/theme.dart';
import 'package:http/http.dart' as http;
import 'package:otp/otp.dart';

class OtpVerificationPage extends StatefulWidget {
  final String email;
  final String otp;
  final VoidCallback onOtpVerify;

  const OtpVerificationPage(
      {super.key,
      required this.email,
      required this.otp,
      required this.onOtpVerify});

  @override
  State<OtpVerificationPage> createState() => _OtpVerificationPageState();
}

class _OtpVerificationPageState extends State<OtpVerificationPage> {
  final TextEditingController _otpController = TextEditingController();

  late String otp;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    otp = widget.otp;
  }

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
          'OTP Verification',
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
              Text(
                'An OTP has been sent to your email address:',
                style: TextStyle(color: MyTheme.textColor),
              ),
              Row(
                children: [
                  Text(
                    widget.email,
                    style: TextStyle(color: MyTheme.textColor, fontSize: 16),
                  ),
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(
                      Icons.edit,
                      color: MyTheme.accent,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 20),
              _buildTextField(
                _otpController,
                'Enter OTP',
                [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(6),
                ],
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 40),
              customButton(
                label: 'Verify OTP',
                onTap: () {
                  print(widget.onOtpVerify);
                  if (verifyOTP()) {
                    widget.onOtpVerify.call();
                  }
                },
                isExpanded: true,
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Didn't receive an OTP?",
                    style: TextStyle(color: MyTheme.textColor),
                  ),
                  TextButton(
                    onPressed: () async {
                      // Resend OTP
                      EasyLoading.show(status: 'Please Wait ...');
                      setState(() {
                        otp = OTP.generateTOTPCodeString(EmailService.secret,
                            DateTime.now().millisecondsSinceEpoch);
                      });
                      EmailService emailService = EmailService();
                      await emailService.sendEmailOTP(widget.email, otp);

                      EasyLoading.dismiss();

                      showSnackBar(context, 'Email sent successfully',
                          isError: false);
                    },
                    style:
                        TextButton.styleFrom(padding: const EdgeInsets.all(5)),
                    child: Text(
                      "Resend OTP",
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
          labelText: labelText,
          labelStyle: TextStyle(color: MyTheme.textColor),
          border: const OutlineInputBorder(),
          focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey))),
      onTapOutside: (event) => FocusManager.instance.primaryFocus?.unfocus(),
      inputFormatters: inputFormatters,
      keyboardType: keyboardType,
      textInputAction: nextFocus ? TextInputAction.next : TextInputAction.done,
      style: TextStyle(color: MyTheme.textColor),
    );
  }

  bool _validateOTP() {
    if (_otpController.text.trim().isEmpty) {
      showSnackBar(context, 'Please enter the OTP.');
      return false;
    }

    if (_otpController.text.trim().length != 6) {
      showSnackBar(context, 'Invalid OTP. Please enter a 6-digit OTP.');
      return false;
    }

    if (_otpController.text.trim() != otp) {
      showSnackBar(context, 'Incorrect OTP. Please try again.');
      return false;
    }

    return true;
  }

  bool verifyOTP() {
    if (_validateOTP()) {
      if (_otpController.text.trim() == otp) {
        return true;
      }
    }
    return false;
  }
}
