import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer_model.dart';
import '../models/meter_record_model.dart';
import '../providers/customer_list_provider.dart';
import '../providers/history_provider.dart';
import '../utils/collection_status_helper.dart';
import 'meter_reading_screen.dart';
import 'payment_collection_screen.dart';

class CustomerDetailScreen extends StatelessWidget {
  const CustomerDetailScreen({super.key, required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    final liveCustomer =
        context
            .watch<CustomerListProvider>()
            .customers
            .cast<Customer?>()
            .firstWhere(
              (item) => item?.customerCode == customer.customerCode,
              orElse: () => null,
            ) ??
        customer;
    final historyProvider = context.watch<HistoryProvider>();
    final meterRecords =
        historyProvider.meterRecords
            .where((record) => record.customerCode == liveCustomer.customerCode)
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final paymentRecords =
        historyProvider.paymentRecords
            .where((record) => record.customerCode == liveCustomer.customerCode)
            .toList()
          ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final chartPoints = _buildChartPoints(liveCustomer, meterRecords);
    final galleryItems = _buildGalleryItems(liveCustomer, meterRecords);
    final note = _buildStaffNote(liveCustomer, meterRecords);
    final debt = _DebtSummary(
      amount: liveCustomer.totalDebt,
      isOverdue:
          liveCustomer.debtMonths >= 2 || liveCustomer.totalDebt >= 200000,
    );
    final latestPayment = paymentRecords.isEmpty ? null : paymentRecords.first;
    final collectionStatus = resolveCustomerCollectionStatus(
      customer: liveCustomer,
      meterRecords: meterRecords,
      paymentRecords: paymentRecords,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Chi tiết khách hàng',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
      ),
      bottomNavigationBar: _BottomActionBar(customer: liveCustomer),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ProfileCard(
                customer: liveCustomer,
                collectionStatus: collectionStatus,
              ),
              const SizedBox(height: 16),
              _DebtCard(
                summary: debt,
                latestPaymentDate: liveCustomer.lastPaymentDate,
              ),
              const SizedBox(height: 16),
              _UsageChartCard(points: chartPoints),
              const SizedBox(height: 18),
              _LatestBillingCard(
                customer: liveCustomer,
                latestMeter: meterRecords.isEmpty ? null : meterRecords.first,
                latestPayment: latestPayment,
              ),
              const SizedBox(height: 18),
              const _SectionTitle(
                icon: Icons.photo_camera_outlined,
                title: 'Ảnh công tơ gần nhất',
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 172,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: galleryItems.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return _MeterPhotoCard(item: galleryItems[index]);
                  },
                ),
              ),
              const SizedBox(height: 22),
              const _SectionTitle(
                icon: Icons.description_outlined,
                title: 'Ghi chú nhân viên',
              ),
              const SizedBox(height: 12),
              _StaffNoteCard(note: note),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.customer, required this.collectionStatus});

  final Customer customer;
  final CustomerCollectionStatus collectionStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AvatarBadge(name: customer.customerName),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20242D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TagChip(label: customer.customerCode),
                        const _TagChip(
                          label: 'Đang hoạt động',
                          foreground: Color(0xFF166534),
                          background: Color(0xFFF0FDF4),
                        ),
                        _TagChip(
                          label: collectionStatus.label,
                          foreground: _collectionStatusForeground(
                            collectionStatus.stage,
                          ),
                          background: _collectionStatusBackground(
                            collectionStatus.stage,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      collectionStatus.description,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFF6B7280),
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Địa chỉ',
            value: customer.address,
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _InfoRow(
            icon: Icons.call_outlined,
            label: 'Số điện thoại',
            value: customer.phoneNumber ?? 'Chưa cập nhật',
          ),
          const Divider(height: 24, color: Color(0xFFE5E7EB)),
          _InfoRow(
            icon: Icons.water_drop_outlined,
            label: 'Mã công tơ',
            value:
                'MT-${customer.customerCode.replaceAll(RegExp(r'[^0-9]'), '').padLeft(4, '0')}',
          ),
        ],
      ),
    );
  }
}

