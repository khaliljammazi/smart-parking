import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import 'vehicle_service.dart';

class VehicleHistoryPage extends StatefulWidget {
  final Map<String, dynamic> vehicle;

  const VehicleHistoryPage({super.key, required this.vehicle});

  @override
  State<VehicleHistoryPage> createState() => _VehicleHistoryPageState();
}

class _VehicleHistoryPageState extends State<VehicleHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  Map<String, dynamic>? _stats;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() => _isLoading = true);
    try {
      final data = await VehicleService.getVehicleHistory(widget.vehicle['_id']);
      if (data != null && mounted) {
        setState(() {
          _bookings = data['bookings'] ?? [];
          _stats = data['stats'];
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
      }
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed': return Colors.green;
      case 'active': return Colors.blue;
      case 'confirmed': return Colors.teal;
      case 'cancelled': return Colors.red;
      case 'no_show': return Colors.orange;
      default: return Colors.grey;
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'completed': return 'Terminée';
      case 'active': return 'Active';
      case 'confirmed': return 'Confirmée';
      case 'cancelled': return 'Annulée';
      case 'pending': return 'En attente';
      case 'no_show': return 'Absent';
      default: return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final plate = widget.vehicle['licensePlate'] ?? '';
    final make = widget.vehicle['make'] ?? '';
    final model = widget.vehicle['model'] ?? '';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        foregroundColor: Colors.white,
        title: Text('Historique – $plate'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadHistory,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Vehicle header
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColor.navy.withOpacity(0.1),
                              radius: 28,
                              child: const Icon(Icons.directions_car, color: AppColor.navy, size: 28),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('$make $model', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColor.navy)),
                                  const SizedBox(height: 4),
                                  Text(plate, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Stats summary
                    if (_stats != null) ...[
                      Row(
                        children: [
                          _buildStatChip('Réservations', '${_stats!['totalBookings'] ?? 0}', Icons.book_online, Colors.blue),
                          const SizedBox(width: 12),
                          _buildStatChip('Terminées', '${_stats!['completedBookings'] ?? 0}', Icons.check_circle, Colors.green),
                          const SizedBox(width: 12),
                          _buildStatChip('Total dépensé', '${(_stats!['totalSpent'] ?? 0).toStringAsFixed(2)} DT', Icons.attach_money, AppColor.orange),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Bookings list
                    Text('Réservations (${_bookings.length})',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColor.navy)),
                    const SizedBox(height: 12),

                    if (_bookings.isEmpty)
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            children: [
                              Icon(Icons.history, size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 12),
                              Text('Aucune réservation pour ce véhicule', style: TextStyle(fontSize: 16, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                      )
                    else
                      ..._bookings.map((b) => _buildBookingCard(b)),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatChip(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 10, color: color.withOpacity(0.8)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final parking = booking['parking'];
    final parkingName = parking?['name'] ?? 'Parking inconnu';
    final status = booking['status'] ?? 'pending';
    final total = booking['pricing']?['total'] ?? 0;
    final createdAt = DateTime.tryParse(booking['createdAt']?.toString() ?? '');
    final dateStr = createdAt != null ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : '';
    final hours = booking['duration']?['hours'] ?? 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(parkingName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusColor(status).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(_statusLabel(status), style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _statusColor(status))),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(dateStr, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text('${hours}h', style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                const Spacer(),
                Text('${total.toStringAsFixed(2)} DT',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.green)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
