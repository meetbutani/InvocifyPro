import 'package:get/get.dart';
import 'package:invocifypro/theme.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class EmailService {
  static const _username = 'meebuu1@gmail.com'; // Your Gmail address
  static const _password = 'uiyn axsx bivk yaom'; // Your Gmail password
  static get secret => "OVUXS3RAMF4HG6BAMJUXM2ZAPFQW63I";
  late final _smtpServer;

  EmailService() {
    _smtpServer = gmail(_username, _password);
  }

  Future<bool> sendEmailOTP(String email, String otp) async {
    final message = Message()
      ..from = const Address(_username, 'InvocifyPro') // Your name
      ..recipients.add(email) // Recipient's email address
      ..subject = 'Your OTP for InvocifyPro!';

    message.html = '''
      <html>
        <head>
          <style>
            h1 {
              font-size: 24px;
              font-weight: bold;
              background: #3598db;
              color: #fff;
              padding: 10px;
              text-align: center;
              display: flex;
              border-radius: 8px;
              width: fit-content;
            }
            h2 {
              font-size: 20px;
              font-weight: bold;
              color: #333;
            }
            h4 {
              font-size: 16px;
              font-weight: bold;
              color: #333;
            }
            p {
              font-size: 14px;
              color: #333;
            }
          </style>
        </head>
        <body>
          <h2>Dear User,</h2>
          <h4>Here is your OTP for InvocifyPro:</h4>
          <h1>$otp</h1>
          <p>Please use this OTP to verify your account. This OTP is valid until session expire.</p>
          <p>Best regards,<br>Your Team at InvocifyPro</p>
        </body>
      </html>
      ''';

    try {
      final sendReport = await send(message, _smtpServer);
      // print('Message sent: ' + sendReport.toString());
      return true;
    } catch (error) {
      // print('Error sending email: $error');
      return false;
    }
  }

  Future<bool> sendOTPToChangePassword(String email, String otp) async {
    final message = Message()
      ..from = const Address(_username, 'InvocifyPro') // Your name
      ..recipients.add(email) // Recipient's email address
      ..subject = 'Your OTP to change password for InvocifyPro!';

    message.html = '''
    <html>
      <head>
        <style>
          h1 {
            font-size: 24px;
            font-weight: bold;
            background: #3598db;
            color: #fff;
            padding: 10px;
            text-align: center;
            display: flex;
            border-radius: 8px;
            width: fit-content;
          }
          h2 {
            font-size: 20px;
            font-weight: bold;
            color: #333;
          }
          h4 {
            font-size: 16px;
            font-weight: bold;
            color: #333;
          }
          p {
            font-size: 14px;
            color: #333;
          }
        </style>
      </head>
      <body>
        <h2>Dear User,</h2>
        <h4>Here is your OTP to change password for InvocifyPro:</h4>
        <h1>$otp</h1>
        <p>Please use this OTP to change your password. This OTP is valid until session expire.</p>
        <p>Best regards,<br>Your Team at InvocifyPro</p>
      </body>
    </html>
    ''';

    try {
      final sendReport = await send(message, _smtpServer);
      // print('Message sent: ' + sendReport.toString());
      return true;
    } catch (error) {
      // print('Error sending email: $error');
      return false;
    }
  }
}
