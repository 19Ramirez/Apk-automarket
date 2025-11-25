import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/user_model.dart';

class AuthScreen extends StatefulWidget {
  @override
  _AuthScreenState createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _auth = FirebaseAuth.instance;
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;
  bool _isLogin = true;
  bool _showPassword = false;

  Future<void> _submit() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    if (!_isLogin && (_nameController.text.isEmpty || _phoneController.text.isEmpty)) {
      _showSnackBar('Por favor completa todos los campos');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (_isLogin) {
        await _auth.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );
        _showSnackBar('✅ Sesión iniciada correctamente');
      } else {
        final userCredential = await _auth.createUserWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text.trim(),
        );

        final newUser = UserModel(
          id: userCredential.user!.uid,
          email: _emailController.text.trim(),
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          createdAt: DateTime.now(),
        );

        await FirebaseService().saveUser(newUser);
        _showSnackBar('✅ Cuenta creada correctamente');
        
        // Cambiar a login después del registro
        setState(() {
          _isLogin = true;
          _nameController.clear();
          _phoneController.clear();
        });
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Error de autenticación';
      if (e.code == 'weak-password') {
        errorMessage = 'La contraseña es muy débil';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'Ya existe una cuenta con este email';
      } else if (e.code == 'user-not-found') {
        errorMessage = 'Usuario no encontrado';
      } else if (e.code == 'wrong-password') {
        errorMessage = 'Contraseña incorrecta';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Email inválido';
      }
      _showSnackBar(errorMessage);
    } catch (e) {
      _showSnackBar('Error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blueGrey[50],
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(20),
          child: Column(
            children: [
              SizedBox(height: 20),
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'lib/images/login.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: 20),
              Text(
                'AutoMarket',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.blueGrey[800],
                ),
              ),
              SizedBox(height: 8),
              Text(
                _isLogin ? 'Inicia sesión en tu cuenta' : 'Crea tu cuenta',
                style: TextStyle(color: Colors.blueGrey[600]),
              ),
              SizedBox(height: 30),

              // Formulario
              if (!_isLogin) ...[
                _buildTextField(_nameController, 'Nombre completo', Icons.person),
                SizedBox(height: 16),
                _buildTextField(_phoneController, 'Teléfono', Icons.phone),
                SizedBox(height: 16),
              ],
              _buildTextField(_emailController, 'Correo electrónico', Icons.email),
              SizedBox(height: 16),
              _buildPasswordField(),
              SizedBox(height: 24),

              // Botón
              _isLoading
                  ? Center(child: CircularProgressIndicator())
                  : SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey[800],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _submit,
                        child: Text(
                          _isLogin ? 'Iniciar Sesión' : 'Registrarse',
                          style: TextStyle(fontSize: 16, color: Colors.white),
                        ),
                      ),
                    ),

              SizedBox(height: 20),
              TextButton(
                onPressed: () {
                  setState(() => _isLogin = !_isLogin);
                },
                child: Text(
                  _isLogin 
                      ? '¿No tienes cuenta? Regístrate' 
                      : '¿Ya tienes cuenta? Inicia sesión',
                  style: TextStyle(color: Colors.blueGrey[700]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_showPassword,
      decoration: InputDecoration(
        hintText: 'Contraseña',
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
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: Colors.blueGrey[600]),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }
}