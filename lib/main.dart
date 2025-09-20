import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:flutter_application_1/screens/productos_screen.dart';
import 'services/auth_services.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await AuthService.initialize(); // ✅ Inicializar auth service
  //UserService.initialize();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tienda App Segura',
      theme: ThemeData(primarySwatch: Colors.blue, useMaterial3: true),
      home: FutureBuilder(
        future: Future.delayed(Duration(milliseconds: 500)), // Pequeño delay
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return AuthPageWrapper();
          }
          return SplashScreen();
        },
      ),
    );
  }
}

// Widget para manejar la autenticación
class AuthPageWrapper extends StatelessWidget {
  const AuthPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: AuthService.isAuthenticated,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SplashScreen();
        }

        final isAuthenticated = snapshot.data ?? false;
        return isAuthenticated ? ProductosBusqueda() : LoginPage();
      },
    );
  }
}

// Pantalla de splash
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Cargando...', style: TextStyle(fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
