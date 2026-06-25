import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/customer_model.dart';
import '../models/meter_record_model.dart';
import '../providers/auth_provider.dart';
import '../providers/customer_list_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';

class PaymentCollectionScreen extends StatefulWidget {
  const PaymentCollectionScreen({super.key, required this.customer});

  final Customer customer;

  @override
  State<PaymentCollectionScreen> createState() => _PaymentCollectionScreenState();
}

class _PaymentCollectionScreenState extends State<PaymentCollectionScreen> {
  late final TextEditingController _amountController;
  late final TextEditingController _noteController;
  final ImagePicker _imagePicker = ImagePicker();

  String _paymentMethod = 'Tiền mặt';
  String _paymentStatus = 'Đã thu đủ';
  File? _proofImage;
  bool _isVerified = false;

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final historyProvider = context.watch<HistoryProvider>();
    final meterRecords = historyProvider.meterRecords
        .where((record) => record.customerCode == widget.customer.customerCode)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final dueAmount = widget.customer.totalDebt;
    final collectedAmount = _parseCurrency(_amountController.text);
    final remainingAmount = (dueAmount - collectedAmount).clamp(
      0.0,
      double.infinity,
    );
    final currentMonthAmount = _resolveCurrentMonthAmount(
      meterRecords: meterRecords,
      totalDebt: dueAmount,
      pricePerUnit: widget.customer.pricePerUnit,
    );
    final previousDebtAmount = (dueAmount - currentMonthAmount).clamp(
      0.0,
      double.infinity,
    );
    final latestReading =
        meterRecords.isNotEmpty
            ? (meterRecords.first.newReading ??
                meterRecords.first.oldReading ??
                widget.customer.lastReading ??
                0)
            : (widget.customer.lastReading ?? 0);
    final currentPeriod = _buildCurrentPeriod(
      meterRecords.isNotEmpty
          ? meterRecords.first.recordedAt
          : (widget.customer.lastReadingDate ?? DateTime.now()),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 0,
        title: const Text(
          'Nhập thông tin thu tiền',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).maybePop(),
            child: const Text(
              'Hủy',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _savePayment(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.save_outlined),
                  label: const Text(
                    'Lưu thanh toán (Offline)',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Dấu thời gian: ${DateFormat('HH:mm:ss d/M/yyyy').format(DateTime.now())}',
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            _CustomerSummaryCard(
              customer: widget.customer,
              dueAmount: dueAmount,
              previousDebtAmount: previousDebtAmount,
              currentMonthAmount: currentMonthAmount,
              currentPeriod: currentPeriod,
            ),
            const SizedBox(height: 18),
            const _SectionHeading(
              title: 'Hình ảnh minh chứng',
              requiredMark: true,
            ),
            const SizedBox(height: 10),
            _ReceiptProofCard(
              imageFile: _proofImage,
              isVerified: _isVerified,
              onTap: _selectProofImage,
            ),
            const SizedBox(height: 18),
            _PaymentDataCard(
              currentReading: latestReading,
              dueAmount: dueAmount,
              previousDebtAmount: previousDebtAmount,
              currentMonthAmount: currentMonthAmount,
              currentPeriod: currentPeriod,
              collectedAmount: collectedAmount,
              remainingAmount: remainingAmount,
              amountController: _amountController,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            _StatusNoteCard(
              paymentMethod: _paymentMethod,
              paymentStatus: _paymentStatus,
              noteController: _noteController,
              onMethodChanged: (value) {
                setState(() {
                  _paymentMethod = value;
                });
              },
              onStatusChanged: (value) {
                setState(() {
                  _paymentStatus = value;
                });
              },
            ),
            const SizedBox(height: 18),
            const _OfflineInfoCard(),
          ],
        ),
      ),
    );
  }

  Future<void> _savePayment(BuildContext context) async {
    final amountCollected = _parseCurrency(_amountController.text);
    if (amountCollected <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập số tiền đã thu.')),
      );
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Không tìm thấy nhân viên đăng nhập.')),
      );
      return;
    }

    final historyProvider = context.read<HistoryProvider>();
    final meterRecords = historyProvider.meterRecords
        .where((record) => record.customerCode == widget.customer.customerCode)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final latestMeter = meterRecords.isNotEmpty ? meterRecords.first : null;

    await historyProvider.addPaymentRecord(
      user: user,
      record: MeterRecord(
        id: null,
        customerCode: widget.customer.customerCode,
        customerName: widget.customer.customerName,
        address: widget.customer.address,
        areaCode: widget.customer.areaCode,
        areaName: widget.customer.areaName,
        recordType: 'payment',
        oldReading: latestMeter?.oldReading ?? widget.customer.lastReading,
        newReading:
            latestMeter?.newReading ??
            latestMeter?.oldReading ??
            widget.customer.lastReading,
        amountCollected: amountCollected,
        syncStatus: 'pending',
        recordedAt: DateTime.now(),
        collectorName: user.fullName,
        note: [
          _paymentStatus,
          _paymentMethod,
          _noteController.text.trim(),
        ].where((part) => part.isNotEmpty).join(' | '),
        pricePerUnit: widget.customer.pricePerUnit,
        billingMonth: _buildBillingMonth(DateTime.now()),
        paymentMethod: _paymentMethod,
        paymentStatus: _paymentStatus,
        proofImagePath: _proofImage?.path,
        syncedAt: null,
      ),
    );
    await context.read<CustomerListProvider>().loadCustomersForUser(
      user,
      forceRefresh: true,
    );
    final settingsProvider = context.read<SettingsProvider>();
    await settingsProvider.loadForUser(user, forceRefresh: true);

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu thông tin thu tiền cho khách hàng ${widget.customer.customerCode}',
        ),
      ),
    );
    Navigator.of(context).pop(true);
  }

  Future<void> _selectProofImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Chọn hình ảnh minh chứng',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 16),
                _ImageSourceTile(
                  icon: Icons.photo_camera_outlined,
                  title: 'Chụp ảnh',
                  subtitle: 'Mở camera để chụp minh chứng mới',
                  onTap: () => Navigator.of(context).pop(ImageSource.camera),
                ),
                const SizedBox(height: 10),
                _ImageSourceTile(
                  icon: Icons.photo_library_outlined,
                  title: 'Tải từ thiết bị',
                  subtitle: 'Chọn ảnh có sẵn trong bộ nhớ máy',
                  onTap: () => Navigator.of(context).pop(ImageSource.gallery),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final pickedFile = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
      maxWidth: 1600,
    );

    if (pickedFile == null || !mounted) {
      return;
    }

    setState(() {
      _proofImage = File(pickedFile.path);
      _isVerified = true;
    });
  }
}

