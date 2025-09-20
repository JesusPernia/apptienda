import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart'; // Para formatear fechas
import 'package:flutter/services.dart'; // Para el teclado numérico
import 'package:dio/dio.dart'; // Asegúrate de tener Dio
import 'package:mime/mime.dart';

// Importa tu AuthService
import 'package:flutter_application_1/services/auth_services.dart';

class ProductUploadPage extends StatefulWidget {
  const ProductUploadPage({Key? key}) : super(key: key);

  @override
  State<ProductUploadPage> createState() => _ProductUploadPageState();
}

class _ProductUploadPageState extends State<ProductUploadPage> {
  final _formKey = GlobalKey<FormState>();

  // Controladores para los campos de texto
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _stockController = TextEditingController();
  final _codeController = TextEditingController();

  // Categorías predefinidas
  final List<String> _categorias = [
    'ferretería',
    'farmacia',
    'comida',
    'otros',
  ];
  String? _selectedCategoria;

  // Lógica de variantes (ejemplo simple)
  final List<Map<String, dynamic>> _variantes = [];
  List<String> _imageUrls = [];

  // Lógica de promoción (ejemplo simple)
  final _promoTipoController = TextEditingController();
  final _promoValorController = TextEditingController();
  DateTime? _promoFechaInicio;
  DateTime? _promoFechaFin;

  // Método para manejar la carga del producto
  // dentro de _ProductUploadPageState
  Future<void> _uploadProduct() async {
    if (_formKey.currentState!.validate()) {
      try {
        final nuevoProducto = {
          'nombre': _nameController.text,
          'descripcion': _descriptionController.text.isEmpty
              ? null
              : _descriptionController.text,
          'categoria': _selectedCategoria,
          'precio': double.tryParse(_priceController.text) ?? 0.0,
          'stock': int.tryParse(_stockController.text) ?? 0,
          'codigo': _codeController.text.isEmpty
              ? null
              : _codeController
                    .text, // Asegura que el campo se envía como nulo si está vacío
          'unidad': 'unidad',
          'proveedor': {'nombre': 'Proveedor predeterminado', 'contacto': ''},
          'variantes': _variantes,
          'promocion': _promoFechaInicio != null
              ? {
                  'tipo': _promoTipoController.text,
                  'valor': double.tryParse(_promoValorController.text) ?? 0.0,
                  'fecha_inicio': _promoFechaInicio!.toIso8601String(),
                  'fecha_fin': _promoFechaFin!.toIso8601String(),
                }
              : null,
          'imagenes': _imageUrls,
        };

        final response = await AuthService.dio.post(
          '/productos',
          data: nuevoProducto,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('✅ Producto creado con éxito!')),
          );
        }
      } on DioException catch (e) {
        if (mounted) {
          // Captura el mensaje de error específico de la respuesta del backend
          String errorMessage =
              'Error al crear el producto. Inténtelo de nuevo.';

          if (e.response != null && e.response!.data != null) {
            // Feathers puede devolver el error en diferentes formatos.
            // Comprobamos si el error es de tipo 'unique'
            if (e.response!.data['message'] != null &&
                e.response!.data['message'].contains('unique')) {
              errorMessage =
                  'El código o el valor ya existen. Por favor, ingrese un valor único.';
            } else if (e.response!.data['message'] != null) {
              errorMessage = e.response!.data['message'];
            }
          }

          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('❌ $errorMessage')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Ocurrió un error inesperado: $e')),
          );
        }
      }
    }
  }

  // dentro de _ProductUploadPageState

  Future<String?> _uploadImageAndGetUrl() async {
    try {
      final picker = ImagePicker();
      final XFile? pickedFile = await picker.pickImage(
        source: ImageSource.gallery,
      );
      if (pickedFile == null) return null;

      final bytes = await pickedFile.readAsBytes();

      final response = await AuthService.dio.post(
        '/uploads',
        data: {
          "uri": {
            "filename": pickedFile.name,
            "mimetype": lookupMimeType(pickedFile.path) ?? 'image/jpeg',
            "data": bytes,
          },
        },
      );

      if (response.statusCode == 201 && response.data['url'] != null) {
        return response.data['url'];
      }
    } on DioException catch (e) {
      print('❌ Error al subir la imagen: ${e.response?.data}');
    } catch (e) {
      print('❌ Ocurrió un error inesperado: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cargar Nuevo Producto')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                controller: _codeController,
                decoration: const InputDecoration(
                  labelText: 'Codigo del Producto',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el codigo del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Producto',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, ingrese el nombre del producto';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategoria,
                decoration: const InputDecoration(labelText: 'Categoría'),
                items: _categorias.map((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategoria = newValue;
                  });
                },
                validator: (value) =>
                    value == null ? 'Seleccione una categoría' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: 'Precio'),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,2}')),
                ],
                validator: (value) {
                  if (value == null || double.tryParse(value) == null) {
                    return 'Ingrese un precio válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _stockController,
                decoration: const InputDecoration(labelText: 'Stock'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || int.tryParse(value) == null) {
                    return 'Ingrese un stock válido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),

              // Aquí podrías agregar widgets para variantes, promociones e imágenes
              ElevatedButton(
                onPressed: () async {
                  final imageUrl = await _uploadImageAndGetUrl();
                  if (imageUrl != null) {
                    setState(() {
                      _imageUrls.add(imageUrl);
                    });
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Imagen agregada!')),
                    );
                  }
                },
                child: const Text('Seleccionar y Subir Imagen'),
              ),

              // Muestra las imágenes subidas
              Wrap(
                spacing: 8.0,
                runSpacing: 8.0,
                children: _imageUrls
                    .map(
                      (url) => Image.network(
                        url,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: _uploadProduct,
                child: const Text('Cargar Producto'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /*   @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _codeController.dispose();
    _promoTipoController.dispose();
    _promoValorController.dispose();
    super.dispose();
  } */
}
