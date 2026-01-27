import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../utils/constanst.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.navy,
      body: Center(
        child: Lottie.asset('assets/logo/data.json'),
      ),
    );
  }
}