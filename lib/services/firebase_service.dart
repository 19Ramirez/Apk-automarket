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
        vehicle.userId = userId; // Asegurar que tenga userId
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
            Vehicle.fromMap(doc.id, doc.data() as Map<String, dynamic>)
        ).toList());
  }

  Stream<List<Vehicle>> getUserVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => 
            Vehicle.fromMap(doc.id, doc.data() as Map<String, dynamic>)
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
      
      // Prevenir que el super admin se elimine a sí mismo
      if (userId == 'XCs21m7R5aQuyfSwMw6F27s3zP13') {
        throw Exception('No se puede eliminar al super administrador');
      }
      
      await _firestore.collection('admins').doc(userId).delete();
    } catch (e) {
      throw Exception('Error al eliminar administrador: $e');
    }
  }

  // MÉTODO getAdminsStream MEJORADO
  Stream<List<Map<String, dynamic>>> getAdminsStream() {
    return _firestore
        .collection('admins')
        .snapshots()
        .asyncMap((snapshot) async {
      final adminsList = <Map<String, dynamic>>[];
      
      for (final doc in snapshot.docs) {
        try {
          // Obtener información del usuario para cada admin
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
          // Agregar admin sin info de usuario
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
      
      // Agregar el super admin si no está en la lista
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
      final adminsCount = (await _firestore.collection('admins').get()).size + 1; // +1 por el super admin
      
      return {
        'totalUsers': usersCount,
        'totalVehicles': vehiclesCount,
        'totalAdmins': adminsCount,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  // ELIMINACIÓN DE CUENTA MEJORADA
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userId = user.uid;
      print('🔄 Iniciando eliminación de cuenta para: $userId');

      // Verificar que el usuario es quien dice ser
      if (user.uid != userId) {
        throw Exception('No autorizado para eliminar esta cuenta');
      }

      // 1. Obtener todos los vehículos del usuario en lotes
      final vehiclesQuery = _firestore
          .collection('vehicles')
          .where('userId', isEqualTo: userId)
          .limit(100);

      final vehiclesSnapshot = await vehiclesQuery.get();
      print('📦 Encontrados ${vehiclesSnapshot.docs.length} vehículos');

      // 2. Eliminar en transacción para mayor seguridad
      await _firestore.runTransaction((transaction) async {
        // Eliminar vehículos
        for (final doc in vehiclesSnapshot.docs) {
          transaction.delete(doc.reference);
        }
        
        // Eliminar usuario
        transaction.delete(_firestore.collection('users').doc(userId));
        
        // Eliminar de admins si existe
        transaction.delete(_firestore.collection('admins').doc(userId));
      });

      print('✅ Datos de Firestore eliminados');

      // 3. Manejar chats de manera más eficiente
      await _deleteUserChats(userId);

      // 4. Eliminar cuenta de autenticación
      await user.delete();
      print('✅ Cuenta de autenticación eliminada');

      // 5. Cerrar sesión
      await _auth.signOut();
      print('🚪 Sesión cerrada');

    } catch (e) {
      print('❌ Error al eliminar cuenta: $e');
      throw Exception('Error al eliminar cuenta: $e');
    }
  }

  // Método auxiliar para eliminar chats
  Future<void> _deleteUserChats(String userId) async {
    try {
      final chatsQuery = await _firestore
          .collection('chats')
          .where('participants.$userId', isGreaterThan: '')
          .get();

      final batch = _firestore.batch();
      
      for (final chatDoc in chatsQuery.docs) {
        // Eliminar mensajes primero
        final messages = await chatDoc.reference.collection('messages').get();
        for (final messageDoc in messages.docs) {
          batch.delete(messageDoc.reference);
        }
        
        // Eliminar chat
        batch.delete(chatDoc.reference);
      }
      
      await batch.commit();
      print('🗑️ Eliminados ${chatsQuery.docs.length} chats');
    } catch (e) {
      print('⚠️ No se pudieron eliminar algunos chats: $e');
      // Continuar sin fallar la eliminación completa
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  bool isSuperAdmin(String userId) {
    return userId == 'XCs21m7R5aQuyfSwMw6F27s3zP13';
  }
}