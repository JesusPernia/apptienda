import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorageService {
  static FlutterSecureStorage _storage = FlutterSecureStorage();

  // Método para inyectar mocks en tests
  static void injectMock(FlutterSecureStorage mock) {
    _storage = mock;
  }

  // Opciones de Android
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
  );

  // Opciones de iOS
  static const IOSOptions _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.passcode,
    synchronizable: true,
  );

  // Guardar token JWT
  static Future<void> saveJwtToken(String token) async {
    try {
      await _storage.write(
        key: 'jwt_token',
        value: token,
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      print('🔐 Token JWT guardado securemente');
    } catch (e) {
      print('❌ Error guardando token seguro: $e');
      throw Exception('No se pudo guardar el token securemente');
    }
  }

  // Obtener token JWT
  static Future<String?> getJwtToken() async {
    try {
      final token = await _storage.read(
        key: 'jwt_token',
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      if (token != null) {
        print('🔐 Token JWT recuperado securemente');
      }
      return token;
    } catch (e) {
      print('❌ Error leyendo token seguro: $e');
      return null;
    }
  }

  // Eliminar token JWT
  static Future<void> deleteJwtToken() async {
    try {
      await _storage.delete(
        key: 'jwt_token',
        aOptions: _androidOptions,
        iOptions: _iosOptions,
      );
      print('🔐 Token JWT eliminado seguro');
    } catch (e) {
      print('❌ Error eliminando token seguro: $e');
    }
  }

  // Verificar si existe token
  static Future<bool> hasJwtToken() async {
    try {
      return await _storage.containsKey(key: 'jwt_token');
    } catch (e) {
      print('❌ Error verificando token: $e');
      return false;
    }
  }

  // Limpiar todo el storage seguro
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      print('🔐 Todos los datos seguros eliminados');
    } catch (e) {
      print('❌ Error limpiando storage seguro: $e');
    }
  }
}
