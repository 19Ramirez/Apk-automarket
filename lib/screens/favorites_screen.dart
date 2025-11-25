import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/vehicle_model.dart';
import 'package:auto_market/models/user_model.dart'; 
import 'package:auto_market/widgets/base64_image.dart';
import 'package:auto_market/screens/vehicle_detail_screen.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:photo_view/photo_view.dart';

class FavoritesScreen extends StatefulWidget {
  @override
  _FavoritesScreenState createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;
  List<Vehicle> _favoriteVehicles = [];

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
                onPageChanged: (index) {
                  setState(() {
                    initialIndex = index;
                  });
                },
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
      if (base64String.startsWith('data:image')) {
        final base64Data = base64String.split(',').last;
        return base64.decode(base64Data);
      }
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding image: $e');
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: Text('Mis Favoritos'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: StreamBuilder<UserModel?>(
        stream: user != null ? _firebaseService.getUser(user.uid) : null,
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          final userData = userSnapshot.data;
          final favorites = userData?.favorites ?? [];

          if (favorites.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 80, color: Colors.blueGrey[300]),
                  SizedBox(height: 20),
                  Text(
                    'No tienes favoritos',
                    style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Agrega vehículos a tus favoritos\npara verlos aquí',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey[400]),
                  ),
                  SizedBox(height: 20),
                  ElevatedButton.icon(
                    icon: Icon(Icons.explore),
                    label: Text('Explorar Vehículos'),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            );
          }

          return StreamBuilder<List<Vehicle>>(
            stream: _firebaseService.getVehicles(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              final allVehicles = snapshot.data ?? [];
              final favoriteVehicles = allVehicles.where((vehicle) => 
                  favorites.contains(vehicle.id)).toList();

              if (favoriteVehicles.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border, size: 80, color: Colors.blueGrey[300]),
                      SizedBox(height: 20),
                      Text(
                        'No hay vehículos favoritos',
                        style: TextStyle(fontSize: 18, color: Colors.blueGrey[600]),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.all(16),
                itemCount: favoriteVehicles.length,
                itemBuilder: (context, index) {
                  final vehicle = favoriteVehicles[index];
                  return _buildFavoriteCard(vehicle, userData!);
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildFavoriteCard(Vehicle vehicle, UserModel user) {
    return Card(
      margin: EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => VehicleDetailScreen(vehicle: vehicle),
            ),
          );
        },
        child: Column(
          children: [
            // Imagen CON ZOOM
            GestureDetector(
              onTap: () {
                if (vehicle.displayImages.isNotEmpty) {
                  _showImageZoom(vehicle.displayImages, 0);
                }
              },
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                  color: Colors.blueGrey[100],
                ),
                child: Stack(
                  children: [
                    vehicle.displayImages.isNotEmpty
                        ? Base64Image(
                            base64String: vehicle.displayImages.first,
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(Icons.directions_car, size: 50, color: Colors.blueGrey[400]),
                          ),
                    
                    // Icono de zoom
                    if (vehicle.displayImages.isNotEmpty)
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
              padding: EdgeInsets.all(12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          vehicle.brand,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '\$${vehicle.minPrice.toStringAsFixed(0)} - \$${vehicle.maxPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.orange[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '${vehicle.category} | ${vehicle.vehicleYear}',
                          style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () => _removeFromFavorites(vehicle.id!, user),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeFromFavorites(String vehicleId, UserModel user) async {
    try {
      final updatedFavorites = List<String>.from(user.favorites)..remove(vehicleId);
      final updatedUser = UserModel(
        id: user.id,
        email: user.email,
        name: user.name,
        phone: user.phone,
        createdAt: user.createdAt,
        favorites: updatedFavorites,
        publicationsCount: user.publicationsCount,
      );
      
      await _firebaseService.saveUser(updatedUser);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Eliminado de favoritos')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar de favoritos: $e')),
      );
    }
  }
}