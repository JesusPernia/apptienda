import 'package:flutter/material.dart';
import 'package:dio/dio.dart';

class ProductosBusqueda extends StatefulWidget {
  const ProductosBusqueda({super.key});

  @override
  State<ProductosBusqueda> createState() => _ProductosBusquedaState();
}

class _ProductosBusquedaState extends State<ProductosBusqueda> {
  final Dio dio = Dio(
    BaseOptions(baseUrl: 'http://192.168.0.240:3030'),
  ); // cambia a tu IP local
  List productos = [];
  String query = '';
  bool cargando = false;

  void buscar(String texto) async {
    setState(() {
      query = texto;
      cargando = true;
    });

    if (texto.length < 2) {
      setState(() {
        productos = [];
        cargando = false;
      });
      return;
    }

    try {
      final response = await dio.get(
        '/productos',
        queryParameters: {'nombre': texto},
      );
      setState(() {
        productos = response.data;
        cargando = false;
      });
    } catch (e) {
      setState(() {
        productos = [];
        cargando = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Buscar productos')),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar por nombre',
                border: OutlineInputBorder(),
              ),
              onChanged: buscar,
            ),
          ),
          if (cargando) CircularProgressIndicator(),
          Expanded(
            child: ListView.builder(
              itemCount: productos.length,
              itemBuilder: (_, i) {
                final p = productos[i];
                return ListTile(
                  title: Text(p['nombre']),
                  subtitle: Text('Stock: ${p['stock']} - \$${p['precio']}'),
                  trailing: p['activo']
                      ? Icon(Icons.check_circle, color: Colors.green)
                      : Icon(Icons.cancel, color: Colors.red),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
