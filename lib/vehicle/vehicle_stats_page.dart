import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constanst.dart';
import 'vehicle_service.dart';

class VehicleStatsPage extends StatefulWidget {
  const VehicleStatsPage({super.key});

  @override
  State<VehicleStatsPage> createState() => _VehicleStatsPageState();
}

class _VehicleStatsPageState extends State<VehicleStatsPage> {
  bool _isLoading = true;
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoading = true);
    try {
      final data = await VehicleService.getVehicleStats();
      if (mounted) {
        setState(() { _stats = data; _isLoading = false; });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        foregroundColor: Colors.white,
        title: const Text('Statistiques véhicules'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
              ? const Center(child: Text('Aucune donnée disponible'))
              : RefreshIndicator(
                  onRefresh: _loadStats,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Summary cards
                        _buildSummaryCards(),
                        const SizedBox(height: 24),

                        // Most used vehicle
                        if (_stats!['mostUsed'] != null) ...[
                          _buildMostUsedCard(),
                          const SizedBox(height: 24),
                        ],

                        // Bookings per vehicle bar chart
                        if ((_stats!['bookingsPerVehicle'] as List?)?.isNotEmpty == true) ...[
                          _buildBookingsPerVehicleChart(),
                          const SizedBox(height: 24),
                        ],

                        // Monthly usage line chart
                        if ((_stats!['monthlyUsage'] as List?)?.isNotEmpty == true) ...[
                          _buildMonthlyUsageChart(),
                          const SizedBox(height: 24),
                        ],
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildSummaryCards() {
    return Row(
      children: [
        _buildSummaryCard('Véhicules', '${_stats!['totalVehicles'] ?? 0}', Icons.directions_car, Colors.blue),
        const SizedBox(width: 12),
        _buildSummaryCard('Réservations', '${_stats!['totalBookings'] ?? 0}', Icons.book_online, Colors.green),
        const SizedBox(width: 12),
        _buildSummaryCard('Total', '${(_stats!['totalSpent'] ?? 0).toStringAsFixed(1)} DT', Icons.attach_money, AppColor.orange),
      ],
    );
  }

  Widget _buildSummaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Card(
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600]), textAlign: TextAlign.center),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMostUsedCard() {
    final most = _stats!['mostUsed'];
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: AppColor.orange.withOpacity(0.2),
              radius: 28,
              child: const Icon(Icons.emoji_events, color: AppColor.orange, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Véhicule le plus utilisé', style: TextStyle(fontSize: 13, color: Colors.grey)),
                  const SizedBox(height: 4),
                  Text('${most['make'] ?? ''} ${most['model'] ?? ''}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColor.navy)),
                  Text('${most['licensePlate'] ?? ''}', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('${most['totalBookings'] ?? 0}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.green)),
                const Text('réservations', style: TextStyle(fontSize: 11, color: Colors.grey)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingsPerVehicleChart() {
    final perVehicle = (_stats!['bookingsPerVehicle'] as List<dynamic>?) ?? [];
    if (perVehicle.isEmpty) return const SizedBox.shrink();

    final maxBookings = perVehicle.map<double>((v) => (v['totalBookings'] ?? 0).toDouble()).reduce((a, b) => a > b ? a : b);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Réservations par véhicule', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.navy)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxBookings + 2,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIdx, rod, rodIdx) {
                        final v = perVehicle[group.x.toInt()];
                        return BarTooltipItem(
                          '${v['make']} ${v['model']}\n${rod.toY.toInt()} réservations',
                          const TextStyle(color: Colors.white, fontSize: 12),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= perVehicle.length) return const SizedBox.shrink();
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(
                              perVehicle[i]['licensePlate']?.toString().split(' ').first ?? '',
                              style: const TextStyle(fontSize: 10),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barGroups: perVehicle.asMap().entries.map((e) {
                    return BarChartGroupData(
                      x: e.key,
                      barRods: [
                        BarChartRodData(
                          toY: (e.value['totalBookings'] ?? 0).toDouble(),
                          color: AppColor.navy,
                          width: 20,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthlyUsageChart() {
    final monthly = (_stats!['monthlyUsage'] as List<dynamic>?) ?? [];
    if (monthly.isEmpty) return const SizedBox.shrink();

    final months = ['', 'Jan', 'Fév', 'Mar', 'Avr', 'Mai', 'Jun', 'Jul', 'Aoû', 'Sep', 'Oct', 'Nov', 'Déc'];

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Utilisation mensuelle', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.navy)),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= monthly.length) return const SizedBox.shrink();
                          final m = monthly[i]['_id']?['month'] ?? 0;
                          return SideTitleWidget(
                            meta: meta,
                            child: Text(m > 0 && m <= 12 ? months[m] : '', style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 30)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: monthly.asMap().entries.map((e) {
                        return FlSpot(e.key.toDouble(), (e.value['count'] ?? 0).toDouble());
                      }).toList(),
                      isCurved: true,
                      color: AppColor.orange,
                      barWidth: 3,
                      isStrokeCapRound: true,
                      belowBarData: BarAreaData(show: true, color: AppColor.orange.withOpacity(0.15)),
                      dotData: FlDotData(show: true),
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
