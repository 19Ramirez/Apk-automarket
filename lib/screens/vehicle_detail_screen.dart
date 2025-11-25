import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/models/vehicle_model.dart';
import 'package:auto_market/widgets/base64_image.dart';
import 'package:auto_market/screens/chat_screen.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/user_model.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:photo_view/photo_view.dart';

class VehicleDetailScreen extends StatefulWidget {
  final Vehicle vehicle;

  const VehicleDetailScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  _VehicleDetailScreenState createState() => _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends State<VehicleDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;
  bool _isFavorite = false;
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    final user = _auth.currentUser;
    if (user != null) {
      final userData = await _firebaseService.getUser(user.uid).first;
      if (userData != null && widget.vehicle.id != null) {
        setState(() {
          _isFavorite = userData.favorites.contains(widget.vehicle.id);
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null) return;

    final userSnapshot = await _firebaseService.getUser(user.uid).first;
    
    if (userSnapshot != null && widget.vehicle.id != null) {
      final isFavorite = userSnapshot.favorites.contains(widget.vehicle.id);
      final updatedFavorites = List<String>.from(userSnapshot.favorites);
      
      if (isFavorite) {
        updatedFavorites.remove(widget.vehicle.id!);
      } else {
        updatedFavorites.add(widget.vehicle.id!);
      }
      
      final updatedUser = UserModel(
        id: userSnapshot.id,
        email: userSnapshot.email,
        name: userSnapshot.name,
        phone: userSnapshot.phone,
        createdAt: userSnapshot.createdAt,
        favorites: updatedFavorites,
        publicationsCount: userSnapshot.publicationsCount,
      );
      
      await _firebaseService.saveUser(updatedUser);
      
      setState(() {
        _isFavorite = !isFavorite;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isFavorite ? 'Eliminado de favoritos' : 'Agregado a favoritos')),
      );
    }
  }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se puede realizar la llamada')),
      );
    }
  }

  void _shareVehicle() {
    // Implementación básica de compartir
    final shareText = 'Mira este vehículo: ${widget.vehicle.brand} - \$${widget.vehicle.minPrice.toStringAsFixed(0)}';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Función de compartir: $shareText')),
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
      body: CustomScrollView(
        slivers: [
          // AppBar con imágenes
          SliverAppBar(
            expandedHeight: 300,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                children: [
                  // Carrusel de imágenes CON ZOOM
                  widget.vehicle.displayImages.isNotEmpty
                      ? PageView.builder(
                          itemCount: widget.vehicle.displayImages.length,
                          onPageChanged: (index) {
                            setState(() {
                              _currentImageIndex = index;
                            });
                          },
                          itemBuilder: (context, index) {
                            return GestureDetector(
                              onTap: () {
                                _showImageZoom(widget.vehicle.displayImages, index);
                              },
                              child: Base64Image(
                                base64String: widget.vehicle.displayImages[index],
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        )
                      : Container(
                          color: Colors.blueGrey[100],
                          child: Center(
                            child: Icon(Icons.directions_car, size: 80, color: Colors.blueGrey[400]),
                          ),
                        ),
                  
                  // Indicador de imágenes
                  if (widget.vehicle.displayImages.length > 1)
                    Positioned(
                      bottom: 16,
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
                              '${_currentImageIndex + 1}/${widget.vehicle.displayImages.length}',
                              style: TextStyle(color: Colors.white, fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.share, color: Colors.white),
                onPressed: _shareVehicle,
              ),
              IconButton(
                icon: Icon(
                  _isFavorite ? Icons.favorite : Icons.favorite_border,
                  color: _isFavorite ? Colors.red : Colors.white,
                ),
                onPressed: _toggleFavorite,
              ),
            ],
          ),

          // Información del vehículo
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Precio y marca - MEJORADO
                  Container(
                    width: double.infinity,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.vehicle.brand,
                          style: TextStyle(
                            fontSize: 24, 
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 8),
                        Text(
                          '\$${widget.vehicle.minPrice.toStringAsFixed(0)} - \$${widget.vehicle.maxPrice.toStringAsFixed(0)}',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12),
                  
                  // Categoría y estado
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(widget.vehicle.category),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          widget.vehicle.category.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (widget.vehicle.isSold)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red[100],
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'VENDIDO',
                            style: TextStyle(
                              color: Colors.red[800],
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16),

                  // Especificaciones
                  _buildSpecsGrid(),
                  SizedBox(height: 24),

                  // Descripción
                  if (widget.vehicle.additionalInfo.isNotEmpty) ...[
                    Text(
                      'Descripción',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blueGrey[50],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.vehicle.additionalInfo,
                        style: TextStyle(fontSize: 16, color: Colors.blueGrey[700]),
                      ),
                    ),
                    SizedBox(height: 24),
                  ],

                  // Información del vendedor
                  _buildSellerInfo(),
                  SizedBox(height: 24),

                  // Botones de contacto - SIN SMS
                  _buildContactButtons(),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpecsGrid() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Primera fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpecItem('Categoría', widget.vehicle.category, Icons.category),
              _buildSpecItem('Año', '${widget.vehicle.vehicleYear}', Icons.calendar_today),
            ],
          ),
          SizedBox(height: 16),
          
          // Segunda fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpecItem('Matriculación', '${widget.vehicle.lastRegistrationYear}', Icons.date_range),
              if (widget.vehicle.category != 'Motocicleta')
                _buildSpecItem('Puertas', '${widget.vehicle.doors}', Icons.door_back_door),
              if (widget.vehicle.category == 'Motocicleta')
                _buildSpecItem('Tipo', 'Motocicleta', Icons.two_wheeler),
            ],
          ),
          SizedBox(height: 16),
          
          // Tercera fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              if (widget.vehicle.engineDisplacement != null && widget.vehicle.engineDisplacement!.isNotEmpty)
                _buildSpecItem('Cilindraje', '${widget.vehicle.engineDisplacement} cc', Icons.speed),
              if (widget.vehicle.engineDisplacement == null || widget.vehicle.engineDisplacement!.isEmpty)
                _buildSpecItem('Color', widget.vehicle.color, Icons.color_lens),
              if (widget.vehicle.category != 'Motocicleta')
                _buildSpecItem('Tracción', widget.vehicle.traction, Icons.settings),
              if (widget.vehicle.category == 'Motocicleta')
                _buildSpecItem('Color', widget.vehicle.color, Icons.color_lens),
            ],
          ),
          SizedBox(height: 16),
          
          // Cuarta fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpecItem('Combustible', widget.vehicle.fuelType, Icons.local_gas_station),
              _buildSpecItem('Vendedor', widget.vehicle.sellerType, Icons.business),
            ],
          ),
          SizedBox(height: 16),
          
          // Quinta fila
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSpecItem('Estado', widget.vehicle.isSold ? 'Vendido' : 'Disponible', 
                  widget.vehicle.isSold ? Icons.sell : Icons.assignment_turned_in),
              _buildSpecItem('Ubicación', _shortenLocation(widget.vehicle.location), Icons.location_on),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecItem(String label, String value, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 24, color: Colors.blueGrey[600]),
          SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: Colors.blueGrey[600]),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              value,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSellerInfo() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blueGrey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Información del Vendedor',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 12),
          Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.blueGrey[800],
                child: Text(
                  widget.vehicle.userEmail[0].toUpperCase(),
                  style: TextStyle(color: Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.vehicle.userEmail,
                      style: TextStyle(fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.vehicle.sellerType,
                      style: TextStyle(color: Colors.blueGrey[600]),
                    ),
                    if (widget.vehicle.dealershipName != null && widget.vehicle.dealershipName!.isNotEmpty)
                      Text(
                        'Concesionaria: ${widget.vehicle.dealershipName}',
                        style: TextStyle(color: Colors.blueGrey[700], fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Container(
            width: double.infinity,
            child: Row(
              children: [
                Icon(Icons.location_on, size: 16, color: Colors.blueGrey[600]),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.vehicle.location,
                    style: TextStyle(color: Colors.blueGrey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.schedule, size: 16, color: Colors.blueGrey[600]),
              SizedBox(width: 8),
              Text(
                'Publicado ${_formatTime(widget.vehicle.createdAt)}',
                style: TextStyle(color: Colors.blueGrey[700]),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContactButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.message),
                label: Text('Mensaje'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey[800],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChatScreen(
                        sellerId: widget.vehicle.userId,
                        sellerEmail: widget.vehicle.userEmail,
                      ),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ElevatedButton.icon(
                icon: Icon(Icons.phone),
                label: Text('Llamar'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[600],
                  padding: EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: widget.vehicle.phoneNumber != null 
                    ? () => _makePhoneCall(widget.vehicle.phoneNumber!)
                    : null,
              ),
            ),
          ],
        ),
        if (widget.vehicle.phoneNumber == null) ...[
          SizedBox(height: 8),
          Text(
            'Teléfono no disponible',
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
          ),
        ],
      ],
    );
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

  String _shortenLocation(String location) {
    if (location.length > 15) {
      return location.substring(0, 15) + '...';
    }
    return location;
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inMinutes < 60) {
      return 'Hace ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Hace ${difference.inHours} h';
    } else if (difference.inDays < 30) {
      return 'Hace ${difference.inDays} días';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}