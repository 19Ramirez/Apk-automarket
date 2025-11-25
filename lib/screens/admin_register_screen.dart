import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/user_model.dart';

class AdminRegisterScreen extends StatefulWidget {
  @override
  _AdminRegisterScreenState createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;
  bool _isLoading = false;
  String? _createdUserId;
  bool _showPassword = false;

  // TU UID FIJADO - SOLO TÚ PUEDES CREAR ADMINS
  final String _superAdminUid = 'XCs21m7R5aQuyfSwMw6F27s3zP13';

  Future<void> _registerAdmin() async {
    final currentUser = _auth.currentUser;
    
    // VERIFICAR QUE SOLO TÚ PUEDES CREAR ADMINS
    if (currentUser?.uid != _superAdminUid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Solo el super administrador puede crear nuevos admins')),
      );
      return;
    }

    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor completa email y contraseña')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Crear usuario en Authentication
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text,
        password: _passwordController.text,
      );

      final userId = userCredential.user!.uid;

      // Guardar usuario en Database
      final newUser = UserModel(
        id: userId,
        email: _emailController.text,
        name: _nameController.text.isNotEmpty ? _nameController.text : 'Administrador',
        phone: _phoneController.text.isNotEmpty ? _phoneController.text : 'No especificado',
        createdAt: DateTime.now(),
      );

      await _firebaseService.saveUser(newUser);

      // Hacerlo administrador
      await _firebaseService.addAdmin(userId);

      setState(() {
        _createdUserId = userId;
        _isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('✅ Administrador creado exitosamente!')),
      );

      // Limpiar formulario
      _emailController.clear();
      _passwordController.clear();
      _nameController.clear();
      _phoneController.clear();

    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error al crear administrador';
      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Ya existe una cuenta con este email';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      setState(() => _isLoading = false);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isLoading = false);
    }
  }

  bool _isSuperAdmin() {
    return _auth.currentUser?.uid == _superAdminUid;
  }

  @override
  Widget build(BuildContext context) {
    if (!_isSuperAdmin()) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Acceso Denegado'),
          backgroundColor: Colors.red[900],
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.block, size: 80, color: Colors.red),
              SizedBox(height: 20),
              Text(
                'Acceso Restringido',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.red),
              ),
              SizedBox(height: 16),
              Text(
                'Solo el super administrador puede\nregistrar nuevos administradores',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.blueGrey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Registrar Administrador'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Banner de Super Admin
            Card(
              color: Colors.orange[50],
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.security, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Super Administrador',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[800]),
                          ),
                          Text(
                            'Solo tú puedes registrar nuevos administradores',
                            style: TextStyle(fontSize: 12, color: Colors.orange[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),

            if (_createdUserId != null) ...[
              Card(
                color: Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Icon(Icons.check_circle, size: 50, color: Colors.green),
                      SizedBox(height: 16),
                      Text(
                        'Administrador Creado',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'UID del nuevo administrador:',
                        style: TextStyle(color: Colors.blueGrey[600]),
                      ),
                      SizedBox(height: 8),
                      Container(
                        padding: EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blueGrey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: SelectableText(
                          _createdUserId!,
                          style: TextStyle(fontFamily: 'monospace', fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],

            Text(
              'Crear Nuevo Administrador',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Completa los datos del nuevo administrador',
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            SizedBox(height: 16),

            _buildTextField(_emailController, 'Email del administrador*', Icons.email),
            SizedBox(height: 16),
            
            // Campo de contraseña con mostrar/ocultar
            _buildPasswordField(),
            SizedBox(height: 16),
            
            _buildTextField(_nameController, 'Nombre completo*', Icons.person),
            SizedBox(height: 16),
            
            _buildTextField(_phoneController, 'Teléfono*', Icons.phone),
            SizedBox(height: 24),

            _isLoading
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange[600],
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    onPressed: _registerAdmin,
                    child: Text(
                      'CREAR ADMINISTRADOR',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
                  ),

            SizedBox(height: 32),
            Divider(),
            SizedBox(height: 16),

            Text(
              'Administradores Actuales',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 8),
            Text(
              'Lista de todos los usuarios con permisos de administrador',
              style: TextStyle(color: Colors.blueGrey[600]),
            ),
            SizedBox(height: 16),

            StreamBuilder(
              stream: _firebaseService.getAdminsStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Error: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                final adminsMap = snapshot.data as Map?;
                final admins = adminsMap?.entries.where((entry) => entry.value == true).toList() ?? [];

                if (admins.isEmpty) {
                  return Card(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No hay administradores registrados'),
                    ),
                  );
                }

                return Column(
                  children: admins.map((entry) => Card(
                    margin: EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        entry.key == _superAdminUid ? Icons.security : Icons.admin_panel_settings, 
                        color: entry.key == _superAdminUid ? Colors.orange : Colors.blueGrey,
                      ),
                      title: Text('UID: ${entry.key}'),
                      subtitle: Text(entry.key == _superAdminUid ? 'Super Administrador (Tú)' : 'Administrador'),
                      trailing: entry.key == _superAdminUid 
                          ? Icon(Icons.star, color: Colors.orange)
                          : null,
                    ),
                  )).toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // MÉTODO ESPECÍFICO PARA EL CAMPO DE CONTRASEÑA CON MOSTRAR/OCULTAR
  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        labelText: 'Contraseña* (mínimo 6 caracteres)',
        prefixIcon: Icon(Icons.lock, color: Colors.blueGrey[600]),
        suffixIcon: IconButton(
          icon: Icon(
            _showPassword ? Icons.visibility : Icons.visibility_off,
            color: Colors.blueGrey[600],
          ),
          onPressed: () {
            setState(() {
              _showPassword = !_showPassword;
            });
          },
        ),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blueGrey[50],
      ),
    );
  }

  // MÉTODO PARA CAMPOS DE TEXTO NORMALES
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