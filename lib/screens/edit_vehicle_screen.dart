import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:auto_market/models/vehicle_model.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/services/image_upload_service.dart';
import 'package:auto_market/widgets/base64_image.dart';

class EditVehicleScreen extends StatefulWidget {
  final Vehicle vehicle;

  const EditVehicleScreen({Key? key, required this.vehicle}) : super(key: key);

  @override
  _EditVehicleScreenState createState() => _EditVehicleScreenState();
}

class _EditVehicleScreenState extends State<EditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();
  final FirebaseService _firebaseService = FirebaseService();
  final _auth = FirebaseAuth.instance;

  // Controladores
  final _brandController = TextEditingController();
  final _minPriceController = TextEditingController();
  final _maxPriceController = TextEditingController();
  final _doorsController = TextEditingController();
  final _colorController = TextEditingController();
  final _locationController = TextEditingController();
  final _additionalInfoController = TextEditingController();
  final _phoneController = TextEditingController();
  final _vehicleYearController = TextEditingController();
  final _lastRegistrationYearController = TextEditingController();
  final _engineDisplacementController = TextEditingController();
  final _dealershipNameController = TextEditingController();

  // Variables del formulario
  List<File> _selectedImages = [];
  List<String> _existingImages = [];
  String _selectedTraction = '4x2';
  String _selectedFuelType = 'Gasolina';
  String _selectedSellerType = 'Directo';
  String _selectedCategory = 'Carro';
  bool _isLoading = false;
  bool _isSold = false;

  // Listas de opciones
  final List<String> _categoryOptions = [
    'Carro', 'Motocicleta', 'Camioneta', 'Camión', 'Furgoneta', 'Bus', 'Otro'
  ];
  final List<String> _tractionOptions = ['4x2', '4x4'];
  final List<String> _fuelOptions = ['Gasolina', 'Híbrido', 'Eléctrico', 'Diesel', 'Gas'];
  final List<String> _sellerOptions = ['Directo', 'Concesionaria'];

  @override
  void initState() {
    super.initState();
    _loadVehicleData();
  }

  void _loadVehicleData() {
    final vehicle = widget.vehicle;
    setState(() {
      _brandController.text = vehicle.brand;
      _minPriceController.text = vehicle.minPrice.toString();
      _maxPriceController.text = vehicle.maxPrice.toString();
      _doorsController.text = vehicle.doors.toString();
      _colorController.text = vehicle.color;
      _locationController.text = vehicle.location;
      _additionalInfoController.text = vehicle.additionalInfo;
      _phoneController.text = vehicle.phoneNumber ?? '';
      _vehicleYearController.text = vehicle.vehicleYear.toString();
      _lastRegistrationYearController.text = vehicle.lastRegistrationYear.toString();
      _engineDisplacementController.text = vehicle.engineDisplacement ?? '';
      _dealershipNameController.text = vehicle.dealershipName ?? '';
      _selectedTraction = vehicle.traction;
      _selectedFuelType = vehicle.fuelType;
      _selectedSellerType = vehicle.sellerType;
      _selectedCategory = vehicle.category;
      _isSold = vehicle.isSold;
      _existingImages = vehicle.displayImages;
    });
  }

  Future<void> _pickImages() async {
    try {
      final List<XFile>? pickedFiles = await ImagePicker().pickMultiImage(
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 80,
      );
      
      if (pickedFiles != null) {
        setState(() {
          _selectedImages.addAll(pickedFiles.map((xfile) => File(xfile.path)).toList());
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al seleccionar imágenes: $e')),
      );
    }
  }

  // MÉTODO PARA VERIFICAR SI DEBE MOSTRAR CAMPOS DE MOTOCICLETA
  bool get _showMotorcycleFields {
    return _selectedCategory == 'Motocicleta';
  }

  // MÉTODO PARA VERIFICAR SI DEBE MOSTRAR CAMPO DE CONCESIONARIA
  bool get _showDealershipField {
    return _selectedSellerType == 'Concesionaria';
  }

  Future<void> _updateVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser!;
      List<String> base64Images = [];
      List<String> dataUrls = [];

      // Procesar nuevas imágenes si las hay
      if (_selectedImages.isNotEmpty) {
        base64Images = await ImageUploadService.convertMultipleImagesToBase64(
          _selectedImages,
          maxWidth: 800,
          quality: 75,
        );
        dataUrls = base64Images.map((base64) => 'data:image/jpeg;base64,$base64').toList();
      }

      // Para motocicletas, establecer valores por defecto para campos no aplicables
      int doors = _showMotorcycleFields ? 0 : int.parse(_doorsController.text);
      String traction = _showMotorcycleFields ? 'No aplica' : _selectedTraction;

      // Crear vehículo actualizado
      final updatedVehicle = Vehicle(
        id: widget.vehicle.id,
        userId: user.uid,
        userEmail: user.email!,
        imageUrls: dataUrls.isNotEmpty ? dataUrls : _existingImages,
        imageBase64: base64Images.isNotEmpty ? base64Images : widget.vehicle.imageBase64,
        brand: _brandController.text,
        minPrice: double.parse(_minPriceController.text),
        maxPrice: double.parse(_maxPriceController.text),
        doors: doors,
        color: _colorController.text,
        traction: traction,
        location: _locationController.text,
        fuelType: _selectedFuelType,
        sellerType: _selectedSellerType,
        additionalInfo: _additionalInfoController.text,
        createdAt: widget.vehicle.createdAt,
        isSold: _isSold,
        isAvailable: !_isSold,
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        vehicleYear: int.parse(_vehicleYearController.text),
        lastRegistrationYear: int.parse(_lastRegistrationYearController.text),
        category: _selectedCategory,
        engineDisplacement: _engineDisplacementController.text.isEmpty ? null : _engineDisplacementController.text,
        dealershipName: _showDealershipField ? _dealershipNameController.text : null,
      );

      await _firebaseService.updateVehicle(updatedVehicle);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehículo actualizado exitosamente! ✅')),
      );
      
      Navigator.pop(context);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al actualizar vehículo: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _removeExistingImage(int index) {
    setState(() {
      _existingImages.removeAt(index);
    });
  }

  void _removeNewImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Editar Vehículo',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blueGrey[900],
        actions: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _isSold ? Colors.red[100] : Colors.green[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _isSold ? 'VENDIDO' : 'STOCK',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: _isSold ? Colors.red[800] : Colors.green[800],
                  ),
                ),
                SizedBox(width: 4),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _isSold = !_isSold;
                    });
                  },
                  child: Icon(
                    _isSold ? Icons.check_circle : Icons.inventory,
                    size: 16,
                    color: _isSold ? Colors.red[800] : Colors.green[800],
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de estado vendido/stock
              Card(
                color: _isSold ? Colors.red[50] : Colors.green[50],
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Icon(
                        _isSold ? Icons.sell : Icons.inventory,
                        color: _isSold ? Colors.red : Colors.green,
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _isSold ? 'Este vehículo está marcado como VENDIDO' : 'Este vehículo está en STOCK',
                          style: TextStyle(
                            color: _isSold ? Colors.red[800] : Colors.green[800],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      Switch(
                        value: _isSold,
                        onChanged: (value) {
                          setState(() {
                            _isSold = value;
                          });
                        },
                        activeColor: Colors.red,
                        inactiveThumbColor: Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              // Sección de imágenes
              _buildImageSection(),
              SizedBox(height: 24),
              
              // Información básica
              _buildTextField(_brandController, 'Marca del vehículo*', Icons.directions_car),
              SizedBox(height: 16),
              
              // CILINDRAJE - NUEVO CAMPO
              _buildTextField(
                _engineDisplacementController, 
                'Cilindraje (cc)', 
                Icons.speed,
                required: false,
                hintText: 'Ej: 150, 1000, 2000'
              ),
              SizedBox(height: 16),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(_minPriceController, 'Precio mínimo*', Icons.attach_money,
                      keyboardType: TextInputType.number),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: _buildTextField(_maxPriceController, 'Precio máximo*', Icons.attach_money,
                      keyboardType: TextInputType.number),
                  ),
                ],
              ),
              SizedBox(height: 16),
              
              // NÚMERO DE PUERTAS - SOLO SI NO ES MOTOCICLETA
              if (!_showMotorcycleFields)
                _buildTextField(_doorsController, 'Número de puertas*', Icons.door_back_door,
                  keyboardType: TextInputType.number),
              if (!_showMotorcycleFields) SizedBox(height: 16),
              
              _buildTextField(_colorController, 'Color*', Icons.color_lens),
              SizedBox(height: 16),
              
              _buildTextField(_vehicleYearController, 'Año del vehículo*', Icons.calendar_today,
                keyboardType: TextInputType.number),
              SizedBox(height: 16),
              
              _buildTextField(_lastRegistrationYearController, 'Último año de matriculación*', Icons.calendar_today,
                keyboardType: TextInputType.number),
              SizedBox(height: 16),
              
              // Dropdowns
              _buildDropdown('Categoría del vehículo*', _selectedCategory, _categoryOptions, (value) {
                setState(() => _selectedCategory = value!);
              }),
              SizedBox(height: 16),
              
              // TRACCIÓN - SOLO SI NO ES MOTOCICLETA
              if (!_showMotorcycleFields)
                _buildDropdown('Tracción', _selectedTraction, _tractionOptions, (value) {
                  setState(() => _selectedTraction = value!);
                }),
              if (!_showMotorcycleFields) SizedBox(height: 16),
              
              _buildDropdown('Tipo de combustible', _selectedFuelType, _fuelOptions, (value) {
                setState(() => _selectedFuelType = value!);
              }),
              SizedBox(height: 16),
              
              _buildDropdown('Tipo de vendedor', _selectedSellerType, _sellerOptions, (value) {
                setState(() => _selectedSellerType = value!);
              }),
              SizedBox(height: 16),
              
              // NOMBRE DE CONCESIONARIA - SOLO SI ES CONCESIONARIA
              if (_showDealershipField)
                _buildTextField(_dealershipNameController, 'Nombre de la concesionaria*', Icons.business),
              if (_showDealershipField) SizedBox(height: 16),
              
              _buildTextField(_locationController, 'Dirección/Ubicación*', Icons.location_on),
              SizedBox(height: 16),
              
              _buildTextField(_phoneController, 'Teléfono de contacto', Icons.phone,
                keyboardType: TextInputType.phone, required: false),
              SizedBox(height: 16),
              
              _buildTextArea(_additionalInfoController, 'Información adicional'),
              SizedBox(height: 32),
              
              // Botón de actualizar
              _isLoading 
                  ? Center(child: CircularProgressIndicator())
                  : ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange[600],
                        padding: EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _updateVehicle,
                      child: Text(
                        'ACTUALIZAR VEHÍCULO',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Imágenes del vehículo',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
        ),
        SizedBox(height: 8),
        
        // Imágenes existentes
        if (_existingImages.isNotEmpty) ...[
          Text(
            'Imágenes actuales (toca para eliminar)',
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
          ),
          SizedBox(height: 12),
          Container(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _existingImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageUrl = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blueGrey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Base64Image(
                          base64String: imageUrl,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.close, size: 12, color: Colors.white),
                          onPressed: () => _removeExistingImage(index),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
          SizedBox(height: 16),
        ],
        
        // Botón para agregar nuevas imágenes
        InkWell(
          onTap: _pickImages,
          child: Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.blueGrey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.blueGrey[50],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate, size: 30, color: Colors.blueGrey[400]),
                SizedBox(height: 4),
                Text('Agregar nuevas imágenes', style: TextStyle(color: Colors.blueGrey[600], fontSize: 12)),
              ],
            ),
          ),
        ),
        
        // Nuevas imágenes seleccionadas
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 12),
          Text(
            'Nuevas imágenes:',
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
          ),
          SizedBox(height: 8),
          Container(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _selectedImages.asMap().entries.map((entry) {
                final index = entry.key;
                final imageFile = entry.value;
                return Stack(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      margin: EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.blueGrey[100],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          imageFile,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: CircleAvatar(
                        radius: 12,
                        backgroundColor: Colors.red,
                        child: IconButton(
                          padding: EdgeInsets.zero,
                          icon: Icon(Icons.close, size: 12, color: Colors.white),
                          onPressed: () => _removeNewImage(index),
                        ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool required = true,
    String? hintText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        prefixIcon: Icon(icon, color: Colors.blueGrey[600]),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blueGrey[50],
      ),
      validator: required ? (value) {
        if (value == null || value.isEmpty) return 'Este campo es obligatorio';
        return null;
      } : null,
    );
  }

  Widget _buildTextArea(TextEditingController controller, String label) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      decoration: InputDecoration(
        labelText: label,
        alignLabelWithHint: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.blueGrey[50],
      ),
    );
  }

  Widget _buildDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.blueGrey[50],
            border: Border.all(color: Colors.blueGrey[300]!),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            underline: SizedBox(),
            items: items.map((String item) {
              return DropdownMenuItem<String>(
                value: item,
                child: Text(item),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}