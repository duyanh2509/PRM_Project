import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/meter_record_model.dart';
import '../models/user_model.dart';
import '../providers/history_provider.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key, required this.user});

  final User user;

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final TextEditingController _searchController = TextEditingController();
  int _segmentIndex = 0;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HistoryProvider>().loadForUser(widget.user);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() {
    return context.read<HistoryProvider>().loadForUser(
      widget.user,
      forceRefresh: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SafeArea(
        bottom: false,
        child: Consumer<HistoryProvider>(
          builder: (context, historyProvider, child) {
            final baseRecords = _segmentIndex == 0
                ? historyProvider.meterRecords
                : historyProvider.paymentRecords;
            // Show all records, not just current month
            final allRecords = baseRecords;
            final filteredRecords = allRecords.where((record) {
              final keyword = _searchQuery.trim().toLowerCase();
              if (keyword.isEmpty) {
                return true;
              }
              return record.customerName.toLowerCase().contains(keyword) ||
                  record.customerCode.toLowerCase().contains(keyword) ||
                  record.address.toLowerCase().contains(keyword);
            }).toList();

            return Column(
              children: [
                const _ScreenHeader(title: 'Bản ghi thực địa'),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                  child: Column(
                    children: [
                      _SegmentControl(
                        index: _segmentIndex,
                        onChanged: (value) {
                          setState(() {
                            _segmentIndex = value;
                          });
                        },
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _searchQuery = value;
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Tìm khách hàng hoặc mã số...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refresh,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 10, 16, 24),
                      children: [
                        _HistoryOverview(
                          records: allRecords,
                          title: _segmentIndex == 0 ? 'Ghi chỉ số' : 'Thu tiền',
                        ),
                        const SizedBox(height: 14),
                        if (historyProvider.isLoading && allRecords.isEmpty)
                          const Padding(
                            padding: EdgeInsets.only(top: 120),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (historyProvider.errorMessage != null &&
                            allRecords.isEmpty)
                          _EmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Không thể tải lịch sử',
                            description: historyProvider.errorMessage!,
                          )
                        else if (filteredRecords.isEmpty)
                          const _EmptyState(
                            icon: Icons.history_toggle_off_rounded,
                            title: 'Không có bản ghi phù hợp',
                            description:
                                'Thử đổi từ khóa tìm kiếm hoặc chuyển sang tab còn lại.',
                          )
                        else ...[
                          for (final record in filteredRecords) ...[
                            _HistoryCard(
                              record: record,
                              mode: _segmentIndex == 0
                                  ? _HistoryCardMode.meter
                                  : _HistoryCardMode.payment,
                            ),
                            const SizedBox(height: 14),
                          ],
                          const SizedBox(height: 12),
                          const _HistoryFooter(),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ScreenHeader extends StatelessWidget {
  const _ScreenHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF20242D),
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_alt_outlined),
          ),
        ],
      ),
    );
  }
}

class _SegmentControl extends StatelessWidget {
  const _SegmentControl({required this.index, required this.onChanged});

  final int index;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: const Color(0xFFEDEFF3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: _SegmentButton(
              label: 'Ghi chỉ số',
              active: index == 0,
              onTap: () => onChanged(0),
            ),
          ),
          Expanded(
            child: _SegmentButton(
              label: 'Thu tiền',
              active: index == 1,
              onTap: () => onChanged(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 13),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: active ? const Color(0xFF3B82F6) : const Color(0xFF4B5563),
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _HistoryOverview extends StatelessWidget {
  const _HistoryOverview({required this.records, required this.title});

  final List<MeterRecord> records;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20242D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Đã thực hiện ${records.length} bản ghi',
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
            ],
          ),
        ),
        const Row(
          children: [
            Icon(Icons.trending_up_rounded, size: 16, color: Color(0xFF111827)),
            SizedBox(width: 4),
            Text(
              '+15% ca trước',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: Color(0xFF111827),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

enum _HistoryCardMode { meter, payment }

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.record, required this.mode});

  final MeterRecord record;
  final _HistoryCardMode mode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: const Color(0xFFE9EFFB),
                child: Text(
                  record.customerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF3B82F6),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.customerName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF20242D),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      record.customerCode,
                      style: const TextStyle(
                        color: Color(0xFF6B7280),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              _SyncBadge(isSynced: record.isSynced),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.location_on_outlined,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  record.address,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (mode == _HistoryCardMode.meter)
            _MeterReadingPanel(record: record)
          else
            _PaymentPanel(record: record),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 18,
                color: Color(0xFF6B7280),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('HH:mm - dd/MM/yyyy').format(record.recordedAt),
                style: const TextStyle(color: Color(0xFF6B7280), fontSize: 14),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => _openDetail(context),
                child: const Text(
                  'Chi tiết',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _HistoryRecordDetailScreen(record: record, mode: mode),
      ),
    );
  }
}

class _MeterReadingPanel extends StatelessWidget {
  const _MeterReadingPanel({required this.record});

  final MeterRecord record;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E7EE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: _PanelValue(
              label: 'CHỈ SỐ CŨ',
              value: '${record.oldReading?.toStringAsFixed(0) ?? '--'} m³',
              accent: const Color(0xFF111827),
            ),
          ),
          Container(width: 1, height: 72, color: const Color(0xFFE3E7EE)),
          Expanded(
            child: _PanelValue(
              label: 'CHỈ SỐ MỚI',
              value: '${record.newReading?.toStringAsFixed(0) ?? '--'} m³',
              accent: const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentPanel extends StatelessWidget {
  const _PaymentPanel({required this.record});

  final MeterRecord record;

  @override
  Widget build(BuildContext context) {
    final amount = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    ).format(record.amountCollected ?? 0);
    final paymentMeta = _parsePaymentNote(record.note);
    final statusColor = _statusColor(paymentMeta.status);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFE3E7EE)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _PanelValue(
                  label: 'SỐ TIỀN THU',
                  value: '$amount đ',
                  accent: const Color(0xFF3B82F6),
                ),
              ),
              Expanded(
                child: _PanelValue(
                  label: 'TIÊU THỤ',
                  value:
                      '${record.consumedUnits?.toStringAsFixed(0) ?? '--'} m³',
                  accent: const Color(0xFF111827),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _InlineBadge(
                  label: paymentMeta.status,
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  foregroundColor: statusColor,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _InlineBadge(
                  label: paymentMeta.method,
                  backgroundColor: const Color(0xFFF3F4F6),
                  foregroundColor: const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PanelValue extends StatelessWidget {
  const _PanelValue({
    required this.label,
    required this.value,
    required this.accent,
  });

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineBadge extends StatelessWidget {
  const _InlineBadge({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: foregroundColor,
        ),
      ),
    );
  }
}

class _SyncBadge extends StatelessWidget {
  const _SyncBadge({required this.isSynced});

  final bool isSynced;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isSynced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined,
          size: 16,
          color: const Color(0xFF4B5563),
        ),
        const SizedBox(width: 4),
        Text(
          isSynced ? 'ĐÃ ĐỒNG BỘ' : 'CHỜ ĐỒNG BỘ',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: Color(0xFF374151),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 100),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryFooter extends StatelessWidget {
  const _HistoryFooter();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 22, bottom: 12),
      child: Column(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: Color(0xFFF3F4F6),
            child: Icon(Icons.check_rounded, color: Color(0xFF6B7280)),
          ),
          SizedBox(height: 12),
          Text(
            'Bạn đã xem hết lịch sử ghi số',
            style: TextStyle(color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }
}

class _HistoryRecordDetailScreen extends StatelessWidget {
  const _HistoryRecordDetailScreen({required this.record, required this.mode});

  final MeterRecord record;
  final _HistoryCardMode mode;

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.currency(
      locale: 'vi_VN',
      symbol: '',
      decimalDigits: 0,
    );
    final paymentMeta = _parsePaymentNote(record.note);
    final detail = _buildRecordDetail(record, mode, currency, paymentMeta);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: Text(
          detail.screenTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              detail.headerLabel,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              detail.recordCode,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFF20242D),
                              ),
                            ),
                          ],
                        ),
                      ),
                      _InlineBadge(
                        label: detail.statusLabel,
                        backgroundColor: detail.statusColor.withValues(
                          alpha: 0.12,
                        ),
                        foregroundColor: detail.statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: detail.highlightBackground,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      children: [
                        Text(
                          detail.highlightLabel,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          detail.highlightValue,
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w900,
                            color: detail.highlightColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Divider(height: 1, color: Color(0xFFE5E7EB)),
                  const SizedBox(height: 18),
                  _InvoiceInfoRow(
                    label: 'Khách hàng',
                    value: record.customerName,
                  ),
                  _InvoiceInfoRow(
                    label: 'Mã khách hàng',
                    value: record.customerCode,
                  ),
                  _InvoiceInfoRow(label: 'Địa chỉ', value: record.address),
                  _InvoiceInfoRow(
                    label: 'Thời gian',
                    value: DateFormat(
                      'HH:mm:ss - dd/MM/yyyy',
                    ).format(record.recordedAt),
                  ),
                  _InvoiceInfoRow(
                    label: 'Nhân viên',
                    value: record.collectorName ?? 'Chưa cập nhật',
                  ),
                  if (mode == _HistoryCardMode.payment) ...[
                    _InvoiceInfoRow(
                      label: 'Phương thức',
                      value: paymentMeta.method,
                    ),
                    _InvoiceInfoRow(
                      label: 'Tình trạng',
                      value: paymentMeta.status,
                    ),
                  ],
                  _InvoiceInfoRow(
                    label: 'Đồng bộ',
                    value: record.isSynced ? 'Đã đồng bộ' : 'Chờ đồng bộ',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if ((record.proofImagePath ?? '').trim().isNotEmpty) ...[
              _ProofImageCard(imagePath: record.proofImagePath!.trim()),
              const SizedBox(height: 16),
            ],
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Thông tin chỉ số',
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
                        child: _InvoiceMetric(
                          label: 'Chỉ số cũ',
                          value:
                              '${record.oldReading?.toStringAsFixed(0) ?? '--'} m³',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _InvoiceMetric(
                          label: 'Chỉ số mới',
                          value:
                              '${record.newReading?.toStringAsFixed(0) ?? '--'} m³',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _InvoiceMetric(
                    label: 'Tiêu thụ',
                    value:
                        '${record.consumedUnits?.toStringAsFixed(0) ?? '--'} m³',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFFE8EDF4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mode == _HistoryCardMode.payment
                        ? 'Ghi chú thanh toán'
                        : 'Ghi chú bản ghi',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF20242D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    detail.noteText,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Color(0xFF4B5563),
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

class _ProofImageCard extends StatelessWidget {
  const _ProofImageCard({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    final imageFile = _isRemoteImagePath(imagePath) ? null : File(imagePath);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ảnh minh chứng',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: AspectRatio(
              aspectRatio: 4 / 3,
              child: _isInlineImagePath(imagePath)
                  ? Image.memory(
                      _decodeInlineImage(imagePath),
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ProofImagePlaceholder(),
                    )
                  : _isRemoteImagePath(imagePath)
                  ? CachedNetworkImage(
                      imageUrl: imagePath,
                      fit: BoxFit.cover,
                      placeholder: (_, _) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (_, _, _) => const _ProofImagePlaceholder(),
                    )
                  : imageFile != null && imageFile.existsSync()
                  ? Image.file(imageFile, fit: BoxFit.cover)
                  : const _ProofImagePlaceholder(),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProofImagePlaceholder extends StatelessWidget {
  const _ProofImagePlaceholder();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF6F7FB),
      alignment: Alignment.center,
      child: const Icon(
        Icons.image_outlined,
        size: 72,
        color: Color(0xFFB8BAD2),
      ),
    );
  }
}

class _InvoiceInfoRow extends StatelessWidget {
  const _InvoiceInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF20242D),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceMetric extends StatelessWidget {
  const _InvoiceMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF111827),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecordDetailData {
  const _RecordDetailData({
    required this.screenTitle,
    required this.headerLabel,
    required this.recordCode,
    required this.statusLabel,
    required this.statusColor,
    required this.highlightLabel,
    required this.highlightValue,
    required this.highlightColor,
    required this.highlightBackground,
    required this.noteText,
  });

  final String screenTitle;
  final String headerLabel;
  final String recordCode;
  final String statusLabel;
  final Color statusColor;
  final String highlightLabel;
  final String highlightValue;
  final Color highlightColor;
  final Color highlightBackground;
  final String noteText;
}

_RecordDetailData _buildRecordDetail(
  MeterRecord record,
  _HistoryCardMode mode,
  NumberFormat currency,
  _PaymentNoteInfo paymentMeta,
) {
  if (mode == _HistoryCardMode.payment) {
    final amount = currency.format(record.amountCollected ?? 0);
    final statusColor = _statusColor(paymentMeta.status);
    return _RecordDetailData(
      screenTitle: 'Chi tiết hóa đơn',
      headerLabel: 'HÓA ĐƠN THU TIỀN',
      recordCode: _buildHistoryCode(prefix: 'HD', record: record),
      statusLabel: paymentMeta.status,
      statusColor: statusColor,
      highlightLabel: 'SỐ TIỀN GHI NHẬN',
      highlightValue: '$amount đ',
      highlightColor: const Color(0xFF2563EB),
      highlightBackground: const Color(0xFFEFF6FF),
      noteText: paymentMeta.note,
    );
  }

  final consumedUnits = record.consumedUnits?.toStringAsFixed(0) ?? '--';
  return _RecordDetailData(
    screenTitle: 'Chi tiết ghi chỉ số',
    headerLabel: 'PHIẾU GHI CHỈ SỐ',
    recordCode: _buildHistoryCode(prefix: 'GS', record: record),
    statusLabel: 'Đã ghi chỉ số',
    statusColor: const Color(0xFF3B82F6),
    highlightLabel: 'SẢN LƯỢNG GHI NHẬN',
    highlightValue: '$consumedUnits m³',
    highlightColor: const Color(0xFF2563EB),
    highlightBackground: const Color(0xFFEFF6FF),
    noteText: record.note?.trim().isNotEmpty == true
        ? record.note!.trim()
        : 'Không có ghi chú thêm.',
  );
}

String _buildHistoryCode({
  required String prefix,
  required MeterRecord record,
}) {
  final datePart = DateFormat('yyyyMMddHHmmss').format(record.recordedAt);
  final idPart = (record.id ?? 0).toString().padLeft(4, '0');
  return '$prefix-$datePart-${record.customerCode}-$idPart';
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

Color _statusColor(String status) {
  final normalized = status.toLowerCase();
  if (normalized.contains('đã thu') || normalized.contains('da thu')) {
    return const Color(0xFF059669);
  }
  if (normalized.contains('một phần') || normalized.contains('mot phan')) {
    return const Color(0xFFD97706);
  }
  if (normalized.contains('hẹn lại') || normalized.contains('hen lai')) {
    return const Color(0xFFDC2626);
  }
  if (normalized.contains('miễn giảm') || normalized.contains('mien giam')) {
    return const Color(0xFF7C3AED);
  }
  return const Color(0xFF2563EB);
}

_PaymentNoteInfo _parsePaymentNote(String? note) {
  if (note == null || note.trim().isEmpty) {
    return const _PaymentNoteInfo(
      status: 'Đã thu đủ',
      method: 'Tiền mặt',
      note: 'Không có ghi chú thêm.',
    );
  }

  final parts = note
      .split('|')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();

  final status = parts.isNotEmpty ? parts.first : 'Đã thu đủ';
  final method = parts.length > 1 ? parts[1] : 'Tiền mặt';
  final customNote = parts.length > 2
      ? parts.sublist(2).join(' | ')
      : 'Không có ghi chú thêm.';

  return _PaymentNoteInfo(status: status, method: method, note: customNote);
}

class _PaymentNoteInfo {
  const _PaymentNoteInfo({
    required this.status,
    required this.method,
    required this.note,
  });

  final String status;
  final String method;
  final String note;
}