class _CustomerSummaryCard extends StatelessWidget {
  const _CustomerSummaryCard({
    required this.customer,
    required this.dueAmount,
    required this.previousDebtAmount,
    required this.currentMonthAmount,
    required this.currentPeriod,
  });

  final Customer customer;
  final double dueAmount;
  final double previousDebtAmount;
  final double currentMonthAmount;
  final String currentPeriod;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 104,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'KHÁCH HÀNG',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  customer.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Mã: ${customer.customerCode}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
                const SizedBox(height: 12),
                _BreakdownLine(
                  label: 'Nợ kỳ trước',
                  value: '${formatter.format(previousDebtAmount)} đ',
                  valueColor: const Color(0xFFB45309),
                ),
                const SizedBox(height: 6),
                _BreakdownLine(
                  label: 'Tiền nước kỳ này',
                  value: '${formatter.format(currentMonthAmount)} đ',
                  valueColor: const Color(0xFF1D4ED8),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'CÔNG NỢ HIỆN TẠI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7280),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                formatter.format(dueAmount),
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Color(0xFF3B82F6),
                ),
              ),
              const SizedBox(height: 2),
              const Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'VND',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFFDCE3EF)),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  currentPeriod,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF374151),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  const _SectionHeading({required this.title, this.requiredMark = false});

  final String title;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
        if (requiredMark)
          const Text(
            ' *',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Color(0xFFEF4444),
            ),
          ),
      ],
    );
  }
}

class _ReceiptProofCard extends StatelessWidget {
  const _ReceiptProofCard({
    required this.imageFile,
    required this.isVerified,
    required this.onTap,
  });

