import 'package:dio/dio.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/secure_storage_service.dart';
import 'package:flutter_application_1/services/jwt_service.dart';
import 'package:flutter_application_1/services/auth_services.dart';

class UserService {
  // 🔥 Usar la instancia de Dio del AuthService para que los interceptores se apliquen globalmente
  static final Dio _dio = AuthService.dio;

  static User? _currentUser;

  // Ya no es necesario inicializar el interceptor aquí
  // static void initialize() {
  //   _setupInterceptor();
  // }

  static Future<User> _getUserFromMeEndpoint() async {
    final response = await _dio.get('/me');
    print('es user${response.data['user']}');
    _currentUser = User.fromJson(
      response.data['user'],
    ); // ✅ solo el campo 'user'

    if (response.data['user'] == null) {
      throw Exception('Usuario no encontrado con endpoint /me');
    }

    return _currentUser!;
  }

  static Future<User> _getUserByFirebaseUid() async {
    final token = await SecureStorageService.getJwtToken();
    if (token == null) throw Exception('No token disponible');

    final firebaseUid = JwtService.getFirebaseUid(token);
    if (firebaseUid == null) throw Exception('No Firebase UID en token');

    print('🔍 Buscando usuario por Firebase UID: $firebaseUid');
    final response = await _dio.get(
      '/users',
      queryParameters: {'firebaseUid': firebaseUid, '\$limit': 1},
    );

    final users = response.data['data'] ?? response.data;
    if (users is List && users.isNotEmpty) {
      _currentUser = User.fromJson(users.first);
      return _currentUser!;
    }

    throw Exception('Usuario no encontrado con Firebase UID: $firebaseUid');
  }

  static Future<User> _getUserByEmail() async {
    final token = await SecureStorageService.getJwtToken();
    if (token == null) throw Exception('No token disponible');

    final email = JwtService.getUserEmail(token);
    if (email == null) throw Exception('No email en token');

    print('🔍 Buscando usuario por email: $email');
    final response = await _dio.get(
      '/users',
      queryParameters: {'email': email, '\$limit': 1},
    );

    final users = response.data['data'] ?? response.data;
    if (users is List && users.isNotEmpty) {
      _currentUser = User.fromJson(users.first);
      return _currentUser!;
    }

    throw Exception('Usuario no encontrado con email: $email');
  }

  // Se ha eliminado el interceptor duplicado
  // static void _setupInterceptor() {
  //   ...
  // }

  static Future<User> getCurrentUser({bool forceRefresh = false}) async {
    if (_currentUser != null && !forceRefresh) {
      return _currentUser!;
    }

    try {
      print('🔄 Intentando obtener usuario...');

      final strategies = [
        _getUserFromMeEndpoint,
        _getUserByFirebaseUid,
        _getUserByEmail,
      ];

      Exception? lastError;

      for (final strategy in strategies) {
        try {
          final user = await strategy();
          print('✅ Usuario obtenido con ${strategy.runtimeType}');
          return user;
        } catch (e) {
          lastError = e as Exception;
          print('⚠️ Estrategia falló: $e');
          continue;
        }
      }

      throw lastError ?? Exception('Todas las estrategias fallaron');
    } catch (e) {
      print('❌ Error obteniendo usuario: $e');
      rethrow;
    }
  }

  static Future<List<User>> getAllUsers() async {
    try {
      print('🔄 Obteniendo todos los usuarios...');
      final response = await _dio.get('/users');

      List<dynamic> usersData;
      if (response.data is Map && response.data.containsKey('data')) {
        usersData = response.data['data'];
      } else if (response.data is List) {
        usersData = response.data;
      } else {
        throw Exception('Formato de respuesta inesperado');
      }

      final users = usersData
          .map((userData) => User.fromJson(userData))
          .toList();
      print('✅ ${users.length} usuarios obtenidos');
      return users;
    } catch (e) {
      print('❌ Error obteniendo todos los usuarios: $e');
      rethrow;
    }
  }

  static Future<User> updateUserLevel(String userId, String newLevel) async {
    try {
      print('🔄 Actualizando nivel del usuario $userId a $newLevel');

      final response = await _dio.patch(
        '/users/$userId',
        data: {'level': newLevel},
      );

      final updatedUser = User.fromJson(response.data);
      print('✅ Nivel de usuario actualizado');

      if (_currentUser?.id == userId) {
        _currentUser = updatedUser;
      }

      return updatedUser;
    } catch (e) {
      print('❌ Error actualizando nivel de usuario: $e');
      rethrow;
    }
  }

  static Future<void> deleteUser(String userId) async {
    try {
      print('🔄 Eliminando usuario $userId');
      await _dio.delete('/users/$userId');
      print('✅ Usuario eliminado');
    } catch (e) {
      print('❌ Error eliminando usuario: $e');
      rethrow;
    }
  }

  static Future<bool> isCurrentUserAdmin() async {
    try {
      final user = await getCurrentUser();
      return user.level == UserLevel.admin;
    } catch (e) {
      print('❌ Error verificando permisos de admin: $e');
      return false;
    }
  }

  static Future<List<User>> searchUsers(String query) async {
    try {
      final response = await _dio.get(
        '/users',
        queryParameters: {'query': query, '\$limit': 50},
      );

      List<dynamic> usersData;
      if (response.data is Map && response.data.containsKey('data')) {
        usersData = response.data['data'];
      } else if (response.data is List) {
        usersData = response.data;
      } else {
        throw Exception('Formato de respuesta inesperado');
      }

      return usersData.map((userData) => User.fromJson(userData)).toList();
    } catch (e) {
      print('❌ Error buscando usuarios: $e');
      rethrow;
    }
  }

  static Future<User> updateUser(Map<String, dynamic> updates) async {
    try {
      final user = await getCurrentUser();
      final response = await _dio.patch('/users/${user.id}', data: updates);
      _currentUser = User.fromJson(response.data);
      return _currentUser!;
    } catch (e) {
      print('❌ Error actualizando usuario: $e');
      rethrow;
    }
  }

  static Future<void> logout() async {
    _currentUser = null;

    // 🔒 Elimina token guardado
    await SecureStorageService.deleteJwtToken();

    // 🧼 Limpia headers de autorización
    //_dio.options.headers.remove('Authorization');

    // 🧠 Limpia interceptores si usas alguno

    // 🔄 Opcional: reinicia Dio si lo necesitas
    //_dio = Dio(); // solo si necesitas reiniciar completamente

    // 🧹 Limpia cualquier caché adicional si usas Provider, Riverpod, etc.
  }

  static User? get currentUser => _currentUser;
}