Color _collectionStatusBackground(CollectionStage stage) {
  switch (stage) {
    case CollectionStage.paid:
      return const Color(0xFFECFDF5);
    case CollectionStage.partial:
      return const Color(0xFFFFF7ED);
    case CollectionStage.unpaid:
      return const Color(0xFFFEF2F2);
    case CollectionStage.noReading:
      return const Color(0xFFEFF6FF);
  }
}

Color _collectionStatusForeground(CollectionStage stage) {
  switch (stage) {
    case CollectionStage.paid:
      return const Color(0xFF059669);
    case CollectionStage.partial:
      return const Color(0xFFC2410C);
    case CollectionStage.unpaid:
      return const Color(0xFFDC2626);
    case CollectionStage.noReading:
      return const Color(0xFF2563EB);
  }
}

class _DebtCard extends StatelessWidget {
  const _DebtCard({required this.summary, required this.latestPaymentDate});

  final _DebtSummary summary;
  final DateTime? latestPaymentDate;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    ).format(summary.amount);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFFDE2E2)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFFFE4E6),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.account_balance_wallet_outlined,
              color: Color(0xFFEF4444),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Tổng nợ hiện tại',
                  style: TextStyle(
                    color: Color(0xFFFB7185),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$amount VND',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFFEF4444),
                  ),
                ),
                if (latestPaymentDate != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Lần thu gần nhất: ${DateFormat('dd/MM/yyyy').format(latestPaymentDate!)}',
                    style: const TextStyle(color: Color(0xFF6B7280)),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: summary.isOverdue
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF16A34A),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              summary.isOverdue ? 'Quá hạn' : 'Đúng hạn',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UsageChartCard extends StatelessWidget {
  const _UsageChartCard({required this.points});

  final List<_ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Column(
        children: [
          const Row(
            children: [
              Icon(
                Icons.trending_up_rounded,
                color: Color(0xFF3B82F6),
                size: 18,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tiêu thụ nước',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
              ),
              Text(
                'm3/ky',
                style: TextStyle(color: Color(0xFF6B7280), fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(height: 180, child: _UsageChart(points: points)),
        ],
      ),
    );
  }
}

class _UsageChart extends StatelessWidget {
  const _UsageChart({required this.points});

  final List<_ChartPoint> points;

  @override
  Widget build(BuildContext context) {
    final safePoints = points.isEmpty
        ? const [_ChartPoint(label: '--', value: 0)]
        : points;
    final maxValue = safePoints.map((point) => point.value).reduce(math.max);
    final minValue = safePoints.map((point) => point.value).reduce(math.min);
    final topValue = math.max(
      16.0,
      math.min(9999.0, ((maxValue / 4).ceil() * 4).toDouble()),
    );
    final bottomValue = math.max(
      0.0,
      math.min(topValue - 4, ((minValue / 4).floor() * 4).toDouble()),
    );
    final step = math.max(4.0, ((topValue - bottomValue) / 4).ceilToDouble());
    final yValues = List<double>.generate(
      5,
      (index) => bottomValue + step * (4 - index),
    );

    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: yValues
                .map(
                  (value) => Text(
                    value.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: [
              Expanded(
                child: CustomPaint(
                  painter: _UsageChartPainter(
                    points: safePoints,
                    minValue: bottomValue,
                    maxValue: bottomValue + step * 4,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: safePoints
                    .map(
                      (point) => Text(
                        point.label,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4B5563),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _UsageChartPainter extends CustomPainter {
  const _UsageChartPainter({
    required this.points,
    required this.minValue,
    required this.maxValue,
  });

  final List<_ChartPoint> points;
  final double minValue;
  final double maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    const gridColor = Color(0xFFD9E2F0);
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (var i = 0; i < 5; i++) {
      final y = size.height * i / 4;
      _drawDashedLine(canvas, Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final normalizedPoints = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final dx = points.length == 1
          ? size.width / 2
          : size.width * i / (points.length - 1);
      final ratio = maxValue == minValue
          ? 0.5
          : (points[i].value - minValue) / (maxValue - minValue);
      final dy = size.height - (ratio * size.height);
      normalizedPoints.add(Offset(dx, dy.clamp(0, size.height)));
    }

    final path = Path();
    for (var i = 0; i < normalizedPoints.length; i++) {
      final point = normalizedPoints[i];
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
        continue;
      }
      final previous = normalizedPoints[i - 1];
      final controlX = (previous.dx + point.dx) / 2;
      path.cubicTo(
        controlX,
        previous.dy,
        controlX,
        point.dy,
        point.dx,
        point.dy,
      );
    }

    final linePaint = Paint()
      ..color = const Color(0xFF3B82F6)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF2563EB);
    for (final point in normalizedPoints) {
      canvas.drawCircle(point, 3.5, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _UsageChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.minValue != minValue ||
        oldDelegate.maxValue != maxValue;
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashSpace = 6.0;
    final distance = (end - start).distance;
    final direction = distance == 0 ? Offset.zero : (end - start) / distance;
    double drawn = 0;
    while (drawn < distance) {
      final dashStart = start + direction * drawn;
      final dashEnd = start + direction * math.min(drawn + dashWidth, distance);
      canvas.drawLine(dashStart, dashEnd, paint);
      drawn += dashWidth + dashSpace;
    }
  }
}

class _LatestBillingCard extends StatelessWidget {
  const _LatestBillingCard({
    required this.customer,
    required this.latestMeter,
    required this.latestPayment,
  });

  final Customer customer;
  final MeterRecord? latestMeter;
  final MeterRecord? latestPayment;

  @override
  Widget build(BuildContext context) {
    final consumed = latestMeter?.consumedUnits ?? 0;
    final estimated = consumed * customer.pricePerUnit;
    final paid = latestPayment?.amountCollected ?? 0;
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle(
            icon: Icons.receipt_long_outlined,
            title: 'Kỳ ghi gần nhất',
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _ValueCard(
                  label: 'Tiêu thụ',
                  value: '${consumed.toStringAsFixed(0)} m3',
                  color: const Color(0xFF111827),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueCard(
                  label: 'Phát sinh',
                  value: '${formatter.format(estimated)} d',
                  color: const Color(0xFFDC2626),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ValueCard(
                  label: 'Đã thu',
                  value: '${formatter.format(paid)} d',
                  color: const Color(0xFF059669),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
      ],
    );
  }
}

class _MeterPhotoCard extends StatelessWidget {
  const _MeterPhotoCard({required this.item});

  final _GalleryItem item;

  @override
  Widget build(BuildContext context) {
    final imagePath = item.imagePath;
    final imageFile = imagePath == null || _isRemoteImagePath(imagePath)
        ? null
        : File(imagePath);

    return Container(
      width: 172,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: const LinearGradient(
          colors: [Color(0xFFE8EAF2), Color(0xFFDDE1EE)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (imagePath != null && _isInlineImagePath(imagePath))
              Image.memory(
                _decodeInlineImage(imagePath),
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => const _ImagePlaceholder(),
              )
            else if (imagePath != null && _isRemoteImagePath(imagePath))
              CachedNetworkImage(
                imageUrl: imagePath,
                fit: BoxFit.cover,
                placeholder: (_, _) => const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                errorWidget: (_, _, _) => const _ImagePlaceholder(),
              )
            else if (imageFile != null && imageFile.existsSync())
              Image.file(imageFile, fit: BoxFit.cover)
            else
              const _ImagePlaceholder(),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                padding: const EdgeInsets.fromLTRB(10, 24, 10, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0x00000000), Color(0xD9000000)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.dateLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${item.readingLabel} m3',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Icon(Icons.image_outlined, size: 72, color: Color(0xFFB8BAD2)),
    );
  }
}

class _StaffNoteCard extends StatelessWidget {
  const _StaffNoteCard({required this.note});

  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE8EBF2)),
      ),
      child: Text(
        '"$note"',
        style: const TextStyle(
          fontSize: 15,
          height: 1.55,
          fontStyle: FontStyle.italic,
          color: Color(0xFF4B5563),
        ),
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE5EAF3))),
        ),
        child: Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => MeterReadingScreen(customer: customer),
                    ),
                  );
                },
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.photo_camera_outlined),
                label: const Text(
                  'Ghi chỉ số',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          PaymentCollectionScreen(customer: customer),
                    ),
                  );
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF20242D),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: Color(0xFFDCE3EF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.credit_card_outlined),
                label: const Text(
                  'Thu tiền',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AvatarBadge extends StatelessWidget {
  const _AvatarBadge({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 68,
      height: 68,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [Color(0xFFD1D5DB), Color(0xFF9CA3AF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        _initials(name),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: const Color(0xFF6B7280)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  height: 1.35,
                  color: Color(0xFF20242D),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({
    required this.label,
    this.foreground = const Color(0xFF374151),
    this.background = const Color(0xFFF3F4F6),
  });

  final String label;
  final Color foreground;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

class _ValueCard extends StatelessWidget {
  const _ValueCard({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartPoint {
  const _ChartPoint({required this.label, required this.value});

  final String label;
  final double value;
}

class _GalleryItem {
  const _GalleryItem({
    required this.dateLabel,
    required this.readingLabel,
    required this.imagePath,
  });

  final String dateLabel;
  final String readingLabel;
  final String? imagePath;
}

class _DebtSummary {
  const _DebtSummary({required this.amount, required this.isOverdue});

  final double amount;
  final bool isOverdue;
}

List<_ChartPoint> _buildChartPoints(
  Customer customer,
  List<MeterRecord> records,
) {
  final relevantRecords = records
      .where((record) => record.consumedUnits != null)
      .take(6)
      .toList()
      .reversed
      .toList();

  if (relevantRecords.isEmpty) {
    final baseDate = customer.lastReadingDate ?? DateTime.now();
    return [_ChartPoint(label: 'T${baseDate.month}', value: 0)];
  }

  return relevantRecords
      .map(
        (record) => _ChartPoint(
          label: 'T${record.recordedAt.month}',
          value: record.consumedUnits ?? 0,
        ),
      )
      .toList();
}

List<_GalleryItem> _buildGalleryItems(
  Customer customer,
  List<MeterRecord> records,
) {
  final formatter = DateFormat('dd/MM/yyyy');
  final relevant = records.take(3).toList();
  if (relevant.isEmpty) {
    final baseDate = customer.lastReadingDate ?? DateTime.now();
    return [
      _GalleryItem(
        dateLabel: formatter.format(baseDate),
        readingLabel: (customer.lastReading ?? 0).toStringAsFixed(0),
        imagePath: null,
      ),
    ];
  }

  return relevant
      .map(
        (record) => _GalleryItem(
          dateLabel: formatter.format(record.recordedAt),
          readingLabel: (record.newReading ?? record.oldReading ?? 0)
              .toStringAsFixed(0),
          imagePath: record.proofImagePath,
        ),
      )
      .toList();
}

String _buildStaffNote(Customer customer, List<MeterRecord> records) {
  final noteRecord = records.cast<MeterRecord?>().firstWhere(
    (record) => (record?.note ?? '').trim().isNotEmpty,
    orElse: () => null,
  );
  if (noteRecord != null) {
    return noteRecord.note!.trim();
  }
  return 'Chưa có ghi chú hiện trường cho khách hàng này.';
}

bool _isRemoteImagePath(String path) {
  final normalized = path.trim().toLowerCase();
  return normalized.startsWith('http://') || normalized.startsWith('https://');
}

bool _isInlineImagePath(String path) {
  return path.trim().toLowerCase().startsWith('data:image/');
}

Uint8List _decodeInlineImage(String path) {
  final commaIndex = path.indexOf(',');
  if (commaIndex < 0) {
    return Uint8List(0);
  }
  return base64Decode(path.substring(commaIndex + 1));
}

String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();
  if (parts.isEmpty) {
    return 'KH';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
