class Customer {
  final int? id;
  final String customerCode;
  final String customerName;
  final String address;
  final String? phoneNumber;
  final String areaCode;
  final String areaName;
  final double? lastReading;
  final DateTime? lastReadingDate;
  final double pricePerUnit;
  final double totalDebt;
  final int debtMonths;
  final DateTime? lastPaymentDate;
  final String routeStatus;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const Customer({
    this.id,
    required this.customerCode,
    required this.customerName,
    required this.address,
    required this.phoneNumber,
    required this.areaCode,
    required this.areaName,
    required this.lastReading,
    required this.lastReadingDate,
    required this.pricePerUnit,
    required this.totalDebt,
    required this.debtMonths,
    required this.lastPaymentDate,
    required this.routeStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Customer.fromMap(Map<String, dynamic> map) {
    return Customer(
      id: map['id'] as int?,
      customerCode: map['customerCode'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      phoneNumber: map['phoneNumber'] as String?,
      areaCode: map['areaCode'] as String? ?? '',
      areaName: map['areaName'] as String? ?? '',
      lastReading: _toDouble(map['lastReading']),
      lastReadingDate: _toDateTime(map['lastReadingDate']),
      pricePerUnit: _toDouble(map['pricePerUnit']) ?? 0,
      totalDebt: _toDouble(map['totalDebt']) ?? 0,
      debtMonths: map['debtMonths'] as int? ?? 0,
      lastPaymentDate: _toDateTime(map['lastPaymentDate']),
      routeStatus: map['routeStatus'] as String? ?? 'uncollected',
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: _toDateTime(map['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerCode': customerCode,
      'customerName': customerName,
      'address': address,
      'phoneNumber': phoneNumber,
      'areaCode': areaCode,
      'areaName': areaName,
      'lastReading': lastReading,
      'lastReadingDate': lastReadingDate?.toIso8601String(),
      'pricePerUnit': pricePerUnit,
      'totalDebt': totalDebt,
      'debtMonths': debtMonths,
      'lastPaymentDate': lastPaymentDate?.toIso8601String(),
      'routeStatus': routeStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  Customer copyWith({
    int? id,
    String? customerCode,
    String? customerName,
    String? address,
    String? phoneNumber,
    String? areaCode,
    String? areaName,
    double? lastReading,
    DateTime? lastReadingDate,
    double? pricePerUnit,
    double? totalDebt,
    int? debtMonths,
    DateTime? lastPaymentDate,
    String? routeStatus,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Customer(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      areaCode: areaCode ?? this.areaCode,
      areaName: areaName ?? this.areaName,
      lastReading: lastReading ?? this.lastReading,
      lastReadingDate: lastReadingDate ?? this.lastReadingDate,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      totalDebt: totalDebt ?? this.totalDebt,
      debtMonths: debtMonths ?? this.debtMonths,
      lastPaymentDate: lastPaymentDate ?? this.lastPaymentDate,
      routeStatus: routeStatus ?? this.routeStatus,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static double? _toDouble(dynamic value) {
    if (value == null) {
      return null;
    }
    if (value is double) {
      return value;
    }
    if (value is int) {
      return value.toDouble();
    }
    return double.tryParse(value.toString());
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) {
      return null;
    }
    return DateTime.tryParse(value.toString());
  }
}
