import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/vehicle_model.dart';
import '../models/user_model.dart';

class FirebaseService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? getCurrentUser() {
    return _auth.currentUser;
  }

  Future<void> saveVehicle(Vehicle vehicle) async {
    try {
      if (vehicle.id == null) {
        final docRef = _firestore.collection('vehicles').doc();
        vehicle.id = docRef.id;
      }
      await _firestore.collection('vehicles').doc(vehicle.id).set(vehicle.toMap());
    } catch (e) {
      throw Exception('Error al guardar vehículo: $e');
    }
  }

  Stream<List<Vehicle>> getVehicles() {
    return _firestore
        .collection('vehicles')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vehicle.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<void> saveUser(UserModel user) async {
    try {
      await _firestore.collection('users').doc(user.id).set(user.toMap());
    } catch (e) {
      throw Exception('Error al guardar usuario: $e');
    }
  }

  Stream<UserModel?> getUser(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists) return null;
      return UserModel.fromMap(userId, snapshot.data() as Map<String, dynamic>);
    });
  }

  Future<void> deleteVehicle(String vehicleId) async {
    try {
      await _firestore.collection('vehicles').doc(vehicleId).delete();
    } catch (e) {
      throw Exception('Error al eliminar vehículo: $e');
    }
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    try {
      await _firestore.collection('vehicles').doc(vehicle.id).update(vehicle.toMap());
    } catch (e) {
      throw Exception('Error al actualizar vehículo: $e');
    }
  }

  Future<Map<String, dynamic>> getAdminStats() async {
    try {
      final usersCount = (await _firestore.collection('users').get()).size;
      final vehiclesCount = (await _firestore.collection('vehicles').get()).size;
      
      return {
        'totalUsers': usersCount,
        'totalVehicles': vehiclesCount,
      };
    } catch (e) {
      throw Exception('Error al obtener estadísticas: $e');
    }
  }

  Stream<List<Vehicle>> getUserVehicles(String userId) {
    return _firestore
        .collection('vehicles')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vehicle.fromMap(doc.id, doc.data() as Map<String, dynamic>);
      }).toList();
    });
  }

  Future<bool> isUserAdmin(String userId) async {
    const adminUids = [
      'XCs21m7R5aQuyfSwMw6F27s3zP13',
    ];
    
    if (adminUids.contains(userId)) {
      return true;
    }
    
    try {
      final doc = await _firestore.collection('admins').doc(userId).get();
      return doc.exists && doc.data()?['isAdmin'] == true;
    } catch (e) {
      print('Error checking admin status: $e');
      return false;
    }
  }

  Future<void> addAdmin(String userId) async {
    try {
      await _firestore.collection('admins').doc(userId).set({
        'isAdmin': true,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Error al agregar administrador: $e');
    }
  }

  Stream<Map<String, dynamic>> getAdminsStream() {
    return _firestore.collection('admins').snapshots().map((snapshot) {
      final admins = <String, dynamic>{};
      for (final doc in snapshot.docs) {
        admins[doc.id] = doc.data();
      }
      return admins;
    });
  }

  bool isSuperAdmin(String userId) {
    return userId == 'XCs21m7R5aQuyfSwMw6F27s3zP13';
  }

  // MÉTODO CORREGIDO: Eliminar cuenta de usuario
  Future<void> deleteUserAccount() async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Usuario no autenticado');

      final userId = user.uid;
      final batch = _firestore.batch();

      print('🔄 Iniciando eliminación de cuenta para usuario: $userId');

      // 1. Eliminar todos los vehículos del usuario (CONSULTA SEGURA)
      try {
        final userVehicles = await _firestore
            .collection('vehicles')
            .where('userId', isEqualTo: userId)
            .get();

        print('📦 Encontrados ${userVehicles.docs.length} vehículos para eliminar');

        for (final doc in userVehicles.docs) {
          batch.delete(doc.reference);
        }
      } catch (e) {
        print('⚠️ Error al obtener vehículos: $e');
        // Continuar con la eliminación aunque falle una parte
      }

      // 2. Eliminar datos del usuario
      batch.delete(_firestore.collection('users').doc(userId));
      print('👤 Datos de usuario marcados para eliminación');

      // 3. Buscar y eliminar chats del usuario (MANERA SEGURA)
      try {
        // Obtener todos los chats y filtrar localmente
        final allChats = await _firestore.collection('chats').get();
        
        int chatsToDelete = 0;
        for (final doc in allChats.docs) {
          final chatData = doc.data();
          final participants = chatData['participants'] as Map<String, dynamic>?;
          
          if (participants != null && participants.containsKey(userId)) {
            batch.delete(doc.reference);
            chatsToDelete++;
            
            // Intentar eliminar mensajes (pero no fallar si no tiene permisos)
            try {
              final messages = await doc.reference.collection('messages').get();
              for (final messageDoc in messages.docs) {
                batch.delete(messageDoc.reference);
              }
              print('💬 Eliminados ${messages.docs.length} mensajes del chat ${doc.id}');
            } catch (e) {
              print('⚠️ No se pudieron eliminar mensajes del chat ${doc.id}: $e');
              // Continuar sin los mensajes
            }
          }
        }
        print('🗑️ Encontrados $chatsToDelete chats para eliminar');
      } catch (e) {
        print('⚠️ Error al procesar chats: $e');
        // Continuar sin eliminar chats
      }

      // 4. Ejecutar todas las eliminaciones en lote
      print('⚡ Ejecutando operaciones en lote...');
      await batch.commit();
      print('✅ Operaciones en lote completadas');

      // 5. Eliminar cuenta de autenticación
      print('🔐 Eliminando cuenta de autenticación...');
      await user.delete();
      print('✅ Cuenta de autenticación eliminada');

      // 6. Cerrar sesión
      await _auth.signOut();
      print('🚪 Sesión cerrada');

    } catch (e) {
      print('❌ Error detallado al eliminar cuenta: $e');
      throw Exception('Error al eliminar cuenta: $e');
    }
  }

  // Método auxiliar para cerrar sesión
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Método para obtener el ID del usuario actual
  String? getCurrentUserId() {
    return _auth.currentUser?.uid;
  }

  // Método para verificar si el usuario está autenticado
  bool isUserLoggedIn() {
    return _auth.currentUser != null;
  }
}