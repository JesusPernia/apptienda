import 'package:dio/dio.dart';

class ApiService {
  final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://192.168.0.240:3000', // cambia a tu IP local o dominio
      headers: {'Content-Type': 'application/json'},
    ),
  );

  Future<List<dynamic>> getProductos() async {
    final response = await _dio.get('/productos');
    return response.data;
  }

  Future<Map<String, dynamic>> crearVenta(Map<String, dynamic> data) async {
    final response = await _dio.post('/ventas', data: data);
    return response.data;
  }

  Future<List<dynamic>> getVentas() async {
    final response = await _dio.get('/ventas');
    return response.data;
  }
}
