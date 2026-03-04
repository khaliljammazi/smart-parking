import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
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
        // Show pricing dialog
        final booking = result['data']?['booking'];
        final pricing = booking?['pricing'];
        if (pricing != null && mounted) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 28),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('Check-out effectué !', style: TextStyle(fontSize: 18))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      children: [
                        const Text('💰 Montant à payer', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        const SizedBox(height: 12),
                        _buildReceiptRow('Tarif/h', '${(pricing['rate'] ?? 0).toStringAsFixed(2)} DT'),
                        _buildReceiptRow('Sous-total', '${(pricing['subtotal'] ?? 0).toStringAsFixed(2)} DT'),
                        _buildReceiptRow('TVA (19%)', '${(pricing['tax'] ?? 0).toStringAsFixed(2)} DT'),
                        const Divider(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('${(pricing['total'] ?? 0).toStringAsFixed(2)} DT',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: Colors.green)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Veuillez payer ce montant au parking.', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColor.navy, foregroundColor: Colors.white),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Check-out effectué !'), backgroundColor: Colors.green),
          );
        }
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
  Future<void> _cancelBooking(Map<String, dynamic> booking) async {
    final bookingId = booking['_id']?.toString() ?? '';
    if (bookingId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: const Text(
          'Êtes-vous sûr de vouloir annuler cette réservation ?\n\n'
          'Note : L\'annulation est possible uniquement 2h avant l\'heure de début.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await BookingService.cancelBooking(bookingId, reason: 'user_cancelled');
    if (result != null && mounted) {
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('✅ Réservation annulée avec succès'), backgroundColor: Colors.green),
        );
        _loadBookings();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ ${result['message'] ?? 'Échec de l\'annulation'}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('❌ Erreur de connexion'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _exportBookingsPDF() async {
    if (_bookings.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Aucune réservation à exporter')),
      );
      return;
    }

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: Card(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [CircularProgressIndicator(), SizedBox(height: 16), Text('Génération du PDF...')],
            ),
          ),
        ),
      ),
    );

    try {
      final pdf = pw.Document();
      final now = DateTime.now();
      final dateStr = DateFormat('dd/MM/yyyy').format(now);

      // Styles
      final headerStyle = pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo900);
      final sectionStyle = pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.indigo800);
      final cellStyle = const pw.TextStyle(fontSize: 10);
      final cellBoldStyle = pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold);

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
                  pw.Text('Smart Parking', style: headerStyle),
                  pw.Text('Historique - $dateStr', style: pw.TextStyle(fontSize: 12, color: PdfColors.grey600)),
                ],
              ),
              pw.Divider(color: PdfColors.indigo900, thickness: 2),
              pw.SizedBox(height: 8),
            ],
          ),
          build: (context) {
            final rows = <pw.TableRow>[
              // Table header
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.indigo50),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Parking', style: cellBoldStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: cellBoldStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Durée', style: cellBoldStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Statut', style: cellBoldStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Prix (DT)', style: cellBoldStyle)),
                ],
              ),
            ];

            double totalSpent = 0;

            for (final b in _bookings) {
              final p = b['parking'] ?? {};
              final st = b['startTime'] != null ? DateTime.parse(b['startTime']) : null;
              final et = b['endTime'] != null ? DateTime.parse(b['endTime']) : null;
              final checkIn = b['checkInTime'] != null ? DateTime.parse(b['checkInTime']) : null;
              final checkOut = b['checkOutTime'] != null ? DateTime.parse(b['checkOutTime']) : null;
              final status = b['status'] ?? 'pending';
              final pricing = b['pricing'];
              final total = (pricing?['total'] ?? 0).toDouble();
              if (status == 'completed') totalSpent += total;

              // Use actual check-in/check-out times for completed bookings
              String durStr = '-';
              if (status == 'completed' && checkIn != null && checkOut != null) {
                final dur = checkOut.difference(checkIn);
                durStr = dur.inHours > 0 ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min' : '${dur.inMinutes}min';
              } else if (st != null && et != null) {
                final dur = et.difference(st);
                durStr = dur.inHours > 0 ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min' : '${dur.inMinutes}min';
              }

              final dateDisplay = st != null ? DateFormat('dd/MM/yy HH:mm').format(st) : '-';

              String statusLabel;
              switch (status) {
                case 'confirmed': statusLabel = 'Confirmé'; break;
                case 'active': statusLabel = 'Actif'; break;
                case 'completed': statusLabel = 'Terminé'; break;
                case 'cancelled': statusLabel = 'Annulé'; break;
                default: statusLabel = status;
              }

              rows.add(pw.TableRow(
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p['name'] ?? '', style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(dateDisplay, style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(durStr, style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(statusLabel, style: cellStyle)),
                  pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(total > 0 ? total.toStringAsFixed(2) : '-', style: cellStyle)),
                ],
              ));
            }

            return [
              pw.Text('Historique des réservations', style: sectionStyle),
              pw.SizedBox(height: 10),
              pw.Text('Total réservations: ${_bookings.length}', style: cellStyle),
              pw.SizedBox(height: 10),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: rows,
              ),
              pw.SizedBox(height: 16),
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green50,
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Total dépensé:', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                    pw.Text('${totalSpent.toStringAsFixed(2)} DT', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold, color: PdfColors.green800)),
                  ],
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Document généré le $dateStr via Smart Parking', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey500)),
            ];
          },
          footer: (context) => pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text('Page ${context.pageNumber}/${context.pagesCount}', style: pw.TextStyle(fontSize: 9, color: PdfColors.grey)),
          ),
        ),
      );

      final bytes = await pdf.save();
      final fileName = 'SmartParking_Historique_${DateFormat('dd_MM_yyyy').format(now)}.pdf';

      if (!mounted) return;
      Navigator.of(context).pop(); // close loading

      await Printing.sharePdf(bytes: bytes, filename: fileName);
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur export PDF: $e'), backgroundColor: Colors.red),
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
        actions: [
          IconButton(
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            tooltip: 'Exporter en PDF',
            onPressed: _exportBookingsPDF,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _bookings.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadBookings,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
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
                            const SizedBox(height: 8),
                            Text(
                              'Tirez vers le bas pour rafraîchir',
                              style: TextStyle(fontSize: 13, color: Colors.grey[400]),
                            ),
                          ],
                        ),
                      ),
                    ),
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
    final checkInTime = booking['checkInTime'] != null
        ? DateTime.parse(booking['checkInTime'])
        : null;
    final checkOutTime = booking['checkOutTime'] != null
        ? DateTime.parse(booking['checkOutTime'])
        : null;
    final qrCode = booking['qrCode'];
    final adminValidated = booking['adminValidated'] ?? false;
    final isRecurring = booking['recurring']?['enabled'] == true;
    final cancellationReason = booking['cancellationReason'];
    final pricing = booking['pricing'];

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
                  // Cancel button for confirmed bookings
                  if (status == 'confirmed')
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _cancelBooking(booking),
                          icon: const Icon(Icons.cancel, color: Colors.red),
                          label: const Text('Annuler la réservation'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red,
                            side: const BorderSide(color: Colors.red),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
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
              Column(
                children: [
                  // Pricing summary for completed bookings
                  if (pricing != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.receipt_long, size: 16, color: Colors.green.shade700),
                                const SizedBox(width: 6),
                                Text('Facture', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.green.shade700)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (checkInTime != null && checkOutTime != null)
                              _buildReceiptRow('Durée réelle', () {
                                final dur = checkOutTime.difference(checkInTime);
                                return dur.inHours > 0
                                    ? '${dur.inHours}h ${dur.inMinutes.remainder(60)}min'
                                    : '${dur.inMinutes}min';
                              }()),
                            _buildReceiptRow('Tarif/h', '${(pricing['rate'] ?? 0).toStringAsFixed(2)} DT'),
                            _buildReceiptRow('Sous-total', '${(pricing['subtotal'] ?? 0).toStringAsFixed(2)} DT'),
                            _buildReceiptRow('TVA (19%)', '${(pricing['tax'] ?? 0).toStringAsFixed(2)} DT'),
                            const Divider(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.green.shade800)),
                                Text('${(pricing['total'] ?? 0).toStringAsFixed(2)} DT',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.green.shade800)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
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
                ],
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

      // After start — check-in deadline (startTime + 30 min)
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

  Widget _buildReceiptRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
