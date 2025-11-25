import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/models/vehicle_model.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/screens/vehicle_detail_screen.dart';
import 'package:auto_market/screens/add_vehicle_screen.dart';
import 'package:auto_market/screens/profile_screen.dart';
import 'package:auto_market/screens/admin_screen.dart';
import 'package:auto_market/widgets/base64_image.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:photo_view/photo_view.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  int _currentIndex = 0;
  bool _isAdmin = false;
  String _selectedCategoryFilter = 'Todos';

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
    return Scaffold(
      appBar: AppBar(
        title: Text('AutoMarket', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          if (_isAdmin && _currentIndex == 0)
            IconButton(
              icon: Icon(Icons.admin_panel_settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AdminScreen()),
                );
              },
            ),
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list),
            onSelected: (category) {
              setState(() => _selectedCategoryFilter = category);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'Todos', child: Text('Todos los vehículos')),
              PopupMenuItem(value: 'Carro', child: Text('Carros')),
              PopupMenuItem(value: 'Motocicleta', child: Text('Motocicletas')),
              PopupMenuItem(value: 'Camioneta', child: Text('Camionetas')),
              PopupMenuItem(value: 'Camión', child: Text('Camiones')),
              PopupMenuItem(value: 'Furgoneta', child: Text('Furgonetas')),
              PopupMenuItem(value: 'Bus', child: Text('Buses')),
            ],
          ),
        ],
      ),
      body: _getCurrentScreen(),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Colors.orange[600],
        unselectedItemColor: Colors.blueGrey[600],
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Inicio'),
          BottomNavigationBarItem(icon: Icon(Icons.add), label: 'Publicar'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }

  Widget _getCurrentScreen() {
    switch (_currentIndex) {
      case 0:
        return _buildFeedScreen();
      case 1:
        return AddVehicleScreen();
      case 2:
        return ProfileScreen();
      default:
        return _buildFeedScreen();
    }
  }

  Widget _buildFeedScreen() {
    return StreamBuilder<List<Vehicle>>(
      stream: _firebaseService.getVehicles(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        var vehicles = snapshot.data ?? [];

        // Aplicar filtro de categoría
        if (_selectedCategoryFilter != 'Todos') {
          vehicles = vehicles.where((vehicle) => vehicle.category == _selectedCategoryFilter).toList();
        }

        if (vehicles.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.directions_car, size: 80, color: Colors.blueGrey[300]),
                SizedBox(height: 16),
                Text(
                  _selectedCategoryFilter == 'Todos' 
                    ? 'No hay vehículos publicados'
                    : 'No hay ${_selectedCategoryFilter.toLowerCase()}s publicados',
                  style: TextStyle(color: Colors.blueGrey[600], fontSize: 16),
                ),
                SizedBox(height: 8),
                Text(
                  'Sé el primero en publicar un vehículo',
                  style: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
                ),
              ],
            ),
          );
        }

        return Column(
          children: [
            // Mostrar filtro activo
            if (_selectedCategoryFilter != 'Todos')
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: Colors.orange[50],
                child: Row(
                  children: [
                    Icon(Icons.filter_alt, size: 16, color: Colors.orange),
                    SizedBox(width: 8),
                    Text(
                      'Filtrado: $_selectedCategoryFilter',
                      style: TextStyle(color: Colors.orange[800]),
                    ),
                    Spacer(),
                    TextButton(
                      onPressed: () {
                        setState(() => _selectedCategoryFilter = 'Todos');
                      },
                      child: Text('Limpiar', style: TextStyle(color: Colors.orange)),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  setState(() {});
                },
                child: ListView.builder(
                  padding: EdgeInsets.all(16),
                  itemCount: vehicles.length,
                  itemBuilder: (context, index) {
                    final vehicle = vehicles[index];
                    return _buildVehicleCard(vehicle);
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildVehicleCard(Vehicle vehicle) {
    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagen del vehículo CENTRADA Y CON ZOOM
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
                    // IMAGEN CENTRADA
                    vehicle.displayImages.isNotEmpty
                        ? Center(
                            child: Container(
                              constraints: BoxConstraints(
                                maxWidth: MediaQuery.of(context).size.width * 0.9,
                                maxHeight: 200,
                              ),
                              child: Base64Image(
                                base64String: vehicle.displayImages.first,
                                fit: BoxFit.contain, // CAMBIADO A CONTAIN PARA CENTRAR
                              ),
                            ),
                          )
                        : _buildPlaceholder(),
                    
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
            
            // Información del vehículo
            Padding(
              padding: EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NOMBRE COMPLETO DEL VEHÍCULO
                  Container(
                    width: double.infinity,
                    child: Text(
                      vehicle.brand,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(height: 6),
                  
                  // PRECIO DEBAJO DEL NOMBRE
                  Container(
                    width: double.infinity,
                    child: Text(
                      '\$${vehicle.minPrice.toStringAsFixed(0)} - \$${vehicle.maxPrice.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.orange[600],
                        height: 1.2,
                      ),
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Categoría y año - EN UNA SOLA LÍNEA
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
                                ? vehicle.category.substring(0, 8).toUpperCase()
                                : vehicle.category.toUpperCase(),
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        Text(
                          '${vehicle.vehicleYear} | ${vehicle.color}',
                          style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Especificaciones técnicas
                  Container(
                    width: double.infinity,
                    child: Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.settings, size: 14, color: Colors.blueGrey[600]),
                            SizedBox(width: 2),
                            Text(
                              vehicle.traction,
                              style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_gas_station, size: 14, color: Colors.blueGrey[600]),
                            SizedBox(width: 2),
                            Text(
                              vehicle.fuelType,
                              style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 8),
                  
                  // Ubicación y estado
                  Container(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Icon(Icons.location_on, size: 14, color: Colors.blueGrey[600]),
                        SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            vehicle.location,
                            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (vehicle.isSold)
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              'VENDIDO',
                              style: TextStyle(
                                color: Colors.red[800],
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 4),
                  
                  // Fecha de publicación
                  Container(
                    width: double.infinity,
                    child: Text(
                      'Publicado: ${_formatTime(vehicle.createdAt)}',
                      style: TextStyle(color: Colors.blueGrey[500], fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.directions_car, size: 60, color: Colors.blueGrey[400]),
          SizedBox(height: 8),
          Text(
            'Sin imagen',
            style: TextStyle(color: Colors.blueGrey[500]),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 7) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}