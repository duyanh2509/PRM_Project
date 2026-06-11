import '../models/customer_model.dart';
import '../models/meter_record_model.dart';

enum CollectionStage {
  noReading,
  unpaid,
  partial,
  paid,
}

class CustomerCollectionStatus {
  const CustomerCollectionStatus({
    required this.stage,
    required this.label,
    required this.description,
    required this.isComplete,
  });

  final CollectionStage stage;
  final String label;
  final String description;
  final bool isComplete;
}

CustomerCollectionStatus resolveCustomerCollectionStatus({
  required Customer customer,
  required List<MeterRecord> meterRecords,
  required List<MeterRecord> paymentRecords,
}) {
  switch (customer.routeStatus) {
    case 'collected':
      return const CustomerCollectionStatus(
        stage: CollectionStage.paid,
        label: 'Thu xong',
        description: 'Đã thu tiền xong trong đợt đi tuyến hiện tại.',
        isComplete: true,
      );
    case 'partial':
      return const CustomerCollectionStatus(
        stage: CollectionStage.partial,
        label: 'Thu chưa xong',
        description: 'Đã thu một phần trong đợt đi tuyến hiện tại.',
        isComplete: false,
      );
    case 'reading_done':
      return const CustomerCollectionStatus(
        stage: CollectionStage.unpaid,
        label: 'Chưa thu',
        description: 'Đã ghi chỉ số nhưng chưa thu tiền trong đợt này.',
        isComplete: false,
      );
    default:
      return const CustomerCollectionStatus(
        stage: CollectionStage.unpaid,
        label: 'Chưa thu',
        description: 'Vừa tải tuyến về, chưa phát sinh thu tiền trong đợt này.',
        isComplete: false,
      );
  }
}
