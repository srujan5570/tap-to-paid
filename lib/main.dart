import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'screens/ios_home_screen.dart';
import 'screens/android_home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tap To Paid',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: defaultTargetPlatform == TargetPlatform.iOS
          ? const IOSHomeScreen()
          : const AndroidHomeScreen(),
    );
  }
}
