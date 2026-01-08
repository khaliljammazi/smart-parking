import 'package:flutter/material.dart';
import '../utils/constanst.dart';

class VehiclePage extends StatelessWidget {
  const VehiclePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes Véhicules'),
        backgroundColor: AppColor.navy,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.directions_car, color: AppColor.navy, size: 40),
              title: const Text('Peugeot 208'),
              subtitle: const Text('TN-123-AB\nCitadine'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            elevation: 4,
            child: ListTile(
              leading: const Icon(Icons.motorcycle, color: AppColor.navy, size: 40),
              title: const Text('Yamaha MT-07'),
              subtitle: const Text('TN-456-CD\nMoto'),
              trailing: IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () {},
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColor.navy,
        child: const Icon(Icons.add),
      ),
    );
  }
}