import 'package:flutter/material.dart';
import 'package:flutter_application_1/login/login.dart';
import 'package:flutter_application_1/services/auth_services.dart';
// Tu pantalla de login

class ProductosBusqueda extends StatefulWidget {
  const ProductosBusqueda({super.key});

  @override
  _ProductosBusquedaState createState() => _ProductosBusquedaState();
}

class _ProductosBusquedaState extends State<ProductosBusqueda> {
  List<dynamic> _productos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  Future<void> _loadProductos() async {
    try {
      // ✅ USAR AuthService.dio (ya tiene el token automáticamente)
      final response = await AuthService.dio.get('/productos');

      setState(() {
        _productos = response.data['data'] ?? response.data;
        _loading = false;
      });

      print('✅ Productos cargados: ${_productos.length}');
    } catch (e) {
      print('❌ Error cargando productos: $e');
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error cargando productos')));
    }
  }

  Future<void> _logout() async {
    await AuthService.logout();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Productos'),
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Cerrar sesión',
          ),
        ],
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator())
          : _productos.isEmpty
          ? Center(child: Text('No hay productos disponibles'))
          : ListView.builder(
              itemCount: _productos.length,
              itemBuilder: (context, index) {
                final producto = _productos[index];
                return ListTile(
                  title: Text(producto['nombre']?.toString() ?? 'Sin nombre'),
                  subtitle: Text(
                    '\$${producto['precio']?.toString() ?? '0.00'}',
                  ),
                  leading: Icon(Icons.shopping_bag),
                );
              },
            ),
    );
  }
}

/* import 'package:flutter/material.dart';
import 'package:flutter_application_1/api_service.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final api = ApiService();
  List productos = [];

  @override
  void initState() {
    super.initState();
    cargarProductos();
  }

  void cargarProductos() async {
    final data = await api.getProductos();
    setState(() => productos = data);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Productos')),
      body: ListView.builder(
        itemCount: productos.length,
        itemBuilder: (_, i) {
          final p = productos[i];
          return ListTile(
            title: Text('${p['nombre']} - ${p['descripcion']}'),
            subtitle: Text('Stock: ${p['stock']} - \$${p['precio']}'),
            trailing: p['activo']
                ? Icon(Icons.check_circle, color: Colors.green)
                : Icon(Icons.cancel, color: Colors.red),
          );
        },
      ),
    );
  }
} */
