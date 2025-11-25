import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  String? id;
  String email;
  String name;
  String phone;
  DateTime createdAt;
  List<String> favorites;
  int publicationsCount;

  UserModel({
    this.id,
    required this.email,
    required this.name,
    required this.phone,
    required this.createdAt,
    this.favorites = const [],
    this.publicationsCount = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'favorites': favorites,
      'publicationsCount': publicationsCount,
    };
  }

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
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

    return UserModel(
      id: id,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      phone: map['phone'] ?? '',
      createdAt: createdAtDate,
      favorites: List<String>.from(map['favorites'] ?? []),
      publicationsCount: map['publicationsCount'] ?? 0,
    );
  }
}