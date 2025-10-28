import 'package:absen_app/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi locale Indonesia
  await initializeDateFormatting('id_ID', null);
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
      home: const SplashScreen(),
    );
  }
}
