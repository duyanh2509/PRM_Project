  import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/customer_model.dart';
import '../models/meter_record_model.dart';
import '../models/user_model.dart';
import '../providers/customer_list_provider.dart';
import '../providers/history_provider.dart';
import '../utils/collection_status_helper.dart';
import 'customer_detail_screen.dart';

/// ============================================================================
/// CUSTOMER LIST SCREEN - Danh sách khách hàng
/// ============================================================================
/// CONTROLLERS: _searchController (TextField search)
/// STATE: _isGridView (false = List view, true = Grid view 2 cột)
///
/// METHODS:
/// - didChangeDependencies(): Load HistoryProvider
/// - _refreshCustomers(): Pull-to-refresh → reload CustomerList + History
/// - _buildListView(): Render ListView (dọc)
/// - _buildGridView(): Render GridView (2 cột)
///
/// UI BUILD - Consumer2 (CustomerListProvider + HistoryProvider):
/// - AppBar: Title "Khách hàng" + nút toggle List/Grid view
/// - TextField: Search box (real-time search)
/// - _AreaBanner: Thông tin khu vực + tổng số khách hàng + nút "Tải lại"
/// - RefreshIndicator wrap List/Grid:
///   + _CustomerCard (List view): Card dọc với đầy đủ thông tin
///   + _CustomerGridCard (Grid view): Card vuông thu gọn
/// - Mỗi card hiện: Tên, mã, địa chỉ, chỉ số cũ, công nợ, status badge
/// - Bấm vào card → Navigate to CustomerDetailScreen
/// ============================================================================

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key, required this.user});

  final User user;

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  late final TextEditingController _searchController;
  bool _isGridView = false; // Trạng thái hiển thị: false = List, true = Grid

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    context.read<HistoryProvider>().loadForUser(widget.user);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshCustomers() {
    return Future.wait([
      context.read<CustomerListProvider>().loadCustomersForUser(
        widget.user,
        forceRefresh: true,
      ),
      context.read<HistoryProvider>().loadForUser(
        widget.user,
        forceRefresh: true,
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const Text(
          'Khách hàng',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: Color(0xFF20242D),
          ),
        ),
        actions: [
          // Nút chuyển đổi List/Grid
          IconButton(
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
            icon: Icon(
              _isGridView ? Icons.view_list_rounded : Icons.grid_view_rounded,
              color: const Color(0xFF20242D),
            ),
            tooltip: _isGridView ? 'Xem dạng danh sách' : 'Xem dạng lưới',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Consumer2<CustomerListProvider, HistoryProvider>(
          builder: (context, customerProvider, historyProvider, child) {
            final filteredCustomers = customerProvider.filteredCustomers;
            final meterByCustomer = <String, List<MeterRecord>>{};
            final paymentByCustomer = <String, List<MeterRecord>>{};

            for (final record in historyProvider.meterRecords) {
              meterByCustomer.putIfAbsent(record.customerCode, () => []).add(record);
            }
            for (final record in historyProvider.paymentRecords) {
              paymentByCustomer.putIfAbsent(record.customerCode, () => []).add(record);
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: customerProvider.updateSearchQuery,
                        decoration: InputDecoration(
                          hintText: 'Tìm tên, mã căn hộ, địa chỉ...',
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: customerProvider.searchQuery.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    _searchController.clear();
                                    customerProvider.clearSearch();
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _AreaBanner(
                        areaName: widget.user.areaName,
                        areaCode: widget.user.areaCode,
                        totalCustomers: customerProvider.customers.length,
                        onRefresh: _refreshCustomers,
                        isLoading: customerProvider.isLoading,
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshCustomers,
                    child: Builder(
                      builder: (context) {
                        if (customerProvider.isLoading && customerProvider.customers.isEmpty) {
                          return const Center(child: CircularProgressIndicator());
                        }

                        if (customerProvider.errorMessage != null &&
                            customerProvider.customers.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              _StateMessage(
                                icon: Icons.error_outline_rounded,
                                title: 'Không thể tải dữ liệu',
                                description: customerProvider.errorMessage!,
                              ),
                            ],
                          );
                        }

                        if (filteredCustomers.isEmpty) {
                          return ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              const SizedBox(height: 120),
                              _StateMessage(
                                icon: Icons.people_outline_rounded,
                                title: customerProvider.searchQuery.isEmpty
                                    ? 'Chưa có dữ liệu tuyến'
                                    : 'Không tìm thấy kết quả',
                                description: customerProvider.searchQuery.isEmpty
                                    ? 'Vào tab Hệ thống để tải dữ liệu tuyến về máy.'
                                    : 'Thử tìm bằng mã căn hộ, tên căn hộ hoặc địa chỉ.',
                              ),
                            ],
                          );
                        }

                        // Chuyển đổi giữa List và Grid view
                        return _isGridView
                            ? _buildGridView(filteredCustomers, meterByCustomer, paymentByCustomer)
                            : _buildListView(filteredCustomers, meterByCustomer, paymentByCustomer);
                      },
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

  // Build List View
  Widget _buildListView(
    List<Customer> customers,
    Map<String, List<MeterRecord>> meterByCustomer,
    Map<String, List<MeterRecord>> paymentByCustomer,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: customers.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final customer = customers[index];
        final collectionStatus = resolveCustomerCollectionStatus(
          customer: customer,
          meterRecords: meterByCustomer[customer.customerCode] ?? const [],
          paymentRecords: paymentByCustomer[customer.customerCode] ?? const [],
        );
        return _CustomerCard(
          customer: customer,
          collectionStatus: collectionStatus,
        );
      },
    );
  }

  // Build Grid View
  Widget _buildGridView(
    List<Customer> customers,
    Map<String, List<MeterRecord>> meterByCustomer,
    Map<String, List<MeterRecord>> paymentByCustomer,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2 cột
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.75, // Tỷ lệ width/height
      ),
      itemCount: customers.length,
      itemBuilder: (context, index) {
        final customer = customers[index];
        final collectionStatus = resolveCustomerCollectionStatus(
          customer: customer,
          meterRecords: meterByCustomer[customer.customerCode] ?? const [],
          paymentRecords: paymentByCustomer[customer.customerCode] ?? const [],
        );
        return _CustomerGridCard(
          customer: customer,
          collectionStatus: collectionStatus,
        );
      },
    );
  }
}

class _AreaBanner extends StatelessWidget {
  const _AreaBanner({
    required this.areaName,
    required this.areaCode,
    required this.totalCustomers,
    required this.onRefresh,
    required this.isLoading,
  });

  final String areaName;
  final String areaCode;
  final int totalCustomers;
  final Future<void> Function() onRefresh;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF5FF),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD7E6FF)),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$areaName ($areaCode)',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF20242D),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$totalCustomers căn hộ',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: isLoading ? null : onRefresh,
            child: Text(isLoading ? 'Đang tải...' : 'Tải lại'),
          ),
        ],
      ),
    );
  }
}

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({
    required this.customer,
    required this.collectionStatus,
  });

  final Customer customer;
  final CustomerCollectionStatus collectionStatus;

  @override
  Widget build(BuildContext context) {
    final lastReading = customer.lastReading?.toStringAsFixed(0) ?? '--';
    final debt = customer.totalDebt.toStringAsFixed(0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE9EDF5)),
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
                          customer.customerName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF20242D),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            customer.customerCode,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    alignment: WrapAlignment.end,
                    children: [
                      const _StatusBadge(
                        label: 'Đã tải',
                        backgroundColor: Color(0xFFEFF6FF),
                        foregroundColor: Color(0xFF3B82F6),
                      ),
                      _StatusBadge(
                        label: collectionStatus.label,
                        backgroundColor: _statusBackgroundColor(collectionStatus.stage),
                        foregroundColor: _statusForegroundColor(collectionStatus.stage),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(
                      Icons.location_on_outlined,
                      size: 18,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      customer.address,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF4B5563),
                        height: 1.35,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFE5E7EB)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.speed_outlined,
                      label: 'Chỉ số cũ',
                      value: lastReading,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _InfoChip(
                      icon: Icons.payments_outlined,
                      label: 'Công nợ',
                      value: '$debt d',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Color _statusBackgroundColor(CollectionStage stage) {
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

Color _statusForegroundColor(CollectionStage stage) {
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

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foregroundColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF6B7280)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
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

class _StateMessage extends StatelessWidget {
  const _StateMessage({
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
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          Icon(icon, size: 44, color: const Color(0xFF94A3B8)),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Color(0xFF20242D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

// Grid Card Widget - Dạng lưới
class _CustomerGridCard extends StatelessWidget {
  const _CustomerGridCard({
    required this.customer,
    required this.collectionStatus,
  });

  final Customer customer;
  final CustomerCollectionStatus collectionStatus;

  @override
  Widget build(BuildContext context) {
    final lastReading = customer.lastReading?.toStringAsFixed(0) ?? '--';
    final debt = customer.totalDebt.toStringAsFixed(0);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => CustomerDetailScreen(customer: customer),
            ),
          );
        },
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE9EDF5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Status badges row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _StatusBadge(
                      label: collectionStatus.label,
                      backgroundColor: _statusBackgroundColor(collectionStatus.stage),
                      foregroundColor: _statusForegroundColor(collectionStatus.stage),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      size: 14,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Customer name
              Text(
                customer.customerName,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF20242D),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              
              // Customer code
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  customer.customerCode,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              
              // Address
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.location_on_outlined,
                    size: 14,
                    color: Color(0xFF3B82F6),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      customer.address,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF6B7280),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              
              const Spacer(),
              const Divider(height: 20, color: Color(0xFFE5E7EB)),
              
              // Meter reading info
              Row(
                children: [
                  const Icon(Icons.speed_outlined, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Chỉ số',
                          style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                        Text(
                          lastReading,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20242D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Debt info
              Row(
                children: [
                  const Icon(Icons.payments_outlined, size: 14, color: Color(0xFF6B7280)),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Công nợ',
                          style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF)),
                        ),
                        Text(
                          '$debt đ',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF20242D),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