  final File? imageFile;
  final bool isVerified;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          height: 300,
          decoration: BoxDecoration(
            color: const Color(0xFFF6F7FB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFD6DBE6)),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: imageFile == null
                      ? const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 96,
                            color: Color(0xFFBBBFD8),
                          ),
                        )
                      : Image.file(imageFile!, fit: BoxFit.cover),
                ),
              ),
              Positioned(
                top: 14,
                right: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        isVerified
                            ? Icons.verified_outlined
                            : Icons.add_a_photo_outlined,
                        size: 16,
                        color: const Color(0xFF111827),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isVerified ? 'Đã xác thực' : 'Chọn hình ảnh',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF111827),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (imageFile == null)
                const Positioned(
                  left: 0,
                  right: 0,
                  bottom: 20,
                  child: Text(
                    'Chạm để chụp ảnh hoặc tải từ thiết bị',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ImageSourceTile extends StatelessWidget {
  const _ImageSourceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5EAF3)),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFEAF2FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: const Color(0xFF3B82F6)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF20242D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDataCard extends StatelessWidget {
  const _PaymentDataCard({
    required this.currentReading,
    required this.dueAmount,
    required this.previousDebtAmount,
    required this.currentMonthAmount,
    required this.currentPeriod,
    required this.collectedAmount,
    required this.remainingAmount,
    required this.amountController,
    required this.onChanged,
  });

  final double currentReading;
  final double dueAmount;
  final double previousDebtAmount;
  final double currentMonthAmount;
  final String currentPeriod;
  final double collectedAmount;
  final double remainingAmount;
  final TextEditingController amountController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline_rounded, size: 18, color: Color(0xFF3B82F6)),
              SizedBox(width: 8),
              Text(
                'SỐ LIỆU HIỆN TẠI',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DataMetric(
                  label: 'Chỉ số gần nhất',
                  value: '${currentReading.toStringAsFixed(0)} m³',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _DataMetric(
                  label: 'Tổng phải thu',
                  value: '${formatter.format(dueAmount)} đ',
                  accent: const Color(0xFFEF4444),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _AmountBreakdownRow(
                  label: 'Nợ tháng trước',
                  value: '${formatter.format(previousDebtAmount)} đ',
                  valueColor: const Color(0xFFB45309),
                ),
                const SizedBox(height: 10),
                _AmountBreakdownRow(
                  label: 'Tiền nước tháng này ($currentPeriod)',
                  value: '${formatter.format(currentMonthAmount)} đ',
                  valueColor: const Color(0xFF1D4ED8),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Divider(height: 1),
                ),
                _AmountBreakdownRow(
                  label: 'Tổng cộng',
                  value: '${formatter.format(dueAmount)} đ',
                  valueColor: const Color(0xFFDC2626),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Số tiền thu (VNĐ)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Nhập số tiền khách thanh toán',
              hintStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF9CA3AF),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 18,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD2D8E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD2D8E5)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Đã nhập: ${formatter.format(collectedAmount)} đ',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4B5563),
                  ),
                ),
              ),
              Text(
                'Còn lại: ${formatter.format(remainingAmount)} đ',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFEF4444),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DataMetric extends StatelessWidget {
  const _DataMetric({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF20242D),
  });

  final String label;
  final String value;
  final Color accent;

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
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownLine extends StatelessWidget {
  const _BreakdownLine({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _AmountBreakdownRow extends StatelessWidget {
  const _AmountBreakdownRow({
    required this.label,
    required this.value,
    required this.valueColor,
    this.isBold = false,
  });

  final String label;
  final String value;
  final Color valueColor;
  final bool isBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
              color: const Color(0xFF374151),
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 16 : 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}

class _StatusNoteCard extends StatelessWidget {
  const _StatusNoteCard({
    required this.paymentMethod,
    required this.paymentStatus,
    required this.noteController,
    required this.onMethodChanged,
    required this.onStatusChanged,
  });

  final String paymentMethod;
  final String paymentStatus;
  final TextEditingController noteController;
  final ValueChanged<String> onMethodChanged;
  final ValueChanged<String> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'TÌNH TRẠNG & GHI CHÚ',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Phương thức thanh toán',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final method in const [
                'Tiền mặt',
                'Chuyển khoản',
                'Ví điện tử',
              ])
                _ChoiceChip(
                  label: method,
                  selected: paymentMethod == method,
                  onTap: () => onMethodChanged(method),
                ),
            ],
          ),
          const SizedBox(height: 18),
          const Text(
            'Tình trạng thanh toán',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final status in const [
                'Đã thu đủ',
                'Thu một phần',
                'Hẹn lại',
                'Miễn giảm',
              ])
                _ChoiceChip(
                  label: status,
                  selected: paymentStatus == status,
                  onTap: () => onStatusChanged(status),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: noteController,
            maxLines: 4,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            textCapitalization: TextCapitalization.sentences,
            enableSuggestions: true,
            autocorrect: true,
            decoration: InputDecoration(
              hintText: 'Nhập ghi chú chi tiết cho giao dịch thu tiền...',
              alignLabelWithHint: true,
              contentPadding: const EdgeInsets.all(14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD2D8E5)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFD2D8E5)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  const _ChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFF3B82F6) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? const Color(0xFF3B82F6) : const Color(0xFFD6DCE8),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : const Color(0xFF374151),
          ),
        ),
      ),
    );
  }
}

class _OfflineInfoCard extends StatelessWidget {
  const _OfflineInfoCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: Color(0xFF3B82F6),
            child: Icon(Icons.offline_bolt_rounded, size: 14, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chế độ Ngoại tuyến',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1D4ED8),
                  ),
                ),
                SizedBox(height: 6),
                Text(
                  'Dữ liệu sẽ được lưu tạm trên thiết bị này và tự động đồng bộ khi có kết nối mạng ổn định.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.45,
                    color: Color(0xFF2563EB),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

double _parseCurrency(String raw) {
  final normalized = raw.replaceAll(RegExp(r'[^0-9.]'), '');
  return double.tryParse(normalized) ?? 0;
}

String _buildCurrentPeriod(DateTime dateTime) {
  return 'T${dateTime.month.toString().padLeft(2, '0')}/${dateTime.year}';
}

String _buildBillingMonth(DateTime dateTime) {
  return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}';
}

double _resolveCurrentMonthAmount({
  required List<MeterRecord> meterRecords,
  required double totalDebt,
  required double pricePerUnit,
}) {
  if (meterRecords.isEmpty) {
    return 0;
  }

  final latestMeter = meterRecords.first;
  final consumedUnits = latestMeter.consumedUnits ?? 0;
  final currentMonthAmount = (consumedUnits.clamp(0.0, double.infinity)) * pricePerUnit;
  return currentMonthAmount.clamp(0.0, totalDebt);
}
