import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../booking/booking_service.dart';
import '../utils/constanst.dart';

class QRCodeDialog extends StatefulWidget {
  final Map<String, dynamic> booking;

  const QRCodeDialog({super.key, required this.booking});

  @override
  State<QRCodeDialog> createState() => _QRCodeDialogState();
}

class _QRCodeDialogState extends State<QRCodeDialog> {
  final ScreenshotController _screenshotController = ScreenshotController();
  bool _isDownloading = false;

  String _extractString(dynamic value, String defaultValue) {
    if (value == null) return defaultValue;
    if (value is String) return value;
    if (value is Map) {
      // If it's an address object, build the address string
      final street = value['street']?.toString() ?? '';
      final city = value['city']?.toString() ?? '';
      if (street.isNotEmpty && city.isNotEmpty) {
        return '$street, $city';
      }
      return street.isNotEmpty ? street : (city.isNotEmpty ? city : defaultValue);
    }
    return value.toString();
  }

  Future<void> _downloadQRCode() async {
    setState(() => _isDownloading = true);

    try {
      final imageFile = await _screenshotController.capture();
      
      if (imageFile != null) {
        final directory = await getApplicationDocumentsDirectory();
        final fileName = 'qr_code_${widget.booking['_id'] ?? DateTime.now().millisecondsSinceEpoch}.png';
        final file = File('${directory.path}/$fileName');
        await file.writeAsBytes(imageFile);

        // Share the file
        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'QR Code de Réservation',
          text: 'Voici votre QR code pour le parking',
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('QR Code téléchargé avec succès!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du téléchargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final qrCode = _extractString(widget.booking['qrCode'], '') ?? widget.booking['_id']?.toString() ?? '';
    final parkingData = widget.booking['parking'];
    final parkingName = _extractString(parkingData?['name'], 'Parking');
    final parkingAddress = _extractString(parkingData?['address'], '');

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Votre QR Code',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColor.navy,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Parking Info
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.navy.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.local_parking, color: AppColor.navy),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          parkingName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColor.navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (parkingAddress.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            parkingAddress,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // QR Code
            if (qrCode.isNotEmpty)
              Screenshot(
                controller: _screenshotController,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        spreadRadius: 2,
                        blurRadius: 8,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      QrImageView(
                        data: qrCode,
                        version: QrVersions.auto,
                        size: 200.0,
                        backgroundColor: Colors.white,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Réservation #${widget.booking['_id']?.toString().substring(0, 8) ?? ''}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              const Text(
                'QR Code non disponible',
                style: TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColor.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline, color: AppColor.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Instructions',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColor.orange,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '1. Présentez ce QR code à l\'entrée du parking\n'
                    '2. Scannez le code pour confirmer votre entrée\n'
                    '3. Garez votre véhicule\n'
                    '4. Payez en espèces à la sortie',
                    style: TextStyle(fontSize: 13, color: Colors.black87),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _downloadQRCode,
                    icon: _isDownloading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.download),
                    label: Text(_isDownloading ? 'Téléchargement...' : 'Télécharger'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: AppColor.navy),
                      foregroundColor: AppColor.navy,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColor.navy,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Fermer',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
