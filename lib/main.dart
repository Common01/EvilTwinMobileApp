import 'package:flutter/material.dart';
import 'package:wifi_app/page/link.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Wi-Fi Scanner',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const LinkPage(), 
    );
  }
}