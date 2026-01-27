import 'package:flutter/material.dart';
import '../model/parking_model.dart';
import '../utils/constanst.dart';
import '../utils/backend_api.dart';
import '../location/map_page.dart';
import 'parking_detail_page.dart';

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
      body: FutureBuilder<List<ParkingModel>>(
        future: BackendApi.getAllParkingSpots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No parking spots available'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final spot = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ListTile(
                    title: Text(spot.name),
                    subtitle: Text('${spot.address}\n${spot.pricePerHour} DT/heure • ${spot.availableSpots} places disponibles'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        Text(spot.rating.toString()),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ParkingDetailPage(parking: spot),
                        ),
                      );
                    },
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}