import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:invocifypro/pages/add_product_page.dart';
import 'package:invocifypro/pages/custom_qr_code_list_page.dart';
import 'package:invocifypro/pages/invoice_generator_page.dart';
import 'package:invocifypro/pages/list_all_product_page.dart';
import 'package:invocifypro/pages/login_page.dart';
import 'package:invocifypro/pages/low_stock_product_list_page.dart';
import 'package:invocifypro/pages/saved_invoices_page.dart';
import 'package:invocifypro/pages/shop_info_page.dart';
import 'package:invocifypro/theme.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int curPage = 0;

  @override
  Widget build(BuildContext context) {
    List pages = [
      [const InvoiceGeneratorPage(), "InvocifyPro"],
      [const ListAllProductPage(), "All Products"],
      [const LowStockProductsListPage(), "Low Stock Products"],
      [const AddProductPage(), "Add Product"],
      [const SavedInvoicesPage(), "Saved Invoices"],
      [const ShopInfoPage(), "Shop Info"],
      [const CustomQRCodeListPage(), "Custom QR Codes"],
    ];

    return PopScope(
      canPop: false,
      onPopInvoked: (val) async {
        await showDialog(
          context: context,
          builder: (context) {
            return AlertDialog(
              backgroundColor: MyTheme.cardBackground,
              title: Text(
                'Exit App',
                style: TextStyle(
                  color: MyTheme.accent,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Text(
                'Are you sure you want to exit the app?',
                style: TextStyle(color: MyTheme.textColor),
              ),
              actions: <Widget>[
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
                  onPressed: () async {
                    Get.back();
                    SystemNavigator.pop();
                  },
                  child: Text(
                    'Exit',
                    style: TextStyle(color: MyTheme.accent),
                  ),
                ),
              ],
            );
          },
        );
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: MyTheme.cardBackground,
          surfaceTintColor: MyTheme.cardBackground,
          centerTitle: true,
          title: Text(
            pages[curPage][1],
            style: TextStyle(color: MyTheme.textColor),
          ),
          // Add the leading icon button to open the drawer
          leading: Builder(
            builder: (context) => IconButton(
              icon: Icon(
                Icons.menu,
                color: MyTheme.accent,
                size: 34,
              ), // 3-bar icon
              onPressed: () {
                Scaffold.of(context).openDrawer(); // Open the drawer
              },
            ),
          ),
          // actions: [
          //   if (curPage == 0)
          //     IconButton(
          //       onPressed: () {},
          //       icon: Icon(
          //         Icons.add,
          //         color: MyTheme.accent,
          //         size: 32,
          //       ),
          //     ),
          //   const SizedBox(width: 10),
          // ],
        ),
        // Add a drawer widget
        drawer: Drawer(
          backgroundColor: MyTheme.background,
          shadowColor: Colors.transparent,
          child: ListView(
            padding: EdgeInsets.zero,
            children: <Widget>[
              DrawerHeader(
                child: Center(
                  child: Text(
                    textAlign: TextAlign.center,
                    'invocifypro',
                    style: TextStyle(fontSize: 36, color: MyTheme.textColor),
                  ),
                ),
              ),
              ListTile(
                title: Text(
                  'Invoice Generator',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 0;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Show All Product',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 1;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Low Stock Products',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 2;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Add Product',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 3;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Saved Invoices',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 4;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Shop Info',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 5;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Custome QR Codes',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                onTap: () {
                  setState(() {
                    curPage = 6;
                  });
                  Get.back();
                },
              ),
              ListTile(
                title: Text(
                  'Use Network',
                  style: TextStyle(fontSize: 18, color: MyTheme.textColor),
                ),
                trailing: Switch(
                  value: GetStorage().read('use_network') ?? true,
                  onChanged: (value) async {
                    print(value);
                    await GetStorage().write('use_network', value);
                    setState(() {});
                  },
                ),
              ),
              ListTile(
                title: const Text(
                  'Logout',
                  style: TextStyle(fontSize: 18, color: Colors.red),
                ),
                onTap: () {
                  // Perform logout operation
                  GetStorage().erase();
                  // Redirect to login page
                  Get.offAll(const LoginPage());
                },
              ),
            ],
          ),
        ),
        body: pages[curPage][0],
      ),
    );
  }
}
