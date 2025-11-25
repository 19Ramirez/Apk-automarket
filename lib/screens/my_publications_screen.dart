import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/vehicle_model.dart';
import 'package:auto_market/widgets/base64_image.dart';
import 'package:auto_market/screens/add_vehicle_screen.dart';
import 'package:auto_market/screens/edit_vehicle_screen.dart';
import 'package:photo_view/photo_view.dart';

class MyPublicationsScreen extends StatefulWidget {
  @override
  _MyPublicationsScreenState createState() => _MyPublicationsScreenState();
}

class _MyPublicationsScreenState extends State<MyPublicationsScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;

  // Método para obtener color de categoría
  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Carro':
        return Colors.blue;
      case 'Motocicleta':
        return Colors.green;
      case 'Camioneta':
        return Colors.orange;
      case 'Camión':
        return Colors.red;
      case 'Furgoneta':
        return Colors.purple;
      case 'Bus':
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Eliminar publicación'),
        content: Text('¿Estás seguro de que quieres eliminar esta publicación?'),
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
      try {
        await _firebaseService.deleteVehicle(vehicleId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Publicación eliminada')),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al eliminar: $e')),
        );
      }
    }
  }

  Future<void> _markAsSold(Vehicle vehicle, bool isSold) async {
    try {
      // Crear una copia actualizada del vehículo
      final updatedVehicle = Vehicle(
        id: vehicle.id,
        userId: vehicle.userId,
        userEmail: vehicle.userEmail,
        imageUrls: vehicle.imageUrls,
        imageBase64: vehicle.imageBase64,
        brand: vehicle.brand,
        minPrice: vehicle.minPrice,
        maxPrice: vehicle.maxPrice,
        doors: vehicle.doors,
        color: vehicle.color,
        traction: vehicle.traction,
        location: vehicle.location,
        fuelType: vehicle.fuelType,
        sellerType: vehicle.sellerType,
        additionalInfo: vehicle.additionalInfo,
        createdAt: vehicle.createdAt,
        isSold: isSold, // ACTUALIZAR ESTADO
        isAvailable: vehicle.isAvailable,
        phoneNumber: vehicle.phoneNumber,
        vehicleYear: vehicle.vehicleYear,
        lastRegistrationYear: vehicle.lastRegistrationYear,
        category: vehicle.category,
        engineDisplacement: vehicle.engineDisplacement,
        dealershipName: vehicle.dealershipName,
      );

      await _firebaseService.updateVehicle(updatedVehicle);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isSold ? '✅ Marcado como vendido' : '🔄 Marcado como disponible')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar: $e')),
      );
    }
  }

  // FUNCIÓN ACTUALIZADA - Ahora navega a EditVehicleScreen
  void _editVehicle(Vehicle vehicle) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditVehicleScreen(vehicle: vehicle),
      ),
    );
  }

  // FUNCIÓN PARA ZOOM DE IMÁGENES
  void _showImageZoom(List<String> images, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Stack(
            children: [
              PageView.builder(
                itemCount: images.length,
                controller: PageController(initialPage: initialIndex),
                itemBuilder: (context, index) {
                  return PhotoView(
                    imageProvider: MemoryImage(
                      _getImageBytes(images[index]),
                    ),
                    backgroundDecoration: BoxDecoration(
                      color: Colors.black,
                    ),
                    minScale: PhotoViewComputedScale.contained,
                    maxScale: PhotoViewComputedScale.covered * 2,
                    initialScale: PhotoViewComputedScale.contained,
                    heroAttributes: PhotoViewHeroAttributes(tag: images[index]),
                  );
                },
              ),
              Positioned(
                top: 40,
                right: 20,
                child: IconButton(
                  icon: Icon(Icons.close, color: Colors.white, size: 30),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ),
              if (images.length > 1)
                Positioned(
                  bottom: 20,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${initialIndex + 1}/${images.length}',
                          style: TextStyle(color: Colors.white, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // FUNCIÓN PARA OBTENER BYTES DE IMAGEN BASE64
  Uint8List _getImageBytes(String base64String) {
    try {
      // Si es una URL de datos (data:image/jpeg;base64,...)
      if (base64String.startsWith('data:image')) {
        final base64Data = base64String.split(',').last;
        return base64.decode(base64Data);
      }
      // Si es base64 puro
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding image: $e');
      // Retornar una imagen de error en bytes
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Publicaciones'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => AddVehicleScreen()),
              );
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Vehicle>>(
        stream: _firebaseService.getUserVehicles(user?.uid ?? ''),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final vehicles = snapshot.data ?? [];

          if (vehicles.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_car, size: 80, color: Colors.blueGrey[300]),
                  SizedBox(height: 20),
                  Text(
                    'No tienes publicaciones',
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Publica tu primer vehículo',
                    style: TextStyle(color: Colors.blueGrey[400]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => AddVehicleScreen()),
                      );
                    },
                    child: Text('Publicar Vehículo'),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: vehicles.length,
            itemBuilder: (context, index) {
              final vehicle = vehicles[index];
              return Card(
                margin: EdgeInsets.only(bottom: 16),
                child: Column(
                  children: [
                    // Imagen con zoom
                    GestureDetector(
                      onTap: () {
                        if (vehicle.displayImages.isNotEmpty) {
                          _showImageZoom(vehicle.displayImages, 0);
                        }
                      },
                      child: Container(
                        height: 200,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                          color: Colors.blueGrey[100],
                        ),
                        child: Stack(
                          children: [
                            // Imagen principal
                            vehicle.displayImages.isNotEmpty
                                ? Base64Image(
                                    base64String: vehicle.displayImages.first,
                                    fit: BoxFit.cover,
                                  )
                                : Center(
                                    child: Icon(Icons.directions_car, size: 60, color: Colors.blueGrey[400]),
                                  ),
                            
                            // Indicador de múltiples imágenes
                            if (vehicle.displayImages.length > 1)
                              Positioned(
                                top: 8,
                                right: 8,
                                child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '+${vehicle.displayImages.length - 1}',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            
                            // Icono de zoom
                            Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.zoom_in,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    
                    // Información
                    Padding(
                      padding: EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // NOMBRE COMPLETO DEL VEHÍCULO
                          Container(
                            width: double.infinity,
                            child: Text(
                              vehicle.brand,
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(height: 4),
                          
                          // PRECIO DEBAJO DEL NOMBRE
                          Container(
                            width: double.infinity,
                            child: Text(
                              '\$${vehicle.minPrice.toStringAsFixed(0)} - \$${vehicle.maxPrice.toStringAsFixed(0)}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.orange[600],
                              ),
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Categoría y año
                          Container(
                            width: double.infinity,
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Container(
                                  padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: _getCategoryColor(vehicle.category),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    vehicle.category.length > 8 
                                        ? vehicle.category.substring(0, 8) 
                                        : vehicle.category,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  'Año: ${vehicle.vehicleYear} | ${vehicle.color}',
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Ubicación completa
                          Container(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Icon(Icons.location_on, size: 14, color: Colors.blueGrey[600]),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    vehicle.location,
                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 8),
                          
                          // Fecha y estado
                          Container(
                            width: double.infinity,
                            child: Row(
                              children: [
                                Icon(Icons.schedule, size: 14, color: Colors.blueGrey[600]),
                                SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Publicado: ${_formatTime(vehicle.createdAt)}',
                                    style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (vehicle.isSold)
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.red[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'VENDIDO',
                                      style: TextStyle(
                                        color: Colors.red[800],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green[100],
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      'DISPONIBLE',
                                      style: TextStyle(
                                        color: Colors.green[800],
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // BOTONES OPTIMIZADOS
                          Row(
                            children: [
                              // Botón Editar
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      side: BorderSide(color: Colors.blueGrey),
                                    ),
                                    onPressed: () => _editVehicle(vehicle),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.edit, size: 14, color: Colors.blueGrey),
                                        SizedBox(width: 4),
                                        Text(
                                          'Editar',
                                          style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              
                              // Botón Estado
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      side: BorderSide(color: vehicle.isSold ? Colors.orange : Colors.green),
                                    ),
                                    onPressed: () => _markAsSold(vehicle, !vehicle.isSold),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          vehicle.isSold ? Icons.inventory : Icons.sell, 
                                          size: 14, 
                                          color: vehicle.isSold ? Colors.orange : Colors.green
                                        ),
                                        SizedBox(width: 4),
                                        Text(
                                          vehicle.isSold ? 'Stock' : 'Vender',
                                          style: TextStyle(
                                            fontSize: 12, 
                                            color: vehicle.isSold ? Colors.orange : Colors.green
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 6),
                              
                              // Botón Eliminar
                              Expanded(
                                child: SizedBox(
                                  height: 36,
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      padding: EdgeInsets.symmetric(horizontal: 4),
                                      side: BorderSide(color: Colors.red),
                                    ),
                                    onPressed: () => _deleteVehicle(vehicle.id!),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.delete, size: 14, color: Colors.red),
                                        SizedBox(width: 4),
                                        Text(
                                          'Borrar',
                                          style: TextStyle(fontSize: 12, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays < 1) {
      return 'Hoy';
    } else if (difference.inDays < 30) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}