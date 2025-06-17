import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:safe_scan/services/api_services.dart';
import 'package:safe_scan/views/home_screen.dart';
import 'package:safe_scan/views/splash_screen.dart';

import 'controller/home_contrller.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize dependencies
    Get.put(ApiService());
    Get.put(HomeController());

    return GetMaterialApp(
      title: 'PPE Detection App',
      theme: ThemeData(
        primaryColor: Color(0xFF0D6E71),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF0D6E71),
          primary: Color(0xFF0D6E71),
          secondary: Color(0xFFFF8000),
        ),
        visualDensity: VisualDensity.adaptivePlatformDensity,
        scaffoldBackgroundColor: Colors.grey[50],
      ),
      home: SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
