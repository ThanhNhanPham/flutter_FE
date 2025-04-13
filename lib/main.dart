import 'package:flutter/material.dart';
import 'package:flutter_baitap153/Admin/AdminScreen.dart';
import 'package:flutter_baitap153/ChangePasswordScreen.dart';
import 'package:flutter_baitap153/user/UserScreen.dart';
import '../screen/login_screen.dart';


void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Smart Canteen Auth',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: LoginScreen(),
    );
  }
}
