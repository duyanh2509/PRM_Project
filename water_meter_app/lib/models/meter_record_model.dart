class MeterRecord {
  final int? id;
  final String customerCode;
  final String customerName;
  final String address;
  final String areaCode;
  final String areaName;
  final String recordType;
  final double? oldReading;
  final double? newReading;
  final double? amountCollected;
  final String syncStatus;
  final DateTime recordedAt;
  final String? collectorName;
  final String? note;
  final double pricePerUnit;
  final String? billingMonth;
  final String? paymentMethod;
  final String? paymentStatus;
  final String? proofImagePath;
  final DateTime? syncedAt;

  const MeterRecord({
    required this.id,
    required this.customerCode,
    required this.customerName,
    required this.address,
    required this.areaCode,
    required this.areaName,
    required this.recordType,
    required this.oldReading,
    required this.newReading,
    required this.amountCollected,
    required this.syncStatus,
    required this.recordedAt,
    required this.collectorName,
    required this.note,
    required this.pricePerUnit,
    required this.billingMonth,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.proofImagePath,
    required this.syncedAt,
  });

  factory MeterRecord.fromMap(Map<String, dynamic> map) {
    return MeterRecord(
      id: map['id'] as int?,
      customerCode: map['customerCode'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      address: map['address'] as String? ?? '',
      areaCode: map['areaCode'] as String? ?? '',
      areaName: map['areaName'] as String? ?? '',
      recordType: map['recordType'] as String? ?? 'meter',
      oldReading: _toDouble(map['oldReading']),
      newReading: _toDouble(map['newReading']),
      amountCollected: _toDouble(map['amountCollected']),
      syncStatus: map['syncStatus'] as String? ?? 'pending',
      recordedAt:
          DateTime.tryParse(map['recordedAt'] as String? ?? '') ??
          DateTime.now(),
      collectorName: map['collectorName'] as String?,
      note: map['note'] as String?,
      pricePerUnit: _toDouble(map['pricePerUnit']) ?? 0,
      billingMonth: map['billingMonth'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      paymentStatus: map['paymentStatus'] as String?,
      proofImagePath: map['proofImagePath'] as String?,
      syncedAt: _toDateTime(map['syncedAt']),
    );
  }

  bool get isSynced => syncStatus == 'synced';

  double? get consumedUnits {
    if (oldReading == null || newReading == null) {
      return null;
    }
    return newReading! - oldReading!;
  }

  Map<String, Object?> toDatabaseMap() {
    return {
      'id': id,
      'customerCode': customerCode,
      'recordType': recordType,
      'oldReading': oldReading,
      'newReading': newReading,
      'amountCollected': amountCollected,
      'syncStatus': syncStatus,
      'recordedAt': recordedAt.toIso8601String(),
      'collectorName': collectorName,
      'note': note,
      'billingMonth': billingMonth,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'proofImagePath': proofImagePath,
      'syncedAt': syncedAt?.toIso8601String(),
    };
  }

  MeterRecord copyWith({
    int? id,
    String? customerCode,
    String? customerName,
    String? address,
    String? areaCode,
    String? areaName,
    String? recordType,
    double? oldReading,
    double? newReading,
    double? amountCollected,
    String? syncStatus,
    DateTime? recordedAt,
    String? collectorName,
    String? note,
    double? pricePerUnit,
    String? billingMonth,
    String? paymentMethod,
    String? paymentStatus,
    String? proofImagePath,
    DateTime? syncedAt,
  }) {
    return MeterRecord(
      id: id ?? this.id,
      customerCode: customerCode ?? this.customerCode,
      customerName: customerName ?? this.customerName,
      address: address ?? this.address,
      areaCode: areaCode ?? this.areaCode,
      areaName: areaName ?? this.areaName,
      recordType: recordType ?? this.recordType,
      oldReading: oldReading ?? this.oldReading,
      newReading: newReading ?? this.newReading,
      amountCollected: amountCollected ?? this.amountCollected,
      syncStatus: syncStatus ?? this.syncStatus,
      recordedAt: recordedAt ?? this.recordedAt,
      collectorName: collectorName ?? this.collectorName,
      note: note ?? this.note,
      pricePerUnit: pricePerUnit ?? this.pricePerUnit,
      billingMonth: billingMonth ?? this.billingMonth,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      proofImagePath: proofImagePath ?? this.proofImagePath,
      syncedAt: syncedAt ?? this.syncedAt,
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
