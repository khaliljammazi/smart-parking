import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../authentication/auth_provider.dart';
import '../utils/constanst.dart';
import 'admin_service.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _revenueData;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final dashboardData = await AdminService.getDashboardData();
      final revenueData = await AdminService.getRevenueData();

      if (mounted) {
        setState(() {
          _dashboardData = dashboardData;
          _revenueData = revenueData;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading dashboard: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.userProfile;

    if (user?['role'] != 'admin') {
      return Scaffold(
        body: const Center(
          child: Text('Access denied. Admin privileges required.'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: const Text('Admin Dashboard', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () => authProvider.logout(),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardData,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Statistics Cards
                    if (_dashboardData != null) ...[
                      const Text(
                        'Overview',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.navy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatisticsGrid(_dashboardData!['statistics']),
                      const SizedBox(height: 32),
                    ],

                    // Revenue Section
                    if (_revenueData != null) ...[
                      const Text(
                        'Revenue Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColor.navy,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildRevenueSummary(_revenueData!['summary']),
                      const SizedBox(height: 16),
                      _buildRevenueByParking(_revenueData!['revenueByParking']),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatisticsGrid(Map<String, dynamic> statistics) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        _buildStatCard(
          'Total Users',
          statistics['totalUsers']?.toString() ?? '0',
          Icons.people,
          Colors.blue,
        ),
        _buildStatCard(
          'Total Parkings',
          statistics['totalParkings']?.toString() ?? '0',
          Icons.local_parking,
          Colors.green,
        ),
        _buildStatCard(
          'Total Bookings',
          statistics['totalBookings']?.toString() ?? '0',
          Icons.book_online,
          Colors.orange,
        ),
        _buildStatCard(
          'Active Bookings',
          statistics['activeBookings']?.toString() ?? '0',
          Icons.access_time,
          Colors.red,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueSummary(Map<String, dynamic> summary) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    'Total Revenue',
                    '${summary['totalRevenue']?.toStringAsFixed(2) ?? '0'} DT',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRevenueItem(
                    'Avg per Booking',
                    '${summary['averageRevenue']?.toStringAsFixed(2) ?? '0'} DT',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueItem(
                    'Total Bookings',
                    summary['totalBookings']?.toString() ?? '0',
                    Icons.receipt,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildRevenueItem(
                    'Period',
                    _formatPeriod(summary['period']),
                    Icons.calendar_today,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildRevenueByParking(List<dynamic> revenueByParking) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue by Parking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            if (revenueByParking.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No revenue data available'),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: revenueByParking.length,
                itemBuilder: (context, index) {
                  final parking = revenueByParking[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.orange,
                      child: Text(
                        (index + 1).toString(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(parking['name'] ?? 'Unknown Parking'),
                    subtitle: Text('${parking['bookingCount']} bookings'),
                    trailing: Text(
                      '${parking['totalRevenue']?.toStringAsFixed(2) ?? '0'} DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(Map<String, dynamic>? period) {
    if (period == null) return 'N/A';
    final start = DateTime.parse(period['start']);
    final end = DateTime.parse(period['end']);
    return '${start.day}/${start.month} - ${end.day}/${end.month}';
  }
}