import 'package:flutter/material.dart';
import '../utils/constanst.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Parking Intelligent'),
        backgroundColor: AppColor.navy,
      ),
      body: const Center(
        child: Text('Bienvenue dans l\'application Parking Intelligent'),
      ),
    );
  }
}