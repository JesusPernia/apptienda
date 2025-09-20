import 'package:flutter/material.dart';
import 'package:flutter_application_1/screens/admin_panel.dart';
import 'package:flutter_application_1/screens/upload_productos.dart';

class AdminFunciones extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => AdminFuncionesState();
}

class AdminFuncionesState extends State<AdminFunciones> {
  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return Container(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [_buildActionButtons()],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      children: [
        _buildActionButton(
          icon: Icons.admin_panel_settings,
          text: 'Administracion de Usuarios',
          color: Colors.red,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => AdminPanel()),
            );
          },
        ),

        _buildActionButton(
          icon: Icons.admin_panel_settings,
          text: 'Carga De Productos',
          color: Colors.red,
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ProductUploadPage()),
            );
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String text,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: 12),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 24),
        label: Text(text, style: TextStyle(fontSize: 16)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 3,
        ),
      ),
    );
  }
}
