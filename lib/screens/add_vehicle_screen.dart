import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'package:auto_market/models/vehicle_model.dart';
import 'package:auto_market/services/firebase_service.dart';
import 'package:auto_market/services/image_upload_service.dart';

class AddVehicleScreen extends StatefulWidget {
  @override
  _AddVehicleScreenState createState() => _AddVehicleScreenState();
}

class _AddVehicleScreenState extends State<AddVehicleScreen> {
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
  final _engineDisplacementController = TextEditingController(); // NUEVO
  final _dealershipNameController = TextEditingController(); // NUEVO

  // Variables del formulario
  List<File> _selectedImages = [];
  String _selectedTraction = '4x2';
  String _selectedFuelType = 'Gasolina';
  String _selectedSellerType = 'Directo';
  String _selectedCategory = 'Carro';
  bool _isLoading = false;
  bool _isUploadingImages = false;
  int _uploadProgress = 0;
  int _totalImagesSizeKB = 0;
  bool _showSizeWarning = false;

  // Lista de categorías - CAMBIO: "Moto" a "Motocicleta"
  final List<String> _categoryOptions = [
    'Carro',
    'Motocicleta', // CAMBIADO
    'Camioneta',
    'Camión',
    'Furgoneta',
    'Bus',
    'Otro'
  ];

  final List<String> _tractionOptions = ['4x2', '4x4'];
  final List<String> _fuelOptions = ['Gasolina', 'Híbrido', 'Eléctrico', 'Diesel', 'Gas'];
  final List<String> _sellerOptions = ['Directo', 'Concesionaria'];

