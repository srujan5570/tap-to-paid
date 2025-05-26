import 'package:flutter/material.dart';

class AndroidHomeScreen extends StatelessWidget {
  const AndroidHomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tap To Paid'),
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Android Version'),
      ),
    );
  }
}
