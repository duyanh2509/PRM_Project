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
import '../services/local_image_service.dart';

class MeterReadingScreen extends StatefulWidget {
  const MeterReadingScreen({super.key, required this.customer});

  final Customer customer;

  @override
  State<MeterReadingScreen> createState() => _MeterReadingScreenState();
}

class _MeterReadingScreenState extends State<MeterReadingScreen> {
  late final TextEditingController _readingController;
  late final TextEditingController _noteController;
  final ImagePicker _imagePicker = ImagePicker();

  File? _proofImage;

  @override
  void initState() {
    super.initState();
    _readingController = TextEditingController();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    _readingController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final oldReading = widget.customer.lastReading ?? 0;
    final newReading =
        double.tryParse(_readingController.text.trim()) ?? oldReading;
    final consumedUnits = (newReading - oldReading).clamp(0.0, double.infinity);
    final estimatedBill = consumedUnits * widget.customer.pricePerUnit;
    final formatter = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );

    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Ghi chỉ số công tơ',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: FilledButton.icon(
            onPressed: _saveRecord,
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
              'Lưu chỉ số mới',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          _SummaryCard(customer: widget.customer),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nhập dữ liệu',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricChip(
                        label: 'Chỉ số cũ',
                        value: '${oldReading.toStringAsFixed(0)} m³',
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricChip(
                        label: 'Đơn giá',
                        value:
                            '${formatter.format(widget.customer.pricePerUnit)} đ',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _readingController,
                  keyboardType: TextInputType.number,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Chỉ số mới',
                    hintText: 'Nhập chỉ số vừa ghi',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _noteController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    labelText: 'Ghi chú hiện trường',
                    hintText: 'Ví dụ: đồng hồ mờ, khách vắng nhà...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _MetricChip(
                        label: 'Tiêu thụ',
                        value: '${consumedUnits.toStringAsFixed(0)} m³',
                        accent: const Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _MetricChip(
                        label: 'Phát sinh',
                        value: '${formatter.format(estimatedBill)} đ',
                        accent: const Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: _pickImage,
            borderRadius: BorderRadius.circular(18),
            child: Ink(
              height: 220,
              decoration: _cardDecoration(),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _proofImage == null
                    ? const Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.add_a_photo_outlined,
                              size: 48,
                              color: Color(0xFF94A3B8),
                            ),
                            SizedBox(height: 8),
                            Text(
                              'Chụp hoặc chọn ảnh đồng hồ',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ],
                        ),
                      )
                    : Image.file(_proofImage!, fit: BoxFit.cover),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _saveRecord() async {
    final rawReading = double.tryParse(_readingController.text.trim());
    final oldReading = widget.customer.lastReading ?? 0;

    if (rawReading == null) {
      _showMessage('Vui lòng nhập chỉ số mới.');
      return;
    }

    if (rawReading < oldReading) {
      _showMessage('Chỉ số mới phải lớn hơn hoặc bằng chỉ số cũ.');
      return;
    }

    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      _showMessage('Không tìm thấy nhân viên đăng nhập.');
      return;
    }

    final historyProvider = context.read<HistoryProvider>();
    final customerListProvider = context.read<CustomerListProvider>();
    final settingsProvider = context.read<SettingsProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    final recordedAt = DateTime.now();
    final record = MeterRecord(
      id: null,
      customerCode: widget.customer.customerCode,
      customerName: widget.customer.customerName,
      address: widget.customer.address,
      areaCode: widget.customer.areaCode,
      areaName: widget.customer.areaName,
      recordType: 'meter',
      oldReading: oldReading,
      newReading: rawReading,
      amountCollected: null,
      syncStatus: 'pending',
      recordedAt: recordedAt,
      collectorName: user.fullName,
      note: _noteController.text.trim(),
      pricePerUnit: widget.customer.pricePerUnit,
      billingMonth: _billingMonth(recordedAt),
      paymentMethod: null,
      paymentStatus: null,
      proofImagePath: _proofImage?.path,
      syncedAt: null,
    );

    await historyProvider.addMeterRecord(user: user, record: record);
    await customerListProvider.loadCustomersForUser(user, forceRefresh: true);
    await settingsProvider.loadForUser(user, forceRefresh: true);

    if (!mounted) {
      return;
    }

    messenger.showSnackBar(
      SnackBar(
        content: Text(
          'Đã lưu chỉ số mới cho khách hàng ${widget.customer.customerCode}',
        ),
      ),
    );
    navigator.pop(true);
  }

  Future<void> _pickImage() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_camera_outlined),
                title: const Text('Chụp ảnh'),
                onTap: () => Navigator.of(context).pop(ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Chọn từ thư viện'),
                onTap: () => Navigator.of(context).pop(ImageSource.gallery),
              ),
            ],
          ),
        );
      },
    );

    if (source == null) {
      return;
    }

    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 65,
      maxWidth: 1024,
    );

    if (picked == null || !mounted) {
      return;
    }

    final proofImage = await LocalImageService.instance.saveProofImage(
      File(picked.path),
      widget.customer.customerCode,
    );
    if (!mounted) {
      return;
    }

    setState(() {
      _proofImage = proofImage;
    });
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _billingMonth(DateTime dateTime) {
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}';
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFFE5EAF3)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.customer});

  final Customer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 24,
            backgroundColor: Color(0xFFEAF2FF),
            child: Icon(Icons.water_drop_outlined, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer.customerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${customer.customerCode} • ${customer.address}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    height: 1.35,
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

class _MetricChip extends StatelessWidget {
  const _MetricChip({
    required this.label,
    required this.value,
    this.accent = const Color(0xFF2563EB),
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
            style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 4),
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
