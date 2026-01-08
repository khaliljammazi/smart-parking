import 'package:flutter/material.dart';
import '../utils/constanst.dart';

class WalletPage extends StatelessWidget {
  const WalletPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portefeuille'),
        backgroundColor: AppColor.navy,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColor.navy, AppColor.forText],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Solde Actuel',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '150.00 DT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Transactions Récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.payment, color: AppColor.navy),
                    title: Text('Paiement Parking'),
                    subtitle: Text('Parking Centre Ville - 15 DT'),
                    trailing: Text('- 15 DT'),
                  ),
                  ListTile(
                    leading: Icon(Icons.add_circle, color: Colors.green),
                    title: Text('Recharge'),
                    subtitle: Text('Ajouté 50 DT'),
                    trailing: Text('+ 50 DT'),
                  ),
                  ListTile(
                    leading: Icon(Icons.payment, color: AppColor.navy),
                    title: Text('Paiement Parking'),
                    subtitle: Text('Parking Mall - 7.5 DT'),
                    trailing: Text('- 7.5 DT'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {},
        backgroundColor: AppColor.navy,
        child: const Icon(Icons.add),
      ),
    );
  }
}