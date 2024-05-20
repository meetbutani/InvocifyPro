class Invoice {
  final String invoiceNo;
  final int shopId;
  final String shopName;
  final String shopAddress;
  final String shopEmail;
  final String shopPhone;
  final String shopGstNo;
  final String custName;
  final String custAddress;
  final String custPhone;
  final String custEmail;
  final DateTime invoiceDate;
  final DateTime dueDate;
  final double subtotal;
  final double discount;
  final double taxRate;
  final double totalAmount;
  final List<List<String>> products;

  Invoice({
    required this.invoiceNo,
    required this.shopId,
    required this.shopName,
    required this.shopAddress,
    required this.shopEmail,
    required this.shopPhone,
    required this.shopGstNo,
    required this.custName,
    required this.custAddress,
    required this.custPhone,
    required this.custEmail,
    required this.invoiceDate,
    required this.dueDate,
    required this.subtotal,
    required this.discount,
    required this.taxRate,
    required this.totalAmount,
    required this.products,
  });

  factory Invoice.fromJson(Map<String, dynamic> json) {
    return Invoice(
      invoiceNo: json['invoice_no'],
      shopId: json['shop_id'],
      shopName: json['shop_name'],
      shopAddress: json['shop_address'],
      shopEmail: json['shop_email'],
      shopPhone: json['shop_phone'],
      shopGstNo: json['shop_gst_no'],
      custName: json['cust_name'],
      custAddress: json['cust_address'],
      custPhone: json['cust_phone'],
      custEmail: json['cust_email'],
      invoiceDate: DateTime.parse(json['invoice_date']),
      dueDate: DateTime.parse(json['due_date']),
      subtotal: double.tryParse(json['subtotal']) ?? 0,
      discount: double.tryParse(json['discount']) ?? 0,
      taxRate: double.tryParse(json['tax_rate']) ?? 0,
      totalAmount: double.tryParse(json['total_amount']) ?? 0,
      products: (json['products'] as List)
          .map((product) => List<String>.from(product))
          .toList(),
    );
  }
}
