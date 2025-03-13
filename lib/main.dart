import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:spine/home_screen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(SpinalisDxGenApp());
}

class SpinalisDxGenApp extends StatelessWidget {
  const SpinalisDxGenApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Spinalis DxGen',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}
