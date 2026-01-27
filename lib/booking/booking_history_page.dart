import 'package:flutter/material.dart';
import '../booking/booking_service.dart';
import '../utils/constanst.dart';
import 'qr_code_dialog.dart';
import 'package:intl/intl.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  bool _isLoading = true;
  List<dynamic> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadBookings();
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
    final qrCode = booking['qrCode'];
    final adminValidated = booking['adminValidated'] ?? false;

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
            // Header with status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    parking['name'] ?? 'Parking',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColor.navy,
                    ),
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
                  // Action buttons
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
                ],
              ),
          ],
        ),
      ),
    );
  }
}
