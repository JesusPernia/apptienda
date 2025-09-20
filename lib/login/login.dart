import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/home_page.dart';
import 'package:flutter_application_1/services/auth_services.dart';
import 'package:flutter_application_1/services/secure_storage_service.dart';
import 'package:flutter_signin_button/flutter_signin_button.dart';
// Tu pantalla de productos

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.240:3030',
      connectTimeout: const Duration(
        seconds: 8,
      ), // ✅ Aumentado para evitar timeouts
      receiveTimeout: const Duration(
        seconds: 8,
      ), // ✅ Aumentado para evitar timeouts
    ),
  );

  Future<void> _login() async {
    setState(() => _loading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text.trim(),
          );

      final firebaseToken = await userCredential.user!.getIdToken();

      // ✅ USAR EL NUEVO SERVICE
      await AuthService.loginWithFirebase(firebaseToken!);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } on FirebaseAuthException catch (e) {
      print('❌ Error Firebase: ${e.code} - ${e.message}');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.message}')));
    } catch (e) {
      print('❌ Error general: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error de autenticación')));
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login')),
      body: Padding(
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(labelText: 'Email'),
              keyboardType: TextInputType.emailAddress,
            ),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(labelText: 'Password'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            _loading
                ? CircularProgressIndicator()
                : ElevatedButton(onPressed: _login, child: Text('Login')),

            SignInButton(
              Buttons.Google,
              onPressed: () async {
                final userCredential = await AuthService.signInWithGoogle();
                if (userCredential != null) {
                  final firebaseToken = await userCredential.user?.getIdToken(
                    true,
                  );
                  if (firebaseToken != null) {
                    final response = await _dio.post(
                      '/authentication',
                      data: {
                        'strategy': 'firebase',
                        'access_token': firebaseToken,
                      },
                    );
                    final jwt = response.data['accessToken'];
                    await SecureStorageService.saveJwtToken(jwt);
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => HomePage()),
                    );
                  } else {
                    print('❌ No se pudo obtener el token de Firebase');
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

/* import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_application_1/screens/producto_autocomplete.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final Dio dio = Dio(BaseOptions(baseUrl: 'http://192.168.0.240:3030'));
  final emailController = TextEditingController();
  final passController = TextEditingController();
  String? token;

  void _diagnoseNetwork() async {
    print('🔍 Iniciando diagnóstico de red...');

    // 1. Test internet general
    try {
      final response = await Dio().get('https://google.com');
      print('✅ Internet general: OK');
    } catch (e) {
      print('❌ Internet general: Falló');
    }

    // 2. Test puertos en tu IP
    final ports = [3030, 3000]; // ← 3030 primero, que es el correcto
    for (final port in ports) {
      try {
        final socket = await Socket.connect(
          '192.168.0.240',
          port,
          timeout: Duration(seconds: 3),
        );
        socket.destroy();
        print('✅ 192.168.0.240:$port - ACCESIBLE');
      } catch (e) {
        print('❌ 192.168.0.240:$port - INACCESIBLE');
      }
    }
  }

  Future<void> login() async {
    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
            email: emailController.text.trim(),
            password: passController.text.trim(),
          );

      final firebaseToken = await userCredential.user!.getIdToken();
      print('✅ Firebase Token obtenido');

      // ✅ Usa el puerto CORRECTO: 3030
      final canConnect = await _testServerConnection();
      if (!canConnect) {
        print('No se puede conectar al servidor');
        return;
      }

      // ✅ ENVÍA al puerto CORRECTO: 3030
      await _sendToFeathers(firebaseToken!);
    } catch (e) {
      print('❌ Error en login: $e');
      print('Error de autenticación');
    }
  }

  Future<void> _sendToFeathers(String firebaseToken) async {
    try {
      final dio = Dio();

      final response = await dio.post(
        'http://192.168.0.240:3030/authentication', // ← PUERTO 3030
        data: {'strategy': 'firebase', 'access_token': firebaseToken},
        options: Options(
          headers: {'Content-Type': 'application/json'},
          sendTimeout: Duration(seconds: 10),
          receiveTimeout: Duration(seconds: 10),
        ),
      );

      print('✅ Feathers Status: ${response.statusCode}');
      print('✅ Feathers Response: ${response.data}');

      final jwt = response.data['accessToken'];
      if (jwt != null) {
        print('🎉 JWT obtenido!');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => ProductosBusqueda()),
        );
      }
    } on DioException catch (e) {
      print('❌ Error Dio: ${e.type}');
      print('❌ Message: ${e.message}');
      print('❌ Response: ${e.response?.data}');
      print('❌ Status: ${e.response?.statusCode}');
    }
  }

  Future<bool> _testServerConnection() async {
    try {
      // ✅ Puerto CORRECTO: 3030
      final socket = await Socket.connect(
        '192.168.0.240',
        3030,
        timeout: Duration(seconds: 3),
      );
      socket.destroy();
      print('✅ Servidor accesible en 192.168.0.240:3030');
      return true;
    } catch (e) {
      print('❌ No se puede conectar al servidor: $e');
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Login Firebase')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: emailController,
              decoration: InputDecoration(labelText: 'Correo'),
            ),
            TextField(
              controller: passController,
              decoration: InputDecoration(labelText: 'Contraseña'),
              obscureText: true,
            ),
            SizedBox(height: 20),
            ElevatedButton(onPressed: login, child: Text('Iniciar sesión')),
            if (token != null) ...[
              SizedBox(height: 20),
              Text(
                'Token obtenido:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SelectableText(token!),
            ],
            ElevatedButton(
              onPressed: _diagnoseNetwork,
              child: Text('Diagnosticar Red'),
            ),
          ],
        ),
      ),
    );
  }
} */
