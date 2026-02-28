import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../utils/constanst.dart';
import 'admin_service.dart';

class ReportsPage extends StatefulWidget {
  final int initialTab;
  const ReportsPage({super.key, this.initialTab = 0});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  Map<String, dynamic>? _revenueData;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _loadReportData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReportData() async {
    setState(() => _isLoading = true);
    try {
      final dashboard = await AdminService.getDashboardData();
      final revenue = await AdminService.getRevenueData();
      final tickets = await AdminService.getSupportTickets();

      if (mounted) {
        setState(() {
          _dashboardData = dashboard;
          _revenueData = revenue;
          _supportTickets = tickets;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur de chargement: $e')),
        );
      }
    }
  }

  Map<String, dynamic>? _supportTickets;

  Widget _buildSupportTickets() {
    final tickets = (_supportTickets?['tickets'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: tickets.length,
        itemBuilder: (context, index) {
          final t = tickets[index];
          final user = t['user'] ?? {};
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 8),
            child: ListTile(
              title: Text('${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catégorie: ${t['category'] ?? 'Autre'}'),
                  const SizedBox(height: 6),
                  Text(t['description'] ?? '', maxLines: 3, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text('Statut: ${t['status'] ?? 'open'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                ],
              ),
              isThreeLine: true,
              trailing: PopupMenuButton<String>(
                onSelected: (value) async {
                  final ok = await AdminService.updateSupportTicketStatus(t['_id'], value);
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Statut mis à jour')));
                    _loadReportData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de la mise à jour'), backgroundColor: Colors.red));
                  }
                },
                itemBuilder: (ctx) => [
                  const PopupMenuItem(value: 'in_progress', child: Text('En cours')),
                  const PopupMenuItem(value: 'resolved', child: Text('Résolu')),
                  const PopupMenuItem(value: 'closed', child: Text('Fermé')),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _exportPDF() async {
    final stats = _dashboardData?['statistics'] ?? {};
    final summary = _revenueData?['summary'] ?? {};
    final byParking = (_revenueData?['revenueByParking'] as List<dynamic>?) ?? [];
    final totalBookings = stats['totalBookings'] ?? 0;
    final activeBookings = stats['activeBookings'] ?? 0;
    final completedBookings = totalBookings - activeBookings;

    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Smart Parking', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
                pw.Text('Rapport - ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ),
            pw.Divider(color: PdfColors.indigo900, thickness: 2),
            pw.SizedBox(height: 10),
          ],
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          child: pw.Text('Page ${context.pageNumber}/${context.pagesCount}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey)),
        ),
        build: (context) => [
          // General Stats Section
          pw.Text('Vue d\'ensemble', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                children: [
                  _pdfCell('Indicateur', bold: true),
                  _pdfCell('Valeur', bold: true),
                ],
              ),
              pw.TableRow(children: [_pdfCell('Total utilisateurs'), _pdfCell('${stats['totalUsers'] ?? 0}')]),
              pw.TableRow(children: [_pdfCell('Total parkings'), _pdfCell('${stats['totalParkings'] ?? 0}')]),
              pw.TableRow(children: [_pdfCell('Total reservations'), _pdfCell('$totalBookings')]),
              pw.TableRow(children: [_pdfCell('Reservations actives'), _pdfCell('$activeBookings')]),
              pw.TableRow(children: [_pdfCell('Reservations terminees'), _pdfCell('$completedBookings')]),
              pw.TableRow(children: [
                _pdfCell('Taux de completion'),
                _pdfCell(totalBookings > 0 ? '${(completedBookings / totalBookings * 100).toStringAsFixed(1)}%' : '0%'),
              ]),
            ],
          ),
          pw.SizedBox(height: 24),

          // Revenue Section
          pw.Text('Analyse des revenus', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
          pw.SizedBox(height: 12),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.green50),
                children: [
                  _pdfCell('Indicateur', bold: true),
                  _pdfCell('Valeur', bold: true),
                ],
              ),
              pw.TableRow(children: [_pdfCell('Revenu total'), _pdfCell('${(summary['totalRevenue'] ?? 0.0).toStringAsFixed(2)} DT')]),
              pw.TableRow(children: [_pdfCell('Moyenne par reservation'), _pdfCell('${(summary['averageRevenue'] ?? 0.0).toStringAsFixed(2)} DT')]),
              pw.TableRow(children: [_pdfCell('Nombre de reservations'), _pdfCell('${summary['totalBookings'] ?? 0}')]),
            ],
          ),
          pw.SizedBox(height: 24),

          // Revenue by parking
          if (byParking.isNotEmpty) ...[
            pw.Text('Revenus par parking', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900)),
            pw.SizedBox(height: 12),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.orange50),
                  children: [
                    _pdfCell('#', bold: true),
                    _pdfCell('Parking', bold: true),
                    _pdfCell('Reservations', bold: true),
                    _pdfCell('Revenu (DT)', bold: true),
                  ],
                ),
                ...byParking.asMap().entries.map((entry) {
                  final i = entry.key;
                  final p = entry.value;
                  return pw.TableRow(children: [
                    _pdfCell('${i + 1}'),
                    _pdfCell(p['name'] ?? 'Inconnu'),
                    _pdfCell('${p['bookingCount'] ?? 0}'),
                    _pdfCell('${(p['totalRevenue'] ?? 0.0).toStringAsFixed(2)}'),
                  ]);
                }),
              ],
            ),
          ],
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) => pdf.save(),
      name: 'SmartParking_Rapport_${DateTime.now().day}_${DateTime.now().month}_${DateTime.now().year}',
    );
  }

  static pw.Widget _pdfCell(String text, {bool bold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(text, style: pw.TextStyle(fontSize: 11, fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        foregroundColor: Colors.white,
        title: const Text('Rapports & Analyses'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Général', icon: Icon(Icons.dashboard)),
            Tab(text: 'Revenus', icon: Icon(Icons.monetization_on)),
            Tab(text: 'Réservations', icon: Icon(Icons.book_online)),
            Tab(text: 'Signalements', icon: Icon(Icons.report_problem)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: _isLoading ? null : _exportPDF,
            tooltip: 'Exporter en PDF',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReportData,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildGeneralReport(),
                _buildRevenueReport(),
                _buildBookingsReport(),
                _buildSupportTickets(),
              ],
            ),
    );
  }

  // ─── General Report Tab ───
  Widget _buildGeneralReport() {
    final stats = _dashboardData?['statistics'] ?? {};
    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Vue d\'ensemble',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            // Stats grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _buildStatCard(
                  'Utilisateurs',
                  stats['totalUsers']?.toString() ?? '0',
                  Icons.people,
                  Colors.blue,
                ),
                _buildStatCard(
                  'Parkings',
                  stats['totalParkings']?.toString() ?? '0',
                  Icons.local_parking,
                  Colors.green,
                ),
                _buildStatCard(
                  'Réservations',
                  stats['totalBookings']?.toString() ?? '0',
                  Icons.book_online,
                  Colors.orange,
                ),
                _buildStatCard(
                  'Actives',
                  stats['activeBookings']?.toString() ?? '0',
                  Icons.access_time,
                  Colors.red,
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Occupancy rate
            _buildOccupancyCard(stats),
            const SizedBox(height: 16),
            // User growth indicator
            _buildInfoCard(
              'Croissance',
              'Total utilisateurs inscrits : ${stats['totalUsers'] ?? 0}',
              Icons.trending_up,
              Colors.teal,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOccupancyCard(Map<String, dynamic> stats) {
    final totalParkings = stats['totalParkings'] ?? 0;
    final activeBookings = stats['activeBookings'] ?? 0;
    final totalBookings = stats['totalBookings'] ?? 1;
    final occupancyRate =
        totalBookings > 0 ? (activeBookings / totalBookings * 100) : 0.0;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Taux d\'occupation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: occupancyRate / 100,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                occupancyRate > 80
                    ? Colors.red
                    : occupancyRate > 50
                        ? Colors.orange
                        : Colors.green,
              ),
              minHeight: 12,
              borderRadius: BorderRadius.circular(6),
            ),
            const SizedBox(height: 8),
            Text(
              '${occupancyRate.toStringAsFixed(1)}% - $activeBookings réservations actives sur $totalBookings totales',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              '$totalParkings parkings enregistrés',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Revenue Report Tab ───
  Widget _buildRevenueReport() {
    final summary = _revenueData?['summary'] ?? {};
    final byParking =
        (_revenueData?['revenueByParking'] as List<dynamic>?) ?? [];

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Analyse des revenus',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            // Revenue summary cards
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Revenu total',
                    '${(summary['totalRevenue'] ?? 0.0).toStringAsFixed(2)} DT',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Moy. / Réservation',
                    '${(summary['averageRevenue'] ?? 0.0).toStringAsFixed(2)} DT',
                    Icons.trending_up,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Total réservations',
                    (summary['totalBookings'] ?? 0).toString(),
                    Icons.receipt,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Période',
                    _formatPeriod(summary['period']),
                    Icons.calendar_today,
                    Colors.grey,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Revenue by parking
            const Text(
              'Revenus par parking',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 12),
            if (byParking.isEmpty)
              _buildEmptyState('Aucune donnée de revenu disponible')
            else
              ...byParking.asMap().entries.map((entry) {
                final index = entry.key;
                final parking = entry.value;
                final revenue =
                    (parking['totalRevenue'] ?? 0.0).toStringAsFixed(2);
                final bookings = parking['bookingCount'] ?? 0;
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColor.orange,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(parking['name'] ?? 'Parking inconnu'),
                    subtitle: Text('$bookings réservations'),
                    trailing: Text(
                      '$revenue DT',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  // ─── Bookings Report Tab ───
  Widget _buildBookingsReport() {
    final stats = _dashboardData?['statistics'] ?? {};
    final totalBookings = stats['totalBookings'] ?? 0;
    final activeBookings = stats['activeBookings'] ?? 0;
    final completedBookings = totalBookings - activeBookings;

    return RefreshIndicator(
      onRefresh: _loadReportData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rapport des réservations',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
            const SizedBox(height: 16),
            // Booking stats
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Totales',
                    totalBookings.toString(),
                    Icons.book_online,
                    Colors.blue,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Actives',
                    activeBookings.toString(),
                    Icons.access_time,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildRevenueCard(
                    'Terminées',
                    completedBookings.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRevenueCard(
                    'Taux complétion',
                    totalBookings > 0
                        ? '${(completedBookings / totalBookings * 100).toStringAsFixed(1)}%'
                        : '0%',
                    Icons.pie_chart,
                    Colors.purple,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Booking status distribution
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Distribution des statuts',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColor.navy,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildStatusBar(
                        'Actives', activeBookings, totalBookings, Colors.orange),
                    const SizedBox(height: 8),
                    _buildStatusBar('Terminées', completedBookings,
                        totalBookings, Colors.green),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Helper Widgets ───
  Widget _buildStatCard(
      String title, String value, IconData icon, Color color) {
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

  Widget _buildRevenueCard(
      String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
      String title, String subtitle, IconData icon, Color color) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withOpacity(0.2),
          child: Icon(icon, color: color),
        ),
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
      ),
    );
  }

  Widget _buildStatusBar(
      String label, int count, int total, Color color) {
    final percentage = total > 0 ? count / total : 0.0;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[700])),
            Text('$count (${(percentage * 100).toStringAsFixed(1)}%)',
                style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(color),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
      ],
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(Icons.inbox, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              message,
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _formatPeriod(Map<String, dynamic>? period) {
    if (period == null) return 'N/A';
    try {
      final start = DateTime.parse(period['start']);
      final end = DateTime.parse(period['end']);
      return '${start.day}/${start.month} - ${end.day}/${end.month}';
    } catch (_) {
      return 'N/A';
    }
  }
}
