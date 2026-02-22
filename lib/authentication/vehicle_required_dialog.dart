import 'package:flutter/material.dart';
import '../utils/constanst.dart';
import '../vehicle/vehicle_form_page.dart';

class VehicleRequiredDialog extends StatefulWidget {
  const VehicleRequiredDialog({super.key});

  @override
  State<VehicleRequiredDialog> createState() => _VehicleRequiredDialogState();
}

class _VehicleRequiredDialogState extends State<VehicleRequiredDialog> {
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Row(
        children: [
          Icon(
            Icons.directions_car,
            color: AppColor.orange,
            size: 28,
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Ajoutez votre véhicule',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColor.navy,
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.grey),
            onPressed: () => Navigator.of(context).pop(false),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
      content: const Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pour utiliser nos services de stationnement, vous devez ajouter au moins un véhicule à votre compte.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.black87,
              height: 1.4,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Cela nous aide à fournir des recommandations de parking personnalisées et à gérer vos réservations efficacement.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
              height: 1.3,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(false); // Skip adding vehicle
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            textStyle: const TextStyle(fontSize: 14),
          ),
          child: const Text('Plus tard'),
        ),
        TextButton(
          onPressed: () {
            // Navigate to vehicle form
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const VehicleFormPage(),
              ),
            ).then((result) {
              if (result == true && mounted) {
                Navigator.of(context).pop(true); // Vehicle was added
              }
            });
          },
          style: TextButton.styleFrom(
            foregroundColor: AppColor.orange,
            textStyle: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          child: const Text('Ajouter un véhicule'),
        ),
      ],
    );
  }
}