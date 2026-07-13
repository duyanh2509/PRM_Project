import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/customer_list_provider.dart';
import '../providers/history_provider.dart';
import '../providers/settings_provider.dart';
import 'login_screen.dart';

/// ============================================================================
/// SETTINGS SCREEN - Màn hình Hệ thống
/// ============================================================================
/// METHODS:
/// - _handleLogout(context): Hiện dialog xác nhận → logout → navigate to LoginScreen
/// - _download(context): Gọi downloadLatestRoute → reload providers → show message
/// - _sync(context): Gọi syncNow → reload providers → show message
/// - _clearCache(context): Gọi clearCache → reload providers
///
/// UI BUILD - Consumer2 (AuthProvider + SettingsProvider):
/// - Header: Title "Hệ thống và dữ liệu" + IconButton toggle Online/Offline
/// - _ProfileCard: Avatar, tên NV, mã NV, khu vực, tag "Trực tuyến"/"Ngoại tuyến"
/// - _StatusCard: 4 metrics (Khách hàng đã tải / Bản ghi chờ sync / Bộ nhớ đệm / Lần sync cuối)
/// - _ActionPanel:
///   + FilledButton "Tải dữ liệu tuyến" (disable khi offline/downloading)
///   + OutlinedButton "Đồng bộ lên máy chủ" (disable khi offline/syncing)
/// - _OptionsPanel: ListTile "Xóa bộ nhớ đệm"
/// - _MessageCard: Hiện statusMessage nếu có
/// - _LogoutCard: Nút đăng xuất (màu đỏ)
/// ============================================================================

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  Future<void> _handleLogout(BuildContext context) async {
    final navigator = Navigator.of(context);
    final authProvider = context.read<AuthProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Đăng xuất'),
        content: const Text('Bạn có chắc muốn thoát khỏi hệ thống?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Đăng xuất'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await authProvider.logout();
      if (mounted) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  Future<void> _download(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final customerListProvider = context.read<CustomerListProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await settingsProvider.downloadLatestRoute(user);
      await customerListProvider.loadCustomersForUser(user, forceRefresh: true);
      await historyProvider.loadForUser(user, forceRefresh: true);
      if (!mounted) {
        return;
      }
      _showMessage(
        messenger,
        settingsProvider.statusMessage ?? 'Đã tải dữ liệu.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showMessage(messenger, e.toString());
    }
  }

  Future<void> _sync(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return;
    }

    final settingsProvider = context.read<SettingsProvider>();
    final customerListProvider = context.read<CustomerListProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    try {
      await settingsProvider.syncNow(user);
      await customerListProvider.loadCustomersForUser(user, forceRefresh: true);
      await historyProvider.loadForUser(user, forceRefresh: true);
      if (!mounted) {
        return;
      }
      _showMessage(
        messenger,
        settingsProvider.statusMessage ?? 'Đã đồng bộ dữ liệu.',
      );
    } catch (e) {
      if (!mounted) {
        return;
      }
      _showMessage(messenger, e.toString());
    }
  }

  Future<void> _clearCache(BuildContext context) async {
    final user = context.read<AuthProvider>().currentUser;
    if (user == null) {
      return;
    }
    final settingsProvider = context.read<SettingsProvider>();
    final customerListProvider = context.read<CustomerListProvider>();
    final historyProvider = context.read<HistoryProvider>();
    final messenger = ScaffoldMessenger.of(context);

    await settingsProvider.clearCache();
    await customerListProvider.loadCustomersForUser(user, forceRefresh: true);
    await historyProvider.loadForUser(user, forceRefresh: true);
    if (!mounted) {
      return;
    }
    _showMessage(messenger, settingsProvider.statusMessage ?? 'Đã xóa cache.');
  }

  void _showMessage(ScaffoldMessengerState messenger, String message) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF5F7FB),
      child: SafeArea(
        bottom: false,
        child: Consumer2<AuthProvider, SettingsProvider>(
          builder: (context, authProvider, settingsProvider, child) {
            final user = authProvider.currentUser;
            if (user == null) {
              return const Center(child: Text('Không tìm thấy người dùng'));
            }

            final employeeCode =
                'NV-${(user.id ?? 0).toString().padLeft(4, '0')}-${user.areaCode}';
            final lastSyncText = settingsProvider.lastSyncAt == null
                ? 'Chưa có'
                : DateFormat(
                    'HH:mm dd/MM/yyyy',
                  ).format(settingsProvider.lastSyncAt!);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hệ thống và dữ liệu',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF20242D),
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: settingsProvider.toggleOnline,
                      icon: Icon(
                        settingsProvider.isOnline
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                _ProfileCard(
                  fullName: user.fullName,
                  employeeCode: employeeCode,
                  areaName: user.areaName,
                  isOnline: settingsProvider.isOnline,
                ),
                const SizedBox(height: 18),
                _StatusCard(
                  downloadedCustomerCount:
                      settingsProvider.downloadedCustomerCount,
                  pendingSyncCount: settingsProvider.pendingSyncCount,
                  cacheSizeMb: settingsProvider.cacheSizeMb,
                  lastSyncText: lastSyncText,
                ),
                const SizedBox(height: 18),
                _ActionPanel(
                  isDownloading: settingsProvider.isDownloading,
                  isSyncing: settingsProvider.isSyncing,
                  isOnline: settingsProvider.isOnline,
                  onDownload: () => _download(context),
                  onSync: () => _sync(context),
                ),
                const SizedBox(height: 18),
                _OptionsPanel(
                  cacheSizeMb: settingsProvider.cacheSizeMb,
                  onClearCache: () => _clearCache(context),
                ),
                if ((settingsProvider.statusMessage ?? '').isNotEmpty) ...[
                  const SizedBox(height: 18),
                  _MessageCard(message: settingsProvider.statusMessage!),
                ],
                const SizedBox(height: 18),
                _LogoutCard(onTap: () => _handleLogout(context)),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.fullName,
    required this.employeeCode,
    required this.areaName,
    required this.isOnline,
  });

  final String fullName;
  final String employeeCode;
  final String areaName;
  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 28,
            backgroundColor: Color(0xFFEAF2FF),
            child: Icon(Icons.engineering_rounded, color: Color(0xFF2563EB)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fullName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 4),
                Text('Ma NV: $employeeCode'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _Tag(label: areaName, background: const Color(0xFFF3F4F6)),
                    _Tag(
                      label: isOnline ? 'Truc tuyen' : 'Ngoai tuyen',
                      background: isOnline
                          ? const Color(0xFFECFDF5)
                          : const Color(0xFFFEF2F2),
                      foreground: isOnline
                          ? const Color(0xFF166534)
                          : const Color(0xFFB91C1C),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.downloadedCustomerCount,
    required this.pendingSyncCount,
    required this.cacheSizeMb,
    required this.lastSyncText,
  });

  final int downloadedCustomerCount;
  final int pendingSyncCount;
  final int cacheSizeMb;
  final String lastSyncText;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Khách hàng đã tải',
                  value: '$downloadedCustomerCount',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(
                  label: 'Ban ghi cho sync',
                  value: '$pendingSyncCount',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _MetricTile(
                  label: 'Bo nho dem',
                  value: '$cacheSizeMb MB',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _MetricTile(label: 'Lan sync cuoi', value: lastSyncText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionPanel extends StatelessWidget {
  const _ActionPanel({
    required this.isDownloading,
    required this.isSyncing,
    required this.isOnline,
    required this.onDownload,
    required this.onSync,
  });

  final bool isDownloading;
  final bool isSyncing;
  final bool isOnline;
  final VoidCallback onDownload;
  final VoidCallback onSync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dữ liệu tuyến',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isOnline
                ? 'Có thể tải toàn bộ dữ liệu tuyến và đồng bộ bản ghi mới lên máy chủ.'
                : 'Đang ngoại tuyến. Bạn vẫn có thể ghi chỉ số, thu tiền, sau đó đồng bộ khi online trở lại.',
            style: const TextStyle(color: Color(0xFF6B7280), height: 1.4),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isDownloading || !isOnline ? null : onDownload,
              icon: isDownloading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.cloud_download_outlined),
              label: Text(
                isDownloading ? 'Đang tải dữ liệu...' : 'Tải dữ liệu tuyến',
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isSyncing || !isOnline ? null : onSync,
              icon: isSyncing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.sync_rounded),
              label: Text(
                isSyncing ? 'Đang đồng bộ...' : 'Đồng bộ lên máy chủ',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OptionsPanel extends StatelessWidget {
  const _OptionsPanel({required this.cacheSizeMb, required this.onClearCache});

  final int cacheSizeMb;
  final VoidCallback onClearCache;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5EAF3)),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.storage_rounded),
            title: const Text('Xóa bộ nhớ đệm'),
            subtitle: Text('Giải phóng cache cục bộ ($cacheSizeMb MB)'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: onClearCache,
          ),
        ],
      ),
    );
  }
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFBFDBFE)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: Color(0xFF1D4ED8), height: 1.4),
      ),
    );
  }
}

class _MetricTile extends StatelessWidget {
  const _MetricTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
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
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
        ],
      ),
    );
  }
}

class _LogoutCard extends StatelessWidget {
  const _LogoutCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFFE5EAF3)),
        ),
        child: const Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFFFDECEC),
              child: Icon(Icons.logout_rounded, color: Color(0xFFEF4444)),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Text(
                'Đăng xuất khỏi hệ thống',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFEF4444),
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF)),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({
    required this.label,
    required this.background,
    this.foreground = const Color(0xFF374151),
  });

  final String label;
  final Color background;
  final Color foreground;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
