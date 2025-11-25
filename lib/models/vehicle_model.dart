import 'package:cloud_firestore/cloud_firestore.dart';

class Vehicle {
  String? id;
  String userId;
  String userEmail;
  List<String> imageUrls;
  List<String>? imageBase64;
  String brand;
  double minPrice;
  double maxPrice;
  int doors;
  String color;
  String traction;
  String location;
  String fuelType;
  String sellerType;
  String additionalInfo;
  DateTime createdAt;
  bool isSold;
  bool isAvailable;
  String? phoneNumber;
  int vehicleYear;
  int lastRegistrationYear;
  String category;
  String? engineDisplacement;
  String? dealershipName;

  Vehicle({
    this.id,
    required this.userId,
    required this.userEmail,
    required this.imageUrls,
    this.imageBase64,
    required this.brand,
    required this.minPrice,
    required this.maxPrice,
    required this.doors,
    required this.color,
    required this.traction,
    required this.location,
    required this.fuelType,
    required this.sellerType,
    required this.additionalInfo,
    required this.createdAt,
    this.isSold = false,
    this.isAvailable = true,
    this.phoneNumber,
    required this.vehicleYear,
    required this.lastRegistrationYear,
    required this.category,
    this.engineDisplacement,
    this.dealershipName,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'userEmail': userEmail,
      'imageUrls': imageUrls,
      'imageBase64': imageBase64,
      'brand': brand,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'doors': doors,
      'color': color,
      'traction': traction,
      'location': location,
      'fuelType': fuelType,
      'sellerType': sellerType,
      'additionalInfo': additionalInfo,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'isSold': isSold,
      'isAvailable': isAvailable,
      'phoneNumber': phoneNumber,
      'vehicleYear': vehicleYear,
      'lastRegistrationYear': lastRegistrationYear,
      'category': category,
      'engineDisplacement': engineDisplacement,
      'dealershipName': dealershipName,
    };
  }

  factory Vehicle.fromMap(String id, Map<String, dynamic> map) {
    // Manejar Timestamp de Firestore
    dynamic createdAt = map['createdAt'];
    DateTime createdAtDate;
    
    if (createdAt is Timestamp) {
      createdAtDate = createdAt.toDate();
    } else if (createdAt is int) {
      createdAtDate = DateTime.fromMillisecondsSinceEpoch(createdAt);
    } else {
      createdAtDate = DateTime.now();
    }

    return Vehicle(
      id: id,
      userId: map['userId'] ?? '',
      userEmail: map['userEmail'] ?? '',
      imageUrls: List<String>.from(map['imageUrls'] ?? []),
      imageBase64: map['imageBase64'] != null ? List<String>.from(map['imageBase64']) : null,
      brand: map['brand'] ?? '',
      minPrice: (map['minPrice'] ?? 0).toDouble(),
      maxPrice: (map['maxPrice'] ?? 0).toDouble(),
      doors: map['doors'] ?? 0,
      color: map['color'] ?? '',
      traction: map['traction'] ?? '',
      location: map['location'] ?? '',
      fuelType: map['fuelType'] ?? '',
      sellerType: map['sellerType'] ?? '',
      additionalInfo: map['additionalInfo'] ?? '',
      createdAt: createdAtDate,
      isSold: map['isSold'] ?? false,
      isAvailable: map['isAvailable'] ?? true,
      phoneNumber: map['phoneNumber'],
      vehicleYear: map['vehicleYear'] ?? DateTime.now().year,
      lastRegistrationYear: map['lastRegistrationYear'] ?? DateTime.now().year,
      category: map['category'] ?? 'Carro',
      engineDisplacement: map['engineDisplacement'],
      dealershipName: map['dealershipName'],
    );
  }

  List<String> get displayImages {
    if (imageBase64 != null && imageBase64!.isNotEmpty) {
      return imageBase64!;
    }
    if (imageUrls.isNotEmpty) {
      return imageUrls;
    }
    return [];
  }
}