import 'package:flutter/material.dart';
import 'screens/login_screen.dart';


void main() {
runApp(const AbsensiApp());
}


class AbsensiApp extends StatelessWidget {
const AbsensiApp({super.key});


@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Absensi App',
theme: ThemeData(
colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
useMaterial3: true,
),
debugShowCheckedModeBanner: false,
home: const LoginScreen(),
);
}
}