import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constanst.dart';
import 'booking_service.dart';

class ParkingStatsPage extends StatefulWidget {
  const ParkingStatsPage({super.key});

  @override
  State<ParkingStatsPage> createState() => _ParkingStatsPageState();
}

class _ParkingStatsPageState extends State<ParkingStatsPage> {
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
      final stats = await BookingService.getMyStats();
      if (mounted) {
        setState(() {
          _stats = stats;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: const Text(
          'Mes Statistiques',
          style: TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _stats == null
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOverviewCards(),
                    const SizedBox(height: 20),
                    _buildMonthlySpendingChart(),
                    const SizedBox(height: 20),
                    _buildWeekdayChart(),
                    const SizedBox(height: 20),
                    _buildTopParkings(),
                    const SizedBox(height: 20),
                    _buildBookingBreakdown(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 80, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Aucune donnée disponible',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Vos statistiques apparaîtront après\nvotre première réservation',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  // ─── Overview Cards ──────────────────────────────────
  Widget _buildOverviewCards() {
    final overview = _stats!['overview'] ?? {};
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Vue d\'ensemble',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColor.navy,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.attach_money,
                label: 'Total dépensé',
                value: '${(overview['totalSpent'] ?? 0).toStringAsFixed(1)} DT',
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.access_time,
                label: 'Heures garées',
                value: '${overview['totalHours'] ?? 0}h',
                color: Colors.blue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.event,
                label: 'Réservations',
                value: '${overview['totalBookings'] ?? 0}',
                color: AppColor.orange,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.timer,
                label: 'Durée moyenne',
                value: '${overview['avgDuration'] ?? 0}h',
                color: Colors.purple,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        ],
      ),
    );
  }

  // ─── Monthly Spending Bar Chart ──────────────────────
  Widget _buildMonthlySpendingChart() {
    final monthly =
        (_stats!['monthly'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (monthly.isEmpty) return const SizedBox.shrink();

    final maxSpent = monthly.fold<double>(
      0,
      (m, e) => (e['spent'] as num).toDouble() > m
          ? (e['spent'] as num).toDouble()
          : m,
    );

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.trending_up, color: AppColor.navy, size: 20),
              SizedBox(width: 8),
              Text(
                'Dépenses mensuelles',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: maxSpent > 0 ? maxSpent * 1.2 : 10,
                barTouchData: BarTouchData(
                  touchTooltipData: BarTouchTooltipData(
                    getTooltipItem: (group, groupIndex, rod, rodIndex) {
                      final m = monthly[group.x.toInt()];
                      return BarTooltipItem(
                        '${m['label']}\n${m['spent']} DT',
                        const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
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
                        final idx = value.toInt();
                        if (idx < 0 || idx >= monthly.length)
                          return const SizedBox.shrink();
                        // Show every 2nd label to avoid crowding
                        if (idx % 2 != 0 && monthly.length > 6)
                          return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            monthly[idx]['label'] ?? '',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 10,
                            ),
                          ),
                        );
                      },
                      reservedSize: 30,
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          '${value.toInt()}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 10,
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: maxSpent > 0 ? maxSpent / 4 : 2,
                  getDrawingHorizontalLine: (value) =>
                      FlLine(color: Colors.grey[200]!, strokeWidth: 1),
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(monthly.length, (i) {
                  final spent = (monthly[i]['spent'] as num).toDouble();
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: spent,
                        color: spent > 0 ? AppColor.navy : Colors.grey[300]!,
                        width: monthly.length > 8 ? 12 : 18,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(6),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Weekday Distribution ────────────────────────────
  Widget _buildWeekdayChart() {
    final weekdays =
        (_stats!['weekdayDistribution'] as List?)?.cast<int>() ??
        [0, 0, 0, 0, 0, 0, 0];
    final labels = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    final maxVal = weekdays.fold<int>(0, (m, v) => v > m ? v : m);

    if (maxVal == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_today, color: AppColor.navy, size: 20),
              SizedBox(width: 8),
              Text(
                'Jours les plus fréquents',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(7, (i) {
            final pct = maxVal > 0 ? weekdays[i] / maxVal : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 36,
                    child: Text(
                      labels[i],
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Stack(
                      children: [
                        Container(
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: pct,
                          child: Container(
                            height: 24,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColor.navy,
                                  AppColor.navy.withOpacity(0.7),
                                ],
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 24,
                    child: Text(
                      '${weekdays[i]}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Top Visited Parkings ────────────────────────────
  Widget _buildTopParkings() {
    final topParkings =
        (_stats!['topParkings'] as List?)?.cast<Map<String, dynamic>>() ?? [];
    if (topParkings.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Parkings les plus visités',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...List.generate(topParkings.length, (i) {
            final item = topParkings[i];
            final parking = item['parking'] ?? {};
            final visits = item['visits'] ?? 0;
            final spent = (item['totalSpent'] ?? 0).toDouble();
            final address = parking['address'];
            String addressStr = '';
            if (address is Map) {
              addressStr =
                  '${address['street'] ?? ''}, ${address['city'] ?? ''}'.trim();
              if (addressStr.startsWith(','))
                addressStr = addressStr.substring(2);
            }

            final medals = ['🥇', '🥈', '🥉'];

            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: i == 0
                    ? Colors.amber.withOpacity(0.06)
                    : Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: i == 0
                    ? Border.all(color: Colors.amber.withOpacity(0.3))
                    : null,
              ),
              child: Row(
                children: [
                  Text(
                    i < 3 ? medals[i] : '${i + 1}.',
                    style: const TextStyle(fontSize: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          parking['name'] ?? 'Parking',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (addressStr.isNotEmpty)
                          Text(
                            addressStr,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '$visits visite${visits > 1 ? 's' : ''}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColor.navy,
                        ),
                      ),
                      Text(
                        '${spent.toStringAsFixed(1)} DT',
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ─── Booking Status Breakdown (Pie Chart) ────────────
  Widget _buildBookingBreakdown() {
    final overview = _stats!['overview'] ?? {};
    final completed = (overview['completedBookings'] ?? 0) as int;
    final active = (overview['activeBookings'] ?? 0) as int;
    final cancelled = (overview['cancelledBookings'] ?? 0) as int;
    final total = completed + active + cancelled;

    if (total == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart, color: AppColor.navy, size: 20),
              SizedBox(width: 8),
              Text(
                'Répartition des réservations',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColor.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 180,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 3,
                      centerSpaceRadius: 35,
                      sections: [
                        if (completed > 0)
                          PieChartSectionData(
                            value: completed.toDouble(),
                            color: Colors.green,
                            title: '$completed',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 50,
                          ),
                        if (active > 0)
                          PieChartSectionData(
                            value: active.toDouble(),
                            color: Colors.blue,
                            title: '$active',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 50,
                          ),
                        if (cancelled > 0)
                          PieChartSectionData(
                            value: cancelled.toDouble(),
                            color: Colors.red,
                            title: '$cancelled',
                            titleStyle: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            radius: 50,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLegendItem('Terminées', Colors.green, completed),
                    const SizedBox(height: 10),
                    _buildLegendItem('Actives', Colors.blue, active),
                    const SizedBox(height: 10),
                    _buildLegendItem('Annulées', Colors.red, cancelled),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, int count) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label ($count)',
          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
        ),
      ],
    );
  }
}
