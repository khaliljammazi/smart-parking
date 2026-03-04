import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'admin_service.dart';
import '../utils/constanst.dart';

class ManageBookingsPage extends StatefulWidget {
  const ManageBookingsPage({super.key});

  @override
  State<ManageBookingsPage> createState() => _ManageBookingsPageState();
}

class _ManageBookingsPageState extends State<ManageBookingsPage> {
  List<dynamic> _bookings = [];
  Map<String, int> _summary = {};
  bool _isLoading = true;
  String _filterStatus = 'all';
  int _page = 1;
  int _total = 0;
  final int _limit = 20;

  final List<Map<String, String>> _statusFilters = [
    {'value': 'all', 'label': 'Toutes'},
    {'value': 'pending', 'label': 'En attente'},
    {'value': 'confirmed', 'label': 'Confirmées'},
    {'value': 'active', 'label': 'Actives'},
    {'value': 'completed', 'label': 'Terminées'},
    {'value': 'cancelled', 'label': 'Annulées'},
  ];

  @override
  void initState() {
    super.initState();
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    try {
      final data = await AdminService.getAllBookings(
        page: _page,
        limit: _limit,
        status: _filterStatus == 'all' ? null : _filterStatus,
      );
      if (data != null && mounted) {
        setState(() {
          _bookings = data['bookings'] ?? [];
          _total = data['total'] ?? 0;
          _summary = Map<String, int>.from(
            (data['summary'] as Map? ?? {}).map((k, v) => MapEntry(k.toString(), (v as num).toInt())),
          );
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer la réservation'),
        content: const Text('Êtes-vous sûr de vouloir supprimer cette réservation ? Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await AdminService.deleteBooking(bookingId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Réservation supprimée' : 'Échec de la suppression'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
        if (success) _loadBookings();
      }
    }
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'active':
        return Colors.green;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _statusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmée';
      case 'active':
        return 'Active';
      case 'completed':
        return 'Terminée';
      case 'cancelled':
        return 'Annulée';
      default:
        return status ?? 'Inconnu';
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '—';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('dd/MM/yyyy HH:mm').format(date);
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalPages = (_total / _limit).ceil();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gérer les réservations'),
        backgroundColor: isDark ? const Color(0xFF1A1F3A) : AppColor.navy,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Summary cards
          if (_summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _summaryCard('En attente', _summary['pending'] ?? 0, Colors.orange, isDark),
                    _summaryCard('Confirmées', _summary['confirmed'] ?? 0, Colors.blue, isDark),
                    _summaryCard('Actives', _summary['active'] ?? 0, Colors.green, isDark),
                    _summaryCard('Terminées', _summary['completed'] ?? 0, Colors.grey, isDark),
                    _summaryCard('Annulées', _summary['cancelled'] ?? 0, Colors.red, isDark),
                  ],
                ),
              ),
            ),

          // Status filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _statusFilters.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final f = _statusFilters[i];
                final isActive = _filterStatus == f['value'];
                return ChoiceChip(
                  label: Text(f['label']!),
                  selected: isActive,
                  selectedColor: AppColor.navy,
                  labelStyle: TextStyle(color: isActive ? Colors.white : null, fontSize: 12),
                  onSelected: (_) {
                    setState(() {
                      _filterStatus = f['value']!;
                      _page = 1;
                    });
                    _loadBookings();
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? const Center(child: Text('Aucune réservation trouvée'))
                    : RefreshIndicator(
                        onRefresh: _loadBookings,
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          itemCount: _bookings.length,
                          itemBuilder: (_, i) => _bookingCard(_bookings[i], isDark),
                        ),
                      ),
          ),

          // Pagination
          if (totalPages > 1)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: _page > 1
                        ? () {
                            setState(() => _page--);
                            _loadBookings();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Text('$_page / $totalPages', style: const TextStyle(fontWeight: FontWeight.w600)),
                  IconButton(
                    onPressed: _page < totalPages
                        ? () {
                            setState(() => _page++);
                            _loadBookings();
                          }
                        : null,
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryCard(String label, int count, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text('$count', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: color)),
        ],
      ),
    );
  }

  Widget _bookingCard(Map<String, dynamic> booking, bool isDark) {
    final user = booking['user'] as Map<String, dynamic>?;
    final parking = booking['parking'] as Map<String, dynamic>?;
    final vehicle = booking['vehicle'] as Map<String, dynamic>?;
    final status = booking['status'] as String?;
    final id = booking['_id'] as String? ?? '';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? const Color(0xFF1E2746) : null,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: status + delete
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusLabel(status),
                    style: TextStyle(color: _statusColor(status), fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  onPressed: () => _deleteBooking(id),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
            const SizedBox(height: 8),

            // User
            if (user != null)
              Row(
                children: [
                  Icon(Icons.person_outline, size: 16, color: isDark ? Colors.white70 : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim(),
                      style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black87),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),

            // Parking
            if (parking != null)
              Row(
                children: [
                  Icon(Icons.local_parking, size: 16, color: isDark ? Colors.white70 : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      parking['name'] ?? '',
                      style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700], fontSize: 13),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 4),

            // Vehicle
            if (vehicle != null)
              Row(
                children: [
                  Icon(Icons.directions_car_outlined, size: 16, color: isDark ? Colors.white70 : Colors.grey[600]),
                  const SizedBox(width: 6),
                  Text(
                    '${vehicle['make'] ?? ''} ${vehicle['model'] ?? ''} — ${vehicle['licensePlate'] ?? ''}',
                    style: TextStyle(color: isDark ? Colors.white60 : Colors.grey[700], fontSize: 13),
                  ),
                ],
              ),
            const SizedBox(height: 6),

            // Times
            Row(
              children: [
                Icon(Icons.access_time, size: 14, color: isDark ? Colors.white54 : Colors.grey),
                const SizedBox(width: 4),
                Text(
                  '${_formatDate(booking['startTime'])} → ${_formatDate(booking['endTime'])}',
                  style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.grey),
                ),
              ],
            ),

            // Pricing (for completed bookings)
            if (booking['pricing'] != null) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(isDark ? 0.15 : 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.amber.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.receipt_long, size: 16, color: Colors.amber[700]),
                        const SizedBox(width: 6),
                        Text('Montant total',
                            style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.grey[700])),
                      ],
                    ),
                    Text(
                      '${((booking['pricing']?['total'] ?? 0) is num ? (booking['pricing']['total'] as num).toStringAsFixed(2) : '0.00')} DT',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
