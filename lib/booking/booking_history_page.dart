import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../booking/booking_service.dart';
import '../utils/constanst.dart';
import 'qr_code_dialog.dart';
import 'rating_dialog.dart';
import 'booking_actions_dialog.dart';
import 'package:intl/intl.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    // Refresh countdown every second
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() => _isLoading = true);
    
    try {
      final bookings = await BookingService.getUserBookings();
      if (bookings != null && mounted) {
        setState(() {
          _bookings = bookings;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading bookings: $e')),
        );
      }
    }
  }

  String _getStatusText(String status) {
    switch (status) {
      case 'pending':
        return 'En attente';
      case 'confirmed':
        return 'Confirmé';
      case 'active':
        return 'Actif';
      case 'completed':
        return 'Terminé';
      case 'cancelled':
        return 'Annulé';
      default:
        return status;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'confirmed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      case 'completed':
        return Colors.grey;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  void _showQRCode(Map<String, dynamic> booking) {
    showDialog(
      context: context,
      builder: (context) => QRCodeDialog(booking: booking),
    );
  }

  Future<void> _checkIn(String bookingId) async {
    try {
      final result = await BookingService.checkIn(bookingId);
      if (result != null && mounted) {
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked in successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking in: $e')),
        );
      }
    }
  }

  Future<void> _checkOut(String bookingId) async {
    try {
      final result = await BookingService.checkOut(bookingId);
      if (result != null && mounted) {
        _loadBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Checked out successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking out: $e')),
        );
      }
    }
  }

  void _showRatingDialog(Map<String, dynamic> booking) {
    final parking = booking['parking'] ?? {};
    final parkingId = parking['_id']?.toString() ?? parking['id']?.toString() ?? '';
    final parkingName = parking['name']?.toString() ?? 'Parking';

    showDialog(
      context: context,
      builder: (context) => RatingDialog(
        parkingId: parkingId,
        parkingName: parkingName,
      ),
    ).then((rated) {
      if (rated == true) {
        _loadBookings();
      }
    });
  }

  void _shareBooking(Map<String, dynamic> booking) {
    final parking = booking['parking'] ?? {};
    final parkingName = parking['name']?.toString() ?? 'Parking';
    final status = _getStatusText(booking['status'] ?? 'pending');
    final startTime = booking['startTime'] != null
        ? DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(booking['startTime']))
        : '';

    final address = parking['address'];
    String addressStr = '';
    if (address is Map) {
      addressStr = '${address['street'] ?? ''}, ${address['city'] ?? ''}'.trim();
    } else if (address is String) {
      addressStr = address;
    }

    final bookingRef = booking['_id']?.toString().substring(0, 8) ?? '';

    final text = '\u{1f697} R\u00e9servation Smart Parking\n'
        '\u{1f3e2} Parking: $parkingName\n'
        '${addressStr.isNotEmpty ? '\u{1f4cd} Adresse: $addressStr\n' : ''}'
        '${startTime.isNotEmpty ? '\u{1f552} Date: $startTime\n' : ''}'
        '\u{1f4cb} Statut: $status\n'
        '\u{1f4c4} R\u00e9f: #$bookingRef';

    Share.share(text, subject: 'Ma r\u00e9servation - $parkingName');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: AppColor.navy,
        elevation: 0,
        title: const Text('Mes Réservations', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text(
                        'Aucune réservation',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _bookings.length,
                    itemBuilder: (context, index) {
                      final booking = _bookings[index];
                      return _buildBookingCard(booking);
                    },
                  ),
                ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final parking = booking['parking'] ?? {};
    final status = booking['status'] ?? 'pending';
    final startTime = booking['startTime'] != null
        ? DateTime.parse(booking['startTime'])
        : null;
    final endTime = booking['endTime'] != null
        ? DateTime.parse(booking['endTime'])
        : null;
    final qrCode = booking['qrCode'];
    final adminValidated = booking['adminValidated'] ?? false;
    final isRecurring = booking['recurring']?['enabled'] == true;
    final cancellationReason = booking['cancellationReason'];

    // Construct address string from address object
    final address = parking['address'];
    final addressString = address != null && address is Map<String, dynamic>
        ? '${address['street'] ?? ''}, ${address['city'] ?? ''}, ${address['country'] ?? ''}'.trim()
        : 'Address not available';

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with status + recurring badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          parking['name'] ?? 'Parking',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColor.navy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isRecurring) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.repeat, size: 12, color: Colors.deepPurple),
                              SizedBox(width: 2),
                              Text('Récurrent', style: TextStyle(fontSize: 10, color: Colors.deepPurple, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _getStatusText(status),
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),

            // Expired badge
            if (status == 'cancelled' && cancellationReason == 'expired')
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.timer_off, size: 14, color: Colors.red),
                      SizedBox(width: 4),
                      Text('Expiré — non présenté',
                          style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              ),

            const SizedBox(height: 12),

            // Address
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    addressString,
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Date and time
            if (startTime != null)
              Row(
                children: [
                  const Icon(Icons.access_time, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(
                    DateFormat('dd/MM/yyyy HH:mm').format(startTime),
                    style: const TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                ],
              ),

            // ── Countdown timer ──
            if ((status == 'confirmed' || status == 'active') && startTime != null && endTime != null)
              _buildCountdownWidget(status, startTime, endTime),

            // ── Smart pricing details ──
            if (booking['pricingDetails'] != null &&
                booking['pricingDetails']['discountType'] != null &&
                booking['pricingDetails']['discountType'] != 'none')
              _buildPricingBadge(booking['pricingDetails']),

            const SizedBox(height: 16),

            // Actions
            if (status == 'confirmed' || status == 'active')
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Validation status
                  if (status == 'confirmed')
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: adminValidated ? Colors.green.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: adminValidated ? Colors.green : Colors.orange,
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            adminValidated ? Icons.check_circle : Icons.access_time,
                            size: 16,
                            color: adminValidated ? Colors.green : Colors.orange,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            adminValidated ? 'Validated by Admin' : 'Waiting for Admin Validation',
                            style: TextStyle(
                              fontSize: 12,
                              color: adminValidated ? Colors.green : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Action buttons row
                  Row(
                    children: [
                      if (qrCode != null && status == 'confirmed')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _showQRCode(booking),
                            icon: const Icon(Icons.qr_code),
                            label: const Text('Show QR Code'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColor.orange,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (status == 'confirmed')
                        const SizedBox(width: 8),
                      if (status == 'confirmed')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: adminValidated ? () => _checkIn(booking['_id']) : null,
                            icon: const Icon(Icons.login),
                            label: Text(adminValidated ? 'Check In' : 'Waiting for Validation'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: adminValidated ? Colors.green : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      if (status == 'active')
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _checkOut(booking['_id']),
                            icon: const Icon(Icons.logout),
                            label: const Text('Check Out'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Extend + Actions row for active bookings
                  if (status == 'active')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => BookingActionsDialog(
                                bookingId: booking['_id'],
                                status: status,
                                onUpdate: _loadBookings,
                              ),
                            );
                          },
                          icon: const Icon(Icons.more_horiz),
                          label: const Text('Prolonger / Annuler'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColor.navy,
                            side: const BorderSide(color: AppColor.navy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),

            // Rate button for completed bookings
            if (status == 'completed')
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showRatingDialog(booking),
                    icon: const Icon(Icons.star, color: Colors.white),
                    label: Text(
                      booking['rating'] != null ? 'Modifier votre avis' : 'Évaluer ce parking',
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber[700],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),

            // Share button
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _shareBooking(booking),
                  icon: const Icon(Icons.share, size: 18),
                  label: const Text('Partager'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.navy,
                    side: const BorderSide(color: AppColor.navy),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Countdown widget for confirmed (time until check-in deadline) and active (time remaining)
  Widget _buildCountdownWidget(String status, DateTime startTime, DateTime endTime) {
    final now = DateTime.now();

    if (status == 'confirmed') {
      // Countdown to check-in deadline (startTime + 30 min)
      final deadline = startTime.add(const Duration(minutes: 30));
      final remaining = deadline.difference(now);

      if (remaining.isNegative) {
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning, size: 16, color: Colors.red),
                SizedBox(width: 4),
                Text('Délai de check-in dépassé !',
                    style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        );
      }

      if (now.isBefore(startTime)) {
        // Before start — count down to start
        final toStart = startTime.difference(now);
        return _buildTimerWidget(
          icon: Icons.hourglass_top,
          label: 'Commence dans',
          duration: toStart,
          color: Colors.blue,
        );
      }

      // Between start and deadline — urgent check-in countdown
      return _buildTimerWidget(
        icon: Icons.running_with_errors,
        label: 'Check-in avant',
        duration: remaining,
        color: remaining.inMinutes < 10 ? Colors.red : Colors.orange,
      );
    }

    // Active — time remaining
    final remaining = endTime.difference(now);
    if (remaining.isNegative) {
      return _buildTimerWidget(
        icon: Icons.timer_off,
        label: 'Dépassé de',
        duration: remaining.abs(),
        color: Colors.red,
      );
    }
    return _buildTimerWidget(
      icon: Icons.timer,
      label: 'Temps restant',
      duration: remaining,
      color: remaining.inMinutes < 30 ? Colors.orange : Colors.green,
    );
  }

  Widget _buildTimerWidget({
    required IconData icon,
    required String label,
    required Duration duration,
    required Color color,
  }) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);
    final timeStr = hours > 0
        ? '${hours}h ${minutes.toString().padLeft(2, '0')}m ${seconds.toString().padLeft(2, '0')}s'
        : '${minutes}m ${seconds.toString().padLeft(2, '0')}s';

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text('$label: ', style: TextStyle(fontSize: 12, color: color)),
            Text(timeStr,
                style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.bold, fontFamily: 'monospace')),
          ],
        ),
      ),
    );
  }

  Widget _buildPricingBadge(Map<String, dynamic> details) {
    final discountType = details['discountType'] ?? 'none';
    final discount = (details['discount'] ?? 0).toDouble();
    final isPeak = details['isPeak'] == true;

    String label;
    IconData icon;
    Color color;

    if (isPeak) {
      label = 'Tarif heures de pointe (x${details['peakMultiplier']})';
      icon = Icons.trending_up;
      color = Colors.red;
    } else if (discountType == 'off_peak') {
      label = 'Réduction hors pointe -${discount.toStringAsFixed(0)}%';
      icon = Icons.trending_down;
      color = Colors.green;
    } else if (discountType == 'long_stay') {
      label = 'Réduction longue durée -${discount.toStringAsFixed(0)}%';
      icon = Icons.access_time_filled;
      color = Colors.teal;
    } else {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(label, style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
