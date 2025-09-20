import 'dart:convert';

class JwtService {
  static Map<String, dynamic> decode(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        throw Exception('Token JWT inválido');
      }

      final payload = _decodeBase64(parts[1]);
      final payloadMap = json.decode(payload);

      return payloadMap is Map<String, dynamic> ? payloadMap : {};
    } catch (e) {
      print('❌ Error decodificando JWT: $e');
      return {};
    }
  }

  static String _decodeBase64(String str) {
    String output = str.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Cadena base64 inválida');
    }

    return utf8.decode(base64Url.decode(output));
  }

  static String? getUserId(String token) {
    try {
      final payload = decode(token);
      print('🔍 Payload JWT completo: $payload');

      // Para Firebase Auth, el user ID está en 'user_id' no en 'userId'
      return payload['user_id'] ?? // Firebase UID
          payload['sub'] ?? // Firebase subject
          payload['userId'] ?? // Posible alternativa
          payload['_id'] ??
          payload['id'];
    } catch (e) {
      print('❌ Error obteniendo user ID from JWT: $e');
      return null;
    }
  }

  static String? getFirebaseUid(String token) {
    try {
      final payload = decode(token);
      return payload['user_id'] ?? payload['sub'];
    } catch (e) {
      print('❌ Error obteniendo Firebase UID: $e');
      return null;
    }
  }

  static String? getUserEmail(String token) {
    try {
      final payload = decode(token);
      return payload['email'];
    } catch (e) {
      print('❌ Error obteniendo email: $e');
      return null;
    }
  }

  static DateTime? getExpiration(String token) {
    try {
      final payload = decode(token);
      final exp = payload['exp'];
      if (exp != null && exp is int) {
        return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
      }
      return null;
    } catch (e) {
      print('❌ Error obteniendo expiración: $e');
      return null;
    }
  }

  static bool isExpired(String token) {
    try {
      final expiration = getExpiration(token);
      if (expiration == null) return false;
      return DateTime.now().isAfter(expiration);
    } catch (e) {
      print('❌ Error verificando expiración: $e');
      return true;
    }
  }

  // Método para debug
  static void printTokenInfo(String token) {
    try {
      final payload = decode(token);
      print('🔐 === INFORMACIÓN DEL TOKEN ===');
      print('📧 Email: ${payload['email']}');
      print('🆔 Firebase UID: ${payload['user_id']}');
      print('🔐 Subject: ${payload['sub']}');
      print('⏰ Expira: ${getExpiration(token)}');
      print('📋 Payload completo: $payload');
      print('🔐 === FIN INFORMACIÓN ===');
    } catch (e) {
      print('❌ Error imprimiendo info del token: $e');
    }
  }
}
