import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/main_screen.dart';
import 'services/api_service.dart';

void main() {
  runApp(const TiendaARApp());
}

class TiendaARApp extends StatelessWidget {
  const TiendaARApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tienda AR',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFEA580C), // Naranja vibrante
          primary: const Color(0xFFEA580C),
        ),
        useMaterial3: true,
      ),
      home: FutureBuilder<String?>(
        future: ApiService().getToken(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          if (snapshot.hasData && snapshot.data != null) {
            return const MainScreen();
          }
          return const LoginScreen();
        },
      ),
    );
  }
}
