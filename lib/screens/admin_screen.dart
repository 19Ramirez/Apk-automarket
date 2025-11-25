import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/models/vehicle_model.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;
  
  Map<String, dynamic> _stats = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final stats = await _firebaseService.getAdminStats();
      setState(() {
        _stats = stats;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading admin data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteVehicle(String vehicleId) async {
    try {
      await _firebaseService.deleteVehicle(vehicleId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehículo eliminado')),
      );
      _loadData(); // Recargar datos
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al eliminar vehículo: $e')),
      );
    }
  }

  void _showVehicleDetails(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles del Vehículo'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Marca: ${vehicle.brand}'),
              Text('Categoría: ${vehicle.category}'),
              Text('Precio: \$${vehicle.minPrice} - \$${vehicle.maxPrice}'),
              Text('Año: ${vehicle.vehicleYear}'),
              Text('Matriculación: ${vehicle.lastRegistrationYear}'),
              Text('Color: ${vehicle.color}'),
              Text('Puertas: ${vehicle.doors}'),
              Text('Tracción: ${vehicle.traction}'),
              Text('Combustible: ${vehicle.fuelType}'),
              Text('Vendedor: ${vehicle.userEmail}'),
              Text('Tipo Vendedor: ${vehicle.sellerType}'),
              Text('Teléfono: ${vehicle.phoneNumber ?? "No proporcionado"}'),
              Text('Ubicación: ${vehicle.location}'),
              Text('Publicado: ${_formatDate(vehicle.createdAt)}'),
              Text('Estado: ${vehicle.isSold ? 'Vendido' : 'Disponible'}'),
              if (vehicle.additionalInfo.isNotEmpty)
                Text('Descripción: ${vehicle.additionalInfo}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cerrar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteVehicle(vehicle.id!);
            },
            child: Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Panel de Administración'),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _loadData,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : StreamBuilder<List<Vehicle>>(
              stream: _firebaseService.getVehicles(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }

                final vehicles = snapshot.data ?? [];
                final activeVehicles = vehicles.where((v) => !v.isSold).length;
                final soldVehicles = vehicles.where((v) => v.isSold).length;

                return Column(
                  children: [
                    // Estadísticas
                    Card(
                      margin: EdgeInsets.all(16),
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _buildStatItem('Usuarios', _stats['totalUsers']?.toString() ?? '0'),
                            _buildStatItem('Vehículos', _stats['totalVehicles']?.toString() ?? '0'),
                            _buildStatItem('Activos', activeVehicles.toString()),
                            _buildStatItem('Vendidos', soldVehicles.toString()),
                          ],
                        ),
                      ),
                    ),

                    // Lista de vehículos
                    Expanded(
                      child: ListView.builder(
                        padding: EdgeInsets.all(16),
                        itemCount: vehicles.length,
                        itemBuilder: (context, index) {
                          final vehicle = vehicles[index];
                          return Card(
                            margin: EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Colors.blueGrey[100],
                                child: Icon(Icons.directions_car, color: Colors.blueGrey[600]),
                              ),
                              title: Text(vehicle.brand),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('\$${vehicle.minPrice} - \$${vehicle.maxPrice}'),
                                  Text('${vehicle.category} | Por: ${vehicle.userEmail}'),
                                  Text(_formatDate(vehicle.createdAt)),
                                ],
                              ),
                              trailing: vehicle.isSold 
                                  ? Chip(
                                      label: Text('VENDIDO', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      backgroundColor: Colors.red,
                                    )
                                  : Chip(
                                      label: Text('DISPONIBLE', style: TextStyle(color: Colors.white, fontSize: 10)),
                                      backgroundColor: Colors.green,
                                    ),
                              onTap: () => _showVehicleDetails(vehicle),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Widget _buildStatItem(String title, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange[600]),
        ),
        Text(title, style: TextStyle(color: Colors.blueGrey[600], fontSize: 12)),
      ],
    );
  }
}