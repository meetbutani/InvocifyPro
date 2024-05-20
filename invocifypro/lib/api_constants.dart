import 'package:get_storage/get_storage.dart';

class ApiConstants {
  // static const String baseUrl = 'http://192.168.87.179:3000';
  static String get baseUrl => GetStorage().read('use_network') ?? false
      ? 'https://obliging-jointly-bengal.ngrok-free.app'
      : 'https://invocifypro.glitch.me';
  static String loginUrl = '$baseUrl/login';
  static String registerUrl = '$baseUrl/register';
  static String changePasswordUrl = '$baseUrl/changePassword';
  static String storeProductUrl = '$baseUrl/storeProduct';
  static String checkQRCodeUrl = '$baseUrl/checkQRCode';
  static String getProductsUrl = '$baseUrl/getProducts/';
  static String getQRDetailsUrl = '$baseUrl/getQRDetails';
  static String getProductDataUrl = '$baseUrl/getProductData';
  static String getProductAllDataUrl = '$baseUrl/getProductAllData';
  static String getAllProductDataUrl = '$baseUrl/getAllProductData';
  static String deleteProductUrl = '$baseUrl/deleteProduct';
  static String updateProductUrl = '$baseUrl/updateProduct';
  static String storeShopInfoUrl = '$baseUrl/storeShopInfo';
  static String uploadShopLogoUrl = '$baseUrl/uploadShopLogo';
  static String getShopLogoUrl = '$baseUrl/shoplogos/';
  static String getShopInfoUrl = '$baseUrl/getShopInfo/';
  static String storeInvoiceUrl = '$baseUrl/invoices';
  static String getAllInvoicesUrl = '$baseUrl/invoices/';
  static String getInvoiceDataUrl = '$baseUrl/invoices/';
  static String getLowStockProductsUrl = '$baseUrl/getLowStockProducts/';
  static String storeCustomQRCodeUrl = '$baseUrl/storeCustomQRCode';
  static String getCustomQRCodesUrl = '$baseUrl/getCustomQRCodes/';
  static String updateCustomQRCodeUrl = '$baseUrl/updateCustomQRCode';
}
