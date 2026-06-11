import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/customer_list_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.onNavigateToTab});

  final ValueChanged<int> onNavigateToTab;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().currentUser;
      if (user != null) {
        context.read<CustomerListProvider>().loadCustomersForUser(user);
        context.read<HistoryProvider>().loadForUser(user);
        context.read<SettingsProvider>().loadForUser(user);
      }
    });
  }

  void _showComingSoon(String label) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$label đang được phát triển')));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SafeArea(
        bottom: false,
        child:
            Consumer4<
              AuthProvider,
              CustomerListProvider,
              HistoryProvider,
              SettingsProvider
            >(
              builder:
                  (
                    context,
                    authProvider,
                    customerProvider,
                    historyProvider,
                    settingsProvider,
                    child,
                  ) {
                    final user = authProvider.currentUser;
                    if (user == null) {
                      return const Center(
                        child: Text('Không tìm thấy người dùng'),
                      );
                    }

                    final customerCount = customerProvider.customers.length;
                    final meterCount = historyProvider.meterRecords.length;
                    final pendingCount = settingsProvider.pendingSyncCount;
                    final completedCustomerCount = historyProvider.meterRecords
                        .map((record) => record.customerCode)
                        .toSet()
                        .length;
                    final progress = customerCount == 0
                        ? 0.0
                        : (completedCustomerCount / customerCount).clamp(
                            0.0,
                            1.0,
                          );

                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'HydroCollect Pro',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF20242D),
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () => _showComingSoon('Thông báo'),
                                icon: const Icon(
                                  Icons.notifications_none_rounded,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _HeroCard(
                            fullName: user.fullName,
                            areaName: user.areaName,
                            areaCode: user.areaCode,
                            onTap: () => widget.onNavigateToTab(1),
                          ),
                          const SizedBox(height: 16),
                          _SyncBanner(
                            pendingCount: pendingCount,
                            onTap: () => widget.onNavigateToTab(3),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            children: [
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.people_alt_outlined,
                                  value: customerCount == 0
                                      ? '--'
                                      : '$customerCount',
                                  label: 'HỘ GIA ĐÌNH',
                                  iconColor: const Color(0xFF3B82F6),
                                  iconBackground: const Color(0xFFEAF2FF),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.edit_note_rounded,
                                  value: meterCount == 0 ? '--' : '$meterCount',
                                  label: 'BẢN GHI',
                                  iconColor: const Color(0xFF111827),
                                  iconBackground: const Color(0xFFF3F4F6),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _StatCard(
                                  icon: Icons.sync_problem_outlined,
                                  value: '$pendingCount',
                                  label: 'CHƯA GỬI',
                                  iconColor: const Color(0xFFDC2626),
                                  iconBackground: const Color(0xFFFEE2E2),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          _ProgressCard(
                            progress: progress,
                            completedCustomers: completedCustomerCount,
                            totalCustomers: customerCount,
                            pendingCount: pendingCount,
                          ),
                          const SizedBox(height: 22),
                          const Text(
                            'Hành động nhanh',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF20242D),
                            ),
                          ),
                          const SizedBox(height: 14),
                          GridView.count(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            crossAxisCount: 2,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.04,
                            children: [
                              _ActionCard(
                                icon: Icons.file_download_outlined,
                                title: 'Tải dữ liệu',
                                subtitle: 'Mở danh sách hộ gia đình',
                                iconColor: const Color(0xFF3B82F6),
                                iconBackground: const Color(0xFFEAF2FF),
                                highlighted: true,
                                onTap: () => widget.onNavigateToTab(1),
                              ),
                              _ActionCard(
                                icon: Icons.search_rounded,
                                title: 'Tìm khách hàng',
                                subtitle: 'Lọc và tìm theo mã số',
                                iconColor: const Color(0xFF0891B2),
                                iconBackground: const Color(0xFFE9FAFF),
                                onTap: () => widget.onNavigateToTab(1),
                              ),
                              _ActionCard(
                                icon: Icons.history_toggle_off_rounded,
                                title: 'Lịch sử',
                                subtitle: 'Bản ghi ghi số và thu tiền',
                                iconColor: const Color(0xFF16A34A),
                                iconBackground: const Color(0xFFEFFFF3),
                                onTap: () => widget.onNavigateToTab(2),
                              ),
                              _ActionCard(
                                icon: Icons.settings_outlined,
                                title: 'Hệ thống',
                                subtitle: 'Đồng bộ, bộ nhớ đệm, tài khoản',
                                iconColor: const Color(0xFF6B7280),
                                iconBackground: const Color(0xFFF4F4F5),
                                onTap: () => widget.onNavigateToTab(3),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _ContinueCard(onTap: () => widget.onNavigateToTab(1)),
                        ],
                      ),
                    );
                  },
            ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.fullName,
    required this.areaName,
    required this.areaCode,
    required this.onTap,
  });

  final String fullName;
  final String areaName;
  final String areaCode;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(18),
                ),
                alignment: Alignment.center,
                child: Text(
                  _initials(fullName),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nhân viên thu nước',
                      style: TextStyle(color: Color(0xFFBFDBFE), fontSize: 13),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$areaName - $areaCode',
                  style: const TextStyle(
                    color: Color(0xFFE0F2FE),
                    fontSize: 14,
                  ),
                ),
              ),
              FilledButton(
                onPressed: onTap,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF1D4ED8),
                ),
                child: const Text('Mở tuyến'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SyncBanner extends StatelessWidget {
  const _SyncBanner({required this.pendingCount, required this.onTap});

  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EAF4)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.cloud_upload_outlined,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dữ liệu sẵn sàng đồng bộ',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$pendingCount bản ghi đang chờ gửi lên hệ thống',
                  style: const TextStyle(color: Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          TextButton(onPressed: onTap, child: const Text('Xử lý')),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.iconColor,
    required this.iconBackground,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color iconColor;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE9EDF5)),
      ),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 20, color: iconColor),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.iconColor,
    required this.iconBackground,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color iconColor;
  final Color iconBackground;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: highlighted ? const Color(0xFFEFF5FF) : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: highlighted
                  ? const Color(0xFFD7E6FF)
                  : const Color(0xFFE9EDF5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBackground,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const Spacer(),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: highlighted
                      ? const Color(0xFF3B82F6)
                      : const Color(0xFF20242D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF6B7280),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.progress,
    required this.completedCustomers,
    required this.totalCustomers,
    required this.pendingCount,
  });

  final double progress;
  final int completedCustomers;
  final int totalCustomers;
  final int pendingCount;

  @override
  Widget build(BuildContext context) {
    final progressPercent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EDF4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Tiến độ công việc',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Theo dõi nhanh tình trạng ghi chỉ số trong tuyến hôm nay',
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF6B7280),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              SizedBox(
                width: 116,
                height: 116,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 116,
                      height: 116,
                      child: CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 10,
                        backgroundColor: const Color(0xFFE5E7EB),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF3B82F6),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$progressPercent%',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF20242D),
                          ),
                        ),
                        const SizedBox(height: 2),
                        const Text(
                          'Hoàn thành',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  children: [
                    _ProgressMetric(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF16A34A),
                      iconBackground: const Color(0xFFECFDF5),
                      title: 'Đã ghi chỉ số',
                      value: '$completedCustomers/$totalCustomers hộ',
                    ),
                    const SizedBox(height: 12),
                    _ProgressMetric(
                      icon: Icons.cloud_upload_outlined,
                      iconColor: const Color(0xFFDC2626),
                      iconBackground: const Color(0xFFFEF2F2),
                      title: 'Chờ đồng bộ',
                      value: '$pendingCount bản ghi',
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 9,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: const AlwaysStoppedAnimation<Color>(
                Color(0xFF3B82F6),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressMetric extends StatelessWidget {
  const _ProgressMetric({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
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

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
          decoration: BoxDecoration(
            color: const Color(0xFF0F172A),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            children: [
              Icon(Icons.arrow_forward_rounded, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tiếp tục sang danh sách hộ gia đình để ghi chỉ số',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
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

String _initials(String fullName) {
  final parts = fullName
      .trim()
      .split(RegExp(r'\s+'))
      .where((part) => part.isNotEmpty)
      .toList();

  if (parts.isEmpty) {
    return 'U';
  }
  if (parts.length == 1) {
    return parts.first.substring(0, 1).toUpperCase();
  }
  return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
      .toUpperCase();
}
