import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/screens/auth_screen.dart';
import 'package:auto_market/screens/admin_screen.dart';
import 'package:auto_market/screens/admin_register_screen.dart';
import 'package:auto_market/screens/edit_profile_screen.dart';
import 'package:auto_market/screens/my_publications_screen.dart';
import 'package:auto_market/screens/favorites_screen.dart';
import 'package:auto_market/screens/chat_list_screen.dart';
import 'package:auto_market/services/firebase_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _auth = FirebaseAuth.instance;
  final FirebaseService _firebaseService = FirebaseService();
  bool _isAdmin = false;
  String _deleteConfirmationText = '';

  @override
  void initState() {
    super.initState();
    _checkAdminStatus();
  }

  Future<void> _checkAdminStatus() async {
    final user = _auth.currentUser;
    if (user != null) {
      final isAdmin = await _firebaseService.isUserAdmin(user.uid);
      setState(() => _isAdmin = isAdmin);
    }
  }

  Future<void> _signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
        (route) => false,
      );
    } catch (e) {
      // Log the error instead of using print
      debugPrint('Error al cerrar sesión: $e');
    }
  }

  // MÉTODO MEJORADO: Diálogo de eliminación de cuenta
  Future<void> _showDeleteAccountDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Eliminar Cuenta Permanentemente',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Esta acción eliminará permanentemente tu cuenta y todos los datos asociados. ¿Estás completamente seguro?',
                style: TextStyle(fontSize: 16, height: 1.4),
              ),
              SizedBox(height: 16),
              
              // Sección de datos que se eliminarán
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📁 Se eliminarán los siguientes datos:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 8),
                    _buildDeleteItem('👤 Tu perfil de usuario'),
                    _buildDeleteItem('🚗 Todas tus publicaciones de vehículos'),
                    _buildDeleteItem('💬 Tus conversaciones y mensajes'),
                    _buildDeleteItem('⭐ Tus favoritos y preferencias'),
                    if (_isAdmin) 
                      _buildDeleteItem('⚙️ Tus privilegios de administrador'),
                  ],
                ),
              ),
              SizedBox(height: 12),
              
              // Advertencia importante
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[100]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.error_outline, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta acción NO se puede deshacer. Todos tus datos se perderán permanentemente.',
                        style: TextStyle(
                          color: Colors.red[800],
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 8),
              
              // Campo de confirmación
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[100]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Para confirmar, escribe "ELIMINAR" en el siguiente campo:',
                      style: TextStyle(
                        color: Colors.orange[800],
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(height: 8),
                    TextFormField(
                      decoration: InputDecoration(
                        hintText: 'Escribe ELIMINAR aquí...',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onChanged: (value) {
                        // Validación en tiempo real
                        setState(() {
                          _deleteConfirmationText = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          // Botón Cancelar
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              foregroundColor: Colors.blueGrey[600],
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text('Cancelar', style: TextStyle(fontSize: 16)),
          ),
          
          // Botón Eliminar (deshabilitado hasta confirmación)
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _deleteConfirmationText.toUpperCase() == 'ELIMINAR' 
                  ? Colors.red 
                  : Colors.grey,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: _deleteConfirmationText.toUpperCase() == 'ELIMINAR'
                ? () => Navigator.pop(context, true)
                : null,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.delete_forever, size: 20),
                SizedBox(width: 6),
                Text('Eliminar Cuenta', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );

    if (confirmed == true) {
      await _deleteAccountWithLoading();
    }
  }

  // Widget auxiliar para items de eliminación
  Widget _buildDeleteItem(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('• ', style: TextStyle(color: Colors.grey[600])),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.grey[700], fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // MÉTODO ACTUALIZADO: Eliminar cuenta con manejo mejorado de errores
  Future<void> _deleteAccountWithLoading() async {
    bool? finalConfirmation = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 24),
            SizedBox(width: 12),
            Text('Confirmación Final'),
          ],
        ),
        content: Text(
          '¿Estás completamente seguro? Esta es tu última oportunidad para cancelar. '
          'Tu cuenta y todos tus datos se eliminarán permanentemente.'
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Volver Atrás'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text('SÍ, ELIMINAR CUENTA'),
          ),
        ],
      ),
    );

    if (finalConfirmation != true) {
      return; // Usuario canceló en la confirmación final
    }

    // Mostrar diálogo de carga
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Indicador de progreso personalizado
                Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      strokeWidth: 3,
                    ),
                    Icon(Icons.delete_forever, color: Colors.red, size: 20),
                  ],
                ),
                SizedBox(height: 20),
                Text(
                  'Eliminando tu cuenta...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Esto puede tomar unos momentos.\nNo cierres la aplicación.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 8),
                // Progreso simulado
                LinearProgressIndicator(
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    try {
      // INTENTAR PRIMERO EL MÉTODO COMPLETO
      await _firebaseService.deleteUserAccount();
      
      if (!mounted) return;
      Navigator.pop(context); // Cerrar loading
      
      // Mostrar mensaje de éxito
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Cuenta eliminada exitosamente. ¡Esperamos verte de nuevo pronto!',
                  style: TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      
      // Navegar a pantalla de auth
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => AuthScreen()),
        (route) => false,
      );
      
    } catch (e) {
      // SI EL MÉTODO COMPLETO FALLA, INTENTAR EL MÉTODO SIMPLE
      print('❌ Error con método completo, intentando método simple: $e');
      
      try {
        // Método simple como fallback
        final user = _auth.currentUser;
        if (user != null) {
          // Eliminar solo los datos básicos y la cuenta de auth
          await _firebaseService.signOut();
          await user.delete();
        }
        
        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading
        
        // Mostrar mensaje de éxito parcial
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.warning_amber_rounded, color: Colors.white),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Cuenta eliminada, pero algunos datos pueden permanecer en el sistema.',
                    style: TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
        );
        
        // Navegar a pantalla de auth
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => AuthScreen()),
          (route) => false,
        );
        
      } catch (e2) {
        // SI AMBOS MÉTODOS FALLAN
        if (!mounted) return;
        Navigator.pop(context); // Cerrar loading
        
        // Mostrar error detallado
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red),
                SizedBox(width: 8),
                Text('Error al Eliminar Cuenta'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'No se pudo completar la eliminación de tu cuenta. '
                    'Por favor, contacta al soporte técnico.',
                    style: TextStyle(height: 1.4),
                  ),
                  SizedBox(height: 12),
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Posibles causas:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text('• Requiere reautenticación reciente'),
                        Text('• Restricciones de seguridad de Firebase'),
                        Text('• Problemas de permisos'),
                        Text('• Error del servidor'),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Detalles técnicos:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                  Text(
                    'Error principal: ${e.toString()}',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Error fallback: ${e2.toString()}',
                    style: TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Entendido'),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(context); // Cerrar diálogo de error
                  _showDeleteAccountDialog(); // Reintentar
                },
                child: Text('Reintentar'),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        );
      }
    }
  }

  // MÉTODO ACTUALIZADO PARA CONSTRUIR OPCIONES
  Widget _buildOptionItem(String title, IconData icon, VoidCallback onTap, {bool isDangerous = false}) {
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      color: isDangerous ? Colors.red[50] : null,
      child: ListTile(
        leading: Icon(
          icon, 
          color: isDangerous ? Colors.red : Colors.blueGrey[600]
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isDangerous ? Colors.red : null,
            fontWeight: isDangerous ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios, 
          size: 16,
          color: isDangerous ? Colors.red : null,
        ),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mi Perfil'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: _signOut,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información del usuario
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.blueGrey[800],
                      child: Text(
                        user?.email?[0].toUpperCase() ?? 'U',
                        style: TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user?.email ?? 'Usuario',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Miembro desde ${_formatJoinDate(user?.metadata.creationTime)}',
                            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (_isAdmin) ...[
                            SizedBox(height: 4),
                            Chip(
                              label: Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10)),
                              backgroundColor: Colors.orange[600],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 24),
            
            // Estadísticas OPTIMIZADAS
            Text(
              'Mis Estadísticas',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            StreamBuilder<List<dynamic>>(
              stream: _firebaseService.getUserVehicles(user?.uid ?? ''),
              builder: (context, snapshot) {
                final userVehicles = snapshot.data ?? [];
                final activeVehicles = userVehicles.where((v) => !v.isSold).length;
                final soldVehicles = userVehicles.where((v) => v.isSold).length;
                
                return Row(
                  children: [
                    // Publicaciones
                    Expanded(
                      child: _buildStatCard('Pubs', userVehicles.length.toString(), Icons.directions_car),
                    ),
                    SizedBox(width: 8),
                    // Activos
                    Expanded(
                      child: _buildStatCard('Activos', activeVehicles.toString(), Icons.check_circle),
                    ),
                    SizedBox(width: 8),
                    // Vendidos
                    Expanded(
                      child: _buildStatCard('Vendidos', soldVehicles.toString(), Icons.sell),
                    ),
                  ],
                );
              },
            ),
            SizedBox(height: 24),
            
            // Opciones
            Text(
              'Configuración',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 16),
            
            _buildOptionItem('Editar Perfil', Icons.edit, () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => EditProfileScreen())
              );
            }),
            _buildOptionItem('Mis Publicaciones', Icons.list_alt, () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => MyPublicationsScreen())
              );
            }),
            _buildOptionItem('Mis Mensajes', Icons.chat, () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => ChatListScreen())
              );
            }),
            _buildOptionItem('Vehículos Favoritos', Icons.favorite, () {
              Navigator.push(
                context, 
                MaterialPageRoute(builder: (context) => FavoritesScreen())
              );
            }),
            if (_isAdmin)
              _buildOptionItem('Panel Administrador', Icons.admin_panel_settings, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminScreen()));
              }),
            if (_isAdmin && user?.uid == 'XCs21m7R5aQuyfSwMw6F27s3zP13')
              _buildOptionItem('Registrar Administradores', Icons.person_add, () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => AdminRegisterScreen()));
              }),
            
            // OPCIÓN DE ELIMINAR CUENTA
            SizedBox(height: 16),
            Divider(),
            SizedBox(height: 8),
            Text(
              'Zona Peligrosa',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            SizedBox(height: 8),
            _buildOptionItem(
              'Eliminar Cuenta Permanentemente', 
              Icons.delete_forever, 
              _showDeleteAccountDialog,
              isDangerous: true
            ),
            
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          children: [
            Icon(icon, size: 24, color: Colors.blueGrey[600]),
            SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.orange[600]),
            ),
            SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(color: Colors.blueGrey[600], fontSize: 11),
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  String _formatJoinDate(DateTime? date) {
    if (date == null) return 'Fecha desconocida';
    return '${date.day}/${date.month}/${date.year}';
  }
}