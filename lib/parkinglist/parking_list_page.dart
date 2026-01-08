import 'package:flutter/material.dart';
import '../model/parking_model.dart';
import '../utils/constanst.dart';
import '../location/map_page.dart';

class ParkingListPage extends StatelessWidget {
  const ParkingListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Places de Parking'),
        backgroundColor: AppColor.navy,
        actions: [
          IconButton(
            icon: const Icon(Icons.map),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MapPage()),
              );
            },
            tooltip: 'Voir sur la carte',
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: mockParkingSpots.length,
        itemBuilder: (context, index) {
          final spot = mockParkingSpots[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: ListTile(
              title: Text(spot.name),
              subtitle: Text('${spot.address}\n${spot.pricePerHour} DT/heure • ${spot.availableSpots} places disponibles'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star, color: Colors.amber),
                  Text(spot.rating.toString()),
                ],
              ),
              onTap: () {
                // Navigate to detail page
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Sélectionné ${spot.name}')),
                );
              },
            ),
          );
        },
      ),
    );
  }
}