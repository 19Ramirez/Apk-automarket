import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() => _auth.currentUser;
  String? getCurrentUserId() => _auth.currentUser?.uid;
  bool isUserLoggedIn() => _auth.currentUser != null;

  // VEHÍCULOS
  Future<void> saveVehicle(Vehicle vehicle) async {
    try {
      final userId = getCurrentUserId();
      if (userId == null) throw Exception('Usuario no autenticado');
      
      if (vehicle.id == null) {
        final docRef = _firestore.collection('vehicles').doc();
        vehicle.id = docRef.id;
        vehicle.userId = userId;
      }
      
      await _firestore.collection('vehicles').doc(vehicle.id).set(
        vehicle.toMap()..['updatedAt'] = FieldValue.serverTimestamp()
      );
    } catch (e) {
      throw Exception('Error al guardar vehículo: $e');
    }
  }

  Stream<List<Vehicle>> getVehicles() {
    return _firestore
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) =>
            Vehicle.fromMap(doc.id, doc.data()!)
        ).toList());
  }

  Stream<List<Vehicle>> getUserVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) =>
            Vehicle.fromMap(doc.id, doc.data()!)
        ).toList());
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _firestore.collection('vehicles').doc(vehicle.id).update(
        vehicle.toMap()..['updatedAt'] = FieldValue.serverTimestamp()
      );
    } catch (e) {
      throw Exception('Error al actualizar vehículo: $e');
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).delete();
    } catch (e) {
      throw Exception('Error al eliminar vehículo: $e');
    }
  }

  // USUARIOS
  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(
        user.toMap()..['updatedAt'] = FieldValue.serverTimestamp()
      );
    } catch (e) {
      throw Exception('Error al guardar usuario: $e');
    }
  }

  Stream<UserModel?> getUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? 
            UserModel.fromMap(userId, snapshot.data()!) : null);
  }

  // ADMINISTRACIÓN
  Future<bool> isUserAdmin(String userId) async {
    const superAdminUid = 'XCs21m7R5aQuyfSwMw6F27s3zP13';
    
    if (userId == superAdminUid) return true;
    
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error verificando admin: $e');
      return false;
    }
  }

  Future<void> addAdmin(String userId) async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null || !await isUserAdmin(currentUserId)) {
        throw Exception('No tienes permisos de administrador');
      }
      
      await _firestore.collection('admins').doc(userId).set({
        'isAdmin': true,
        'addedBy': currentUserId,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar administrador: $e');
    }
  }

  Future<void> removeAdmin(String userId) async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null || !await isUserAdmin(currentUserId)) {
        throw Exception('No tienes permisos de administrador');
      }
      
      if (userId == 'XCs21m7R5aQuyfSwMw6F27s3zP13') {
        throw Exception('No se puede eliminar al super administrador');
      }
      
      await _firestore.collection('admins').doc(userId).delete();
    } catch (e) {
      throw Exception('Error al eliminar administrador: $e');
    }
  }

  Stream<List<Map<String, dynamic>>> getAdminsStream() {
    return _firestore
        .collection('admins')
        .snapshots()
        .asyncMap((snapshot) async {
      final adminsList = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        try {
          final userDoc = await _firestore.collection('users').doc(doc.id).get();
          final userData = userDoc.data();
          
          adminsList.add({
            'uid': doc.id,
            'adminData': doc.data(),
            'userInfo': userData,
            'email': userData?['email'] ?? 'No disponible',
            'displayName': userData?['displayName'] ?? 'No disponible',
            'isSuperAdmin': doc.id == 'XCs21m7R5aQuyfSwMw6F27s3zP13',
          });
        } catch (e) {
          print('Error obteniendo info del admin ${doc.id}: $e');
          adminsList.add({
            'uid': doc.id,
            'adminData': doc.data(),
            'userInfo': null,
            'email': 'Error al cargar',
            'displayName': 'Error al cargar',
            'isSuperAdmin': doc.id == 'XCs21m7R5aQuyfSwMw6F27s3zP13',
          });
        }
      }
      
      const superAdminUid = 'XCs21m7R5aQuyfSwMw6F27s3zP13';
      final hasSuperAdmin = adminsList.any((admin) => admin['uid'] == superAdminUid);
      
      if (!hasSuperAdmin) {
        try {
          final superAdminUser = await _firestore.collection('users').doc(superAdminUid).get();
          final userData = superAdminUser.data();
          
          adminsList.insert(0, {
            'uid': superAdminUid,
            'adminData': {
              'isAdmin': true,
              'isSuperAdmin': true,
              'addedAt': null,
            },
            'userInfo': userData,
            'email': userData?['email'] ?? 'superadmin@email.com',
            'displayName': userData?['displayName'] ?? 'Super Administrador',
            'isSuperAdmin': true,
          });
        } catch (e) {
          print('Error obteniendo info del super admin: $e');
          adminsList.insert(0, {
            'uid': superAdminUid,
            'adminData': {
              'isAdmin': true,
              'isSuperAdmin': true,
              'addedAt': null,
            },
            'userInfo': null,
            'email': 'superadmin@email.com',
            'displayName': 'Super Administrador',
            'isSuperAdmin': true,
          });
        }
      }
      
      return adminsList;
    });
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final currentUserId = getCurrentUserId();
      if (currentUserId == null || !await isUserAdmin(currentUserId)) {
        throw Exception('No autorizado');
      }
      
      final usersCount = (await _firestore.collection('users').get()).size;
      final vehiclesCount = (await _firestore.collection('vehicles').get()).size;
      final adminsCount = (await _firestore.collection('admins').get()).size + 1;
      
      return {
        'totalUsers': usersCount,
        'totalVehicles': vehiclesCount,
        'totalAdmins': adminsCount,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // VERIFICACIÓN SIMPLIFICADA PARA ELIMINACIÓN
  Future<Map<String, dynamic>> checkDeletePermissions() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'canDelete': false,
          'message': 'No hay usuario autenticado',
          'userEmail': 'No autenticado',
        };
      }

      final userId = user.uid;
      
      // Cualquier usuario puede eliminar EXCEPTO super admin
      if (isSuperAdmin(userId)) {
        return {
          'canDelete': false,
          'message': 'No se puede eliminar la cuenta del super administrador',
          'userEmail': user.email,
        };
      }

      return {
        'canDelete': true,
        'message': 'Puedes eliminar tu cuenta',
        'userEmail': user.email,
        'userId': userId,
      };

    } catch (e) {
      return {
        'canDelete': false,
        'message': 'Error al verificar: $e',
        'userEmail': 'Error',
      };
    }
  }

  // ELIMINACIÓN DE CUENTA - CUALQUIER USUARIO PUEDE ELIMINAR
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado');
      }

      final userId = user.uid;
      final userEmail = user.email ?? 'Sin email';
      
      print('🔄 Iniciando eliminación para: $userEmail ($userId)');

      // Verificar que no sea super admin (protección extra)
      if (isSuperAdmin(userId)) {
        throw Exception('No se puede eliminar la cuenta del super administrador');
      }

      // ELIMINACIÓN PASO A PASO - SIN VERIFICACIONES COMPLEJAS
      print('🗑️ Paso 1: Eliminando vehículos...');
      await _deleteUserVehiclesSimple(userId);

      print('🗑️ Paso 2: Eliminando chats...');
      await _deleteUserChats(userId);

      print('🗑️ Paso 3: Eliminando permisos de admin (si existen)...');
      await _deleteAdminPermissions(userId);

      print('🗑️ Paso 4: Eliminando usuario de Firestore...');
      await _firestore.collection('users').doc(userId).delete();

      print('🔐 Paso 5: Eliminando cuenta de autenticación...');
      await user.delete();

      print('🚪 Paso 6: Cerrando sesión...');
      await _auth.signOut();

      print('✅ ELIMINACIÓN COMPLETADA EXITOSAMENTE');

    } catch (e) {
      print('❌ Error en eliminación: $e');
      _handleDeleteError(e);
    }
  }

  // MÉTODO MEJORADO PARA ELIMINAR PERMISOS DE ADMIN
  Future<void> _deleteAdminPermissions(String userId) async {
    try {
      // Intentar eliminar directamente - las reglas permiten si es el propio usuario
      await _firestore.collection('admins').doc(userId).delete();
      print('✅ Permisos de admin eliminados');
    } catch (e) {
      // Si falla, probablemente porque no era admin o no existe
      print('ℹ️ Usuario no tenía permisos de admin o no se pudieron eliminar: $e');
      // No relanzar excepción - no es crítico para la eliminación
    }
  }

  // MÉTODO SIMPLIFICADO PARA ELIMINAR VEHÍCULOS
  Future<void> _deleteUserVehiclesSimple(String userId) async {
    try {
      final vehiclesSnapshot = await _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: userId)
          .get();

      if (vehiclesSnapshot.docs.isEmpty) {
        print('ℹ️ No hay vehículos para eliminar');
        return;
      }

      // Eliminar en lotes
      final batch = _firestore.batch();
      for (final doc in vehiclesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      
      print('✅ ${vehiclesSnapshot.docs.length} vehículos eliminados');
    } catch (e) {
      print('⚠️ Error eliminando vehículos: $e');
      // Continuar con la eliminación aunque falle este paso
    }
  }

  // MÉTODO SIMPLIFICADO PARA ELIMINAR CHATS
  Future<void> _deleteUserChats(String userId) async {
    try {
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants.$userId', isGreaterThan: '')
          .get();

      if (chatsQuery.docs.isEmpty) {
        print('ℹ️ No hay chats para eliminar');
        return;
      }

      final batch = _firestore.batch();
      
      for (final chatDoc in chatsQuery.docs) {
        try {
          // Eliminar mensajes del chat
          final messages = await chatDoc.reference.collection('messages').get();
          for (final messageDoc in messages.docs) {
            batch.delete(messageDoc.reference);
          }
          
          // Eliminar el chat
          batch.delete(chatDoc.reference);
        } catch (e) {
          print('⚠️ Error procesando chat ${chatDoc.id}: $e');
        }
      }
      
      await batch.commit();
      print('✅ ${chatsQuery.docs.length} chats eliminados');
      
    } catch (e) {
      print('⚠️ Error eliminando chats: $e');
      // No propagar el error
    }
  }

  // MANEJO DE ERRORES ACTUALIZADO
  void _handleDeleteError(dynamic e) {
    final errorMsg = e.toString();
    
    if (errorMsg.contains('permission-denied')) {
      throw Exception(
        'Error de permisos.\n'
        'Las reglas de seguridad no permiten la eliminación.\n'
        'Contacta al administrador del sistema.'
      );
    } else if (errorMsg.contains('requires-recent-login')) {
      throw Exception(
        'Se requiere autenticación reciente.\n'
        'Por favor, cierra sesión y vuelve a iniciar antes de eliminar tu cuenta.'
      );
    } else {
      throw Exception('Error al eliminar la cuenta: $e');
    }
  }

  // VERIFICACIÓN DE DATOS (OPCIONAL)
  Future<Map<String, dynamic>> verifyUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return {
          'exists': false, 
          'message': 'No autenticado',
          'userId': null,
          'userEmail': null,
          'vehiclesCount': 0,
          'isAdmin': false
        };
      }

      final userId = user.uid;
      
      // Verificar usuario en Firestore
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final userExists = userDoc.exists;

      // Verificar vehículos
      final vehicles = await _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: userId)
          .get();

      return {
        'exists': userExists,
        'userId': userId,
        'userEmail': user.email,
        'vehiclesCount': vehicles.docs.length,
        'message': userExists ? 
          'Usuario encontrado con ${vehicles.docs.length} vehículos' : 
          'Usuario NO encontrado en Firestore'
      };
    } catch (e) {
      return {
        'exists': false,
        'message': 'Error al verificar: $e',
        'vehiclesCount': 0,
        'userId': null,
        'userEmail': null
      };
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool isSuperAdmin(String userId) {  
    return userId == 'XCs21m7R5aQuyfSwMw6F27s3zP13';
  }
}