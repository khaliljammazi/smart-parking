import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import '../booking/booking_service.dart';

class BookingActionsDialog extends StatelessWidget {
  final String bookingId;
  final String status;
  final VoidCallback onUpdate;
  final String? parkingId;
  final String? endTime;

  const BookingActionsDialog({
    super.key,
    required this.bookingId,
    required this.status,
    required this.onUpdate,
    this.parkingId,
    this.endTime,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            
            // Extend Booking
            if (status == 'active')
              _ActionButton(
                icon: Icons.schedule,
                label: 'Prolonger la réservation',
                color: AppColor.navy,
                onPressed: () {
                  Navigator.pop(context);
                  _showExtendDialog(context);
                },
              ),
            
            const SizedBox(height: 12),
            
            // Cancel Booking
            if (status != 'completed' && status != 'cancelled')
              _ActionButton(
                icon: Icons.cancel,
                label: 'Annuler la réservation',
                color: Colors.red,
                onPressed: () {
                  Navigator.pop(context);
                  _showCancelDialog(context);
                },
              ),
            
            const SizedBox(height: 12),
            
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer'),
            ),
          ],
        ),
      ),
    );
  }

  void _showExtendDialog(BuildContext context) {
    int selectedHours = 1;
    Map<String, dynamic>? pricePreview;
    bool loadingPrice = false;

    Future<void> fetchPrice(StateSetter setState) async {
      if (parkingId == null || endTime == null) return;
      setState(() => loadingPrice = true);
      final end = DateTime.parse(endTime!);
      final newEnd = end.add(Duration(hours: selectedHours));
      final result = await BookingService.calculateSmartPrice(
        parkingId: parkingId!,
        startTime: end.toIso8601String(),
        endTime: newEnd.toIso8601String(),
      );
      setState(() {
        pricePreview = result;
        loadingPrice = false;
      });
    }
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          // Fetch price on first build
          if (pricePreview == null && !loadingPrice && parkingId != null) {
            fetchPrice(setState);
          }

          return AlertDialog(
            title: const Text('Prolonger la réservation'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Combien d\'heures souhaitez-vous ajouter?'),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline),
                      onPressed: selectedHours > 1
                          ? () {
                              setState(() => selectedHours--);
                              fetchPrice(setState);
                            }
                          : null,
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColor.navy),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '$selectedHours h',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      onPressed: selectedHours < 12
                          ? () {
                              setState(() => selectedHours++);
                              fetchPrice(setState);
                            }
                          : null,
                    ),
                  ],
                ),
                // Price preview
                if (loadingPrice)
                  const Padding(
                    padding: EdgeInsets.only(top: 16),
                    child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                  ),
                if (pricePreview != null && !loadingPrice) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Coût supplémentaire',
                                style: TextStyle(fontSize: 13, color: Colors.grey)),
                            Text('${(pricePreview!['total'] ?? 0).toStringAsFixed(2)} DT',
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.bold, color: AppColor.navy)),
                          ],
                        ),
                        if (pricePreview!['isPeak'] == true)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_up, size: 14, color: Colors.red),
                                const SizedBox(width: 4),
                                Text(
                                  'Tarif heures de pointe (x${pricePreview!['peakMultiplier']})',
                                  style: const TextStyle(fontSize: 11, color: Colors.red),
                                ),
                              ],
                            ),
                          ),
                        if (pricePreview!['discountType'] == 'off_peak')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.trending_down, size: 14, color: Colors.green),
                                const SizedBox(width: 4),
                                Text(
                                  'Réduction hors pointe -${(pricePreview!['discount'] ?? 0).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 11, color: Colors.green),
                                ),
                              ],
                            ),
                          ),
                        if (pricePreview!['discountType'] == 'long_stay')
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                const Icon(Icons.access_time_filled, size: 14, color: Colors.teal),
                                const SizedBox(width: 4),
                                Text(
                                  'Réduction longue durée -${(pricePreview!['discount'] ?? 0).toStringAsFixed(0)}%',
                                  style: const TextStyle(fontSize: 11, color: Colors.teal),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Annuler'),
              ),
              ElevatedButton(
                onPressed: () => _extendBooking(context, selectedHours),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColor.navy,
                ),
                child: const Text('Confirmer'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showCancelDialog(BuildContext context) {
    final reasonController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Annuler la réservation'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Êtes-vous sûr de vouloir annuler cette réservation?',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reasonController,
              decoration: const InputDecoration(
                labelText: 'Raison (optionnel)',
                border: OutlineInputBorder(),
                hintText: 'Indiquez la raison de l\'annulation',
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Non'),
          ),
          ElevatedButton(
            onPressed: () => _cancelBooking(
              context,
              reasonController.text.isNotEmpty ? reasonController.text : null,
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Oui, annuler'),
          ),
        ],
      ),
    );
  }

  Future<void> _extendBooking(BuildContext context, int hours) async {
    Navigator.pop(context);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await BookingService.extendBooking(
      bookingId: bookingId,
      additionalHours: hours,
    );

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Réservation prolongée de $hours heure(s)'),
            backgroundColor: Colors.green,
          ),
        );
        onUpdate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de la prolongation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _cancelBooking(BuildContext context, String? reason) async {
    Navigator.pop(context);
    
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final result = await BookingService.cancelBooking(bookingId, reason: reason);

    if (context.mounted) {
      Navigator.pop(context); // Close loading
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Réservation annulée'),
            backgroundColor: Colors.green,
          ),
        );
        onUpdate();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Échec de l\'annulation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onPressed;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