  @override
  void initState() {
    super.initState();
    // Configurar listeners para mostrar/ocultar campos dinámicamente
    _selectedCategory = 'Carro';
    _selectedSellerType = 'Directo';
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

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedImages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor selecciona al menos una imagen')),
      );
      return;
    }

    // Validaciones específicas
    if (_showDealershipField && _dealershipNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Por favor ingresa el nombre de la concesionaria')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
      _isUploadingImages = true;
      _uploadProgress = 0;
      _totalImagesSizeKB = 0;
      _showSizeWarning = false;
    });

    try {
      final user = _auth.currentUser!;
      
      // Convertir imágenes a Base64 CON COMPRESIÓN
      List<String> base64Images = await ImageUploadService.convertMultipleImagesToBase64(
        _selectedImages,
        maxWidth: 800,
        quality: 75,
      );

      // Calcular tamaño total
      _totalImagesSizeKB = base64Images.fold(0, (total, base64) {
        return total + ImageUploadService.getBase64SizeInKB(base64);
      });

      // Verificar si alguna imagen es muy grande
      _showSizeWarning = base64Images.any((base64) {
        return ImageUploadService.isImageTooLarge(base64, maxSizeKB: 400);
      });

      setState(() {
        _isUploadingImages = false;
        _uploadProgress = 100;
      });

      // Mostrar advertencia si las imágenes son muy grandes
      if (_showSizeWarning) {
        final shouldContinue = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('Imágenes muy grandes'),
            content: Text(
              'Algunas imágenes son muy grandes ($_totalImagesSizeKB KB). '
              'Esto puede afectar el rendimiento. ¿Deseas continuar?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Continuar'),
              ),
            ],
          ),
        );

        if (shouldContinue != true) {
          setState(() => _isLoading = false);
          return;
        }
      }

      // Crear URLs de datos para las imágenes
      List<String> dataUrls = base64Images.map((base64) => 
        'data:image/jpeg;base64,$base64'
      ).toList();

      // Para motocicletas, establecer valores por defecto para campos no aplicables
      int doors = _showMotorcycleFields ? 0 : int.parse(_doorsController.text);
      String traction = _showMotorcycleFields ? 'No aplica' : _selectedTraction;

      // Crear y guardar el vehículo
      final vehicle = Vehicle(
        userId: user.uid,
        userEmail: user.email!,
        imageUrls: dataUrls,
        imageBase64: base64Images,
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
        createdAt: DateTime.now(),
        phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
        vehicleYear: int.parse(_vehicleYearController.text),
        lastRegistrationYear: int.parse(_lastRegistrationYearController.text),
        category: _selectedCategory,
        engineDisplacement: _engineDisplacementController.text.isEmpty ? null : _engineDisplacementController.text, // NUEVO
        dealershipName: _showDealershipField ? _dealershipNameController.text : null, // NUEVO
      );

      await _firebaseService.saveVehicle(vehicle);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vehículo publicado exitosamente! ✅')),
      );
      
      _clearForm();
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al publicar vehículo: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
        _isUploadingImages = false;
        _uploadProgress = 0;
      });
    }
  }

  void _clearForm() {
    _brandController.clear();
    _minPriceController.clear();
    _maxPriceController.clear();
    _doorsController.clear();
    _colorController.clear();
    _locationController.clear();
    _additionalInfoController.clear();
    _phoneController.clear();
    _vehicleYearController.clear();
    _lastRegistrationYearController.clear();
    _engineDisplacementController.clear(); // NUEVO
    _dealershipNameController.clear(); // NUEVO
    _selectedImages.clear();
    setState(() {
      _selectedCategory = 'Carro';
      _selectedSellerType = 'Directo';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Publicar Vehículo'),
        backgroundColor: Colors.blueGrey[900],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sección de imágenes
              _buildImageSection(),
              SizedBox(height: 16),
              
              // Progress bar para subida de imágenes
              if (_isUploadingImages) _buildUploadProgress(),
              if (_totalImagesSizeKB > 0) _buildSizeInfo(),
              
              // Categoría del vehículo
              _buildDropdown('Categoría del vehículo*', _selectedCategory, _categoryOptions, (value) {
                setState(() => _selectedCategory = value!);
              }),
              SizedBox(height: 16),
              
              // Información básica
              _buildTextField(_brandController, 'Marca del vehículo*', Icons.directions_car),
              SizedBox(height: 16),
              
              // CILINDRAJE - NUEVO CAMPO (para todas las categorías)
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
              
              // Año del vehículo
              _buildTextField(_vehicleYearController, 'Año del vehículo*', Icons.calendar_today,
                keyboardType: TextInputType.number),
              SizedBox(height: 16),
              
              // Último año de matriculación
              _buildTextField(_lastRegistrationYearController, 'Último año de matriculación*', Icons.calendar_today,
                keyboardType: TextInputType.number),
              SizedBox(height: 16),
              
              // TRACCIÓN - SOLO SI NO ES MOTOCICLETA
              if (!_showMotorcycleFields)
                _buildDropdown('Tracción', _selectedTraction, _tractionOptions, (value) {
                  setState(() => _selectedTraction = value!);
                }),
              if (!_showMotorcycleFields) SizedBox(height: 16),
              
              // Ubicación
              _buildTextField(_locationController, 'Dirección/Ubicación*', Icons.location_on),
              SizedBox(height: 16),
              
              // Tipo de combustible
              _buildDropdown('Tipo de combustible', _selectedFuelType, _fuelOptions, (value) {
                setState(() => _selectedFuelType = value!);
              }),
              SizedBox(height: 16),
              
              // Tipo de vendedor
              _buildDropdown('Tipo de vendedor', _selectedSellerType, _sellerOptions, (value) {
                setState(() => _selectedSellerType = value!);
              }),
              SizedBox(height: 16),
              
              // NOMBRE DE CONCESIONARIA - SOLO SI ES CONCESIONARIA
              if (_showDealershipField)
                _buildTextField(_dealershipNameController, 'Nombre de la concesionaria*', Icons.business),
              if (_showDealershipField) SizedBox(height: 16),
              
              // Teléfono (opcional)
              _buildTextField(_phoneController, 'Teléfono de contacto', Icons.phone,
                keyboardType: TextInputType.phone, required: false),
              SizedBox(height: 16),
              
              // Información adicional
              _buildTextArea(_additionalInfoController, 'Información adicional'),
              SizedBox(height: 32),
              
              // Botón de publicar
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
                      onPressed: _submitForm,
                      child: Text(
                        'PUBLICAR VEHÍCULO',
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
          'Imágenes del vehículo*',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.blueGrey[800]),
        ),
        SizedBox(height: 8),
        Text(
          'Selecciona las fotos de tu vehículo (mínimo 1)',
          style: TextStyle(color: Colors.blueGrey[600], fontSize: 14),
        ),
        SizedBox(height: 12),
        
        // Grid de imágenes
        Container(
          height: 120,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              // Botón para agregar imágenes
              InkWell(
                onTap: _pickImages,
                child: Container(
                  width: 100,
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
                      Text('Agregar', style: TextStyle(color: Colors.blueGrey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ),
              
              // Imágenes seleccionadas
              ..._selectedImages.map((imageFile) => Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    margin: EdgeInsets.only(left: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      image: DecorationImage(
                        image: FileImage(imageFile),
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
                        onPressed: () {
                          setState(() {
                            _selectedImages.remove(imageFile);
                          });
                        },
                      ),
                    ),
                  ),
                ],
              )).toList(),
            ],
          ),
        ),
        
        if (_selectedImages.isNotEmpty) ...[
          SizedBox(height: 8),
          Text(
            '${_selectedImages.length} imagen(es) seleccionada(s)',
            style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
          ),
        ],
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Column(
      children: [
        SizedBox(height: 16),
        LinearProgressIndicator(
          value: _uploadProgress / 100,
          backgroundColor: Colors.blueGrey[200],
          valueColor: AlwaysStoppedAnimation<Color>(Colors.orange[600]!),
        ),
        SizedBox(height: 8),
        Text(
          'Subiendo imágenes... $_uploadProgress%',
          style: TextStyle(color: Colors.blueGrey[600], fontSize: 12),
        ),
        SizedBox(height: 16),
      ],
    );
  }

  Widget _buildSizeInfo() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 8),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _showSizeWarning ? Colors.orange[100] : Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _showSizeWarning ? Colors.orange : Colors.green,
        ),
      ),
      child: Row(
        children: [
          Icon(
            _showSizeWarning ? Icons.warning : Icons.check_circle,
            color: _showSizeWarning ? Colors.orange : Colors.green,
          ),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              _showSizeWarning 
                  ? 'Imágenes grandes: $_totalImagesSizeKB KB (puede ser lento)'
                  : 'Tamaño total: $_totalImagesSizeKB KB',
              style: TextStyle(
                color: _showSizeWarning ? Colors.orange[800] : Colors.green[800],
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
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