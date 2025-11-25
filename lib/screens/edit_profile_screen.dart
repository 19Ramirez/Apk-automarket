import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/user_model.dart';

class EditProfileScreen extends StatefulWidget {
  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  UserModel? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userSnapshot = _firebaseService.getUser(user.uid);
      userSnapshot.listen((userData) {
        if (userData != null) {
          setState(() {
            _currentUser = userData;
            _nameController.text = userData.name;
            _phoneController.text = userData.phone;
          });
        }
      });
    }
  }

  Future<void> _updateProfile() async {
    if (_nameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('El nombre es obligatorio')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser!;
      final updatedUser = UserModel(
        id: user.uid,
        email: user.email!,
        name: _nameController.text,
        phone: _phoneController.text,
        createdAt: _currentUser?.createdAt ?? DateTime.now(),
        favorites: _currentUser?.favorites ?? [],
        publicationsCount: _currentUser?.publicationsCount ?? 0,
      );

      await _firebaseService.saveUser(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perfil actualizado exitosamente! ✅')),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar perfil: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Editar Perfil'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          if (_isLoading)
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: CircularProgressIndicator(color: Colors.white)),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Información actual
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Información Actual',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('Email: ${_auth.currentUser?.email ?? "No disponible"}'),
                    Text('Nombre: ${_currentUser?.name ?? "No establecido"}'),
                    Text('Teléfono: ${_currentUser?.phone ?? "No establecido"}'),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),

            Text(
              'Editar Información',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),

            _buildTextField(_nameController, 'Nombre completo*', Icons.person),
            SizedBox(height: 16),
            
            _buildTextField(_phoneController, 'Teléfono', Icons.phone),
            SizedBox(height: 24),

            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _updateProfile,
                    child: Text(
                      'ACTUALIZAR PERFIL',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.blueGrey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blueGrey[50],
      ),
    );
  }
}