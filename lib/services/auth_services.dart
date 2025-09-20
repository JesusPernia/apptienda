import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'secure_storage_service.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.240:3030',
      connectTimeout: const Duration(
        seconds: 10,
      ), // ✅ Aumentado para evitar timeouts
      receiveTimeout: const Duration(
        seconds: 10,
      ), // ✅ Aumentado para evitar timeouts
    ),
  );

  static String? _jwt;
  static bool _isRefreshing = false; // Bandera para evitar múltiples refrescos

  // Inicializar el servicio
  static Future<void> initialize() async {
    await _loadToken();
    _setupInterceptor();
  }

  // Cargar token desde Secure Storage
  static Future<void> _loadToken() async {
    try {
      _jwt = await SecureStorageService.getJwtToken();
      if (_jwt != null) {
        print('🔑 Token cargado secure: ${_jwt!.substring(0, 50)}...');
      } else {
        print('ℹ️ No hay token almacenado');
      }
    } catch (e) {
      print('❌ Error cargando token seguro: $e');
    }
  }

  // Configurar interceptor con lógica de refresco de token
  static void _setupInterceptor() {
    _dio.interceptors.clear(); // Limpiar interceptor antes de añadirlo
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (_jwt != null && _jwt!.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $_jwt';
          } else {
            print('⚠️ JWT ausente o vacío, no se añade Authorization');
          }
          /*      if (_jwt != null) {
            options.headers['Authorization'] = 'Bearer $_jwt';
            print(_jwt);
            print('🔄 Request autenticada: ${options.method} ${options.path}');
          } */
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // Si el token ha expirado y no estamos en un proceso de refresco
          if (error.response?.statusCode == 401 &&
              _jwt != null &&
              !_isRefreshing) {
            print('❌ Token expirado, intentando refrescar...');
            _isRefreshing = true;

            try {
              final user = FirebaseAuth.instance.currentUser;
              if (user != null) {
                // Obtener un nuevo token de Firebase
                final newToken = await user.getIdToken(true);
                print('✅ Token refrescado exitosamente.');

                // Actualizar token en memoria y en almacenamiento seguro
                _jwt = newToken;
                await SecureStorageService.saveJwtToken(_jwt!);

                // Clonar la solicitud original con el nuevo token
                final clonedRequest = error.requestOptions;
                clonedRequest.headers['Authorization'] = 'Bearer $_jwt';
                // ✅ actualiza el usuario

                // Re-enviar la solicitud original
                final response = await _dio.request(
                  clonedRequest.path,
                  options: Options(
                    method: clonedRequest.method,
                    headers: {
                      ...clonedRequest.headers,
                      'Authorization': 'Bearer $_jwt',
                    },
                  ),
                  data: clonedRequest.data,
                  queryParameters: clonedRequest.queryParameters,
                );

                _isRefreshing = false;
                return handler.resolve(
                  response,
                ); // Resolver la promesa con la nueva respuesta
              }
            } on FirebaseAuthException catch (e) {
              print('❌ Error de Firebase al refrescar token: $e');
            } catch (e) {
              print('❌ Error general al refrescar token: $e');
            } finally {
              _isRefreshing = false;
            }
          }
          // Si el error no es 401 o el refresco falló, reintentamos la excepción original
          return handler.next(error);
        },
      ),
    );
  }

  // Login con Firebase (versión segura)
  static Future<void> loginWithFirebase(String firebaseToken) async {
    try {
      print('🔄 Iniciando login con Firebase...');

      final response = await _dio.post(
        '/authentication',
        data: {'strategy': 'firebase', 'access_token': firebaseToken},
      );

      _jwt = response.data['accessToken'];

      await SecureStorageService.saveJwtToken(_jwt!);

      print('✅ Login exitoso. Token guardado securemente.');
      _setupInterceptor();
    } catch (e) {
      print('❌ Error en login: $e');
      rethrow;
    }
  }

  //login con google

  static Future<UserCredential?> signInWithGoogle() async {
    final GoogleSignIn googleSignIn = GoogleSignIn(
      scopes: ['email', 'profile'],
    );

    await googleSignIn.signOut();

    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
    if (googleUser == null) return null;

    final GoogleSignInAuthentication googleAuth =
        await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );

    final userCredential = await FirebaseAuth.instance.signInWithCredential(
      credential,
    );

    final firebaseToken = await userCredential.user?.getIdToken();

    final response = await _dio.post(
      '/authentication',
      data: {'strategy': 'firebase', 'access_token': firebaseToken},
    );

    final jwt = response.data['accessToken'];
    await SecureStorageService.saveJwtToken(jwt);
    _jwt = jwt;
    _setupInterceptor();
    return userCredential;
  }

  // Logout (versión segura)
  static Future<void> logout() async {
    try {
      await SecureStorageService.deleteJwtToken();
      _jwt = null;
      _dio.interceptors.clear();
      print('✅ Logout exitoso. Token eliminado securemente.');
    } catch (e) {
      print('❌ Error en logout: $e');
    }
  }

  // Logout completo (elimina todo)
  static Future<void> logoutCompleto() async {
    try {
      await FirebaseAuth.instance.signOut();

      // 🔒 Cerrar sesión en Google
      final googleSignIn = GoogleSignIn();
      await googleSignIn.signOut();

      await SecureStorageService.clearAll();
      _jwt = null;
      _dio.interceptors.clear();
      print('✅ Logout completo exitoso.');
    } catch (e) {
      print('❌ Error en logout completo: $e');
    }
  }

  // Verificar si está autenticado
  static Future<bool> get isAuthenticated async {
    return await SecureStorageService.hasJwtToken();
  }

  // Getter para el token
  static String? get token => _jwt;

  // Getter para Dio instance
  static Dio get dio => _dio;
}
