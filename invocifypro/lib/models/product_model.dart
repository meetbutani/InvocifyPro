class Product {
  final int id;
  final int userId;
  final String qrCode;
  final String productName;
  final double sellingPrice;
  final double mrpPrice;
  final double costPrice;
  final int currentStock;
  final int alertStockLimit;
  final String stockUnit;

  Product({
    required this.id,
    required this.userId,
    required this.qrCode,
    required this.productName,
    required this.sellingPrice,
    required this.mrpPrice,
    required this.costPrice,
    required this.currentStock,
    required this.alertStockLimit,
    required this.stockUnit,
  });

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      qrCode: json['qrCode'] ?? '',
      productName: json['productName'] ?? '',
      sellingPrice: json['sellingPrice'] != null
          ? double.tryParse(json['sellingPrice']) ?? 0.0
          : 0.0,
      mrpPrice: json['mrpPrice'] != null
          ? double.tryParse(json['mrpPrice']) ?? 0.0
          : 0.0,
      costPrice: json['costPrice'] != null
          ? double.tryParse(json['costPrice']) ?? 0.0
          : 0.0,
      currentStock: json['currentStock'] ?? 0,
      alertStockLimit: json['alertStockLimit'] ?? 0,
      stockUnit: json['stockUnit'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'qrCode': qrCode,
      'productName': productName,
      'sellingPrice': sellingPrice,
      'mrpPrice': mrpPrice,
      'costPrice': costPrice,
      'currentStock': currentStock,
      'alertStockLimit': alertStockLimit,
      'stockUnit': stockUnit,
    };
  }
}
