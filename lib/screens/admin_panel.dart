import 'package:flutter/material.dart';
import 'package:flutter_application_1/models/user_model.dart';
import 'package:flutter_application_1/services/user_service.dart';

class AdminPanel extends StatefulWidget {
  const AdminPanel({super.key});

  @override
  _AdminPanelState createState() => _AdminPanelState();
}

class _AdminPanelState extends State<AdminPanel> {
  List<User> _users = [];
  bool _loading = true;
  String _searchQuery = '';
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      setState(() {
        _loading = true;
        _errorMessage = '';
      });

      // 🔥 VERIFICAR PERMISOS DE ADMIN
      final isAdmin = await UserService.isCurrentUserAdmin();
      if (!isAdmin) {
        setState(() {
          _errorMessage = 'No tienes permisos de administrador';
          _loading = false;
        });
        return;
      }

      final users = await UserService.getAllUsers();
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error cargando usuarios: $e';
        _loading = false;
      });
    }
  }

  Future<void> _updateUserLevel(User user, UserLevel newLevel) async {
    try {
      setState(() => _loading = true);

      await UserService.updateUserLevel(user.id, newLevel.value);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${user.name} ahora es ${newLevel.displayName}'),
        ),
      );

      await _loadUsers(); // Recargar lista
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _deleteUser(User user) async {
    try {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('¿Eliminar usuario?'),
          content: Text('¿Estás seguro de eliminar a ${user.name}?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancelar'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        setState(() => _loading = true);
        await UserService.deleteUser(user.id);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Usuario eliminado')));
        await _loadUsers();
      }
    } catch (e) {
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error eliminando usuario: $e')));
    }
  }

  Future<void> _searchUsers() async {
    try {
      if (_searchQuery.isEmpty) {
        await _loadUsers();
        return;
      }

      setState(() => _loading = true);
      final users = await UserService.searchUsers(_searchQuery);
      setState(() {
        _users = users;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error buscando usuarios: $e';
        _loading = false;
      });
    }
  }

  Widget _buildUserCard(User user) {
    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatar != null
              ? NetworkImage(user.avatar!)
              : null,
          child: user.avatar == null ? Icon(Icons.person) : null,
        ),
        title: Text(user.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(user.email),
            Chip(
              label: Text('${user.level.icon} ${user.level.displayName}'),
              backgroundColor: _getLevelColor(user.level),
            ),
            Text('ID: ${user.id}'),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Botón para cambiar nivel
            PopupMenuButton<UserLevel>(
              onSelected: (level) => _updateUserLevel(user, level),
              itemBuilder: (context) => UserLevel.values.map((level) {
                return PopupMenuItem(
                  value: level,
                  child: Text('Hacer ${level.displayName}'),
                );
              }).toList(),
            ),
            // Botón para eliminar
            IconButton(
              icon: Icon(Icons.delete, color: Colors.red),
              onPressed: () => _deleteUser(user),
            ),
          ],
        ),
      ),
    );
  }

  Color _getLevelColor(UserLevel level) {
    switch (level) {
      case UserLevel.admin:
        return Colors.red;
      case UserLevel.moderator:
        return Colors.orange;
      case UserLevel.user:
        return Colors.green;
      case UserLevel.guest:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administración'),
        actions: [IconButton(icon: Icon(Icons.refresh), onPressed: _loadUsers)],
      ),
      body: Column(
        children: [
          // Barra de búsqueda
          Padding(
            padding: EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Buscar usuarios',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (value) => _searchQuery = value,
              onSubmitted: (_) => _searchUsers(),
            ),
          ),

          // Mensaje de error
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _errorMessage,
                style: TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
            ),

          // Loading
          if (_loading) LinearProgressIndicator(),

          // Lista de usuarios
          Expanded(
            child: _users.isEmpty && !_loading
                ? Center(child: Text('No hay usuarios'))
                : ListView.builder(
                    itemCount: _users.length,
                    itemBuilder: (context, index) {
                      return _buildUserCard(_users[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
