import 'package:flutter/material.dart';
import 'package:frontend/screens/login_screen.dart';
// import 'package:frontend/screens/home_screen.dart';


void main() {
  runApp(EcoWasteManagerApp());
}

class EcoWasteManagerApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'EcoWaste Manager',
      theme: ThemeData(
        primaryColor: Color(0xFF4CAF50), // Green primary
        colorScheme: ColorScheme.fromSwatch().copyWith(
          secondary: Color(0xFF8BC34A), // Light Green secondary
        ),
      ),
       home: LoginScreen(),
      // home:
      //     // HomeScreen(), // Uncomment this line to use HomeScreen instead of AuthScreen
    );
  }
}
