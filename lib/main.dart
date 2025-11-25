import 'package:flutter/material.dart';
import 'package:auto_market/screens/home_screen.dart';
import 'package:auto_market/screens/auth_screen.dart';
import 'package:auto_market/screens/add_vehicle_screen.dart';
import 'package:auto_market/screens/profile_screen.dart';
import 'package:auto_market/screens/edit_profile_screen.dart';
import 'package:auto_market/screens/my_publications_screen.dart';
import 'package:auto_market/screens/favorites_screen.dart';
import 'package:auto_market/screens/chat_list_screen.dart';
import 'package:auto_market/screens/chat_screen.dart';
import 'package:auto_market/screens/vehicle_detail_screen.dart';
import 'package:auto_market/screens/edit_vehicle_screen.dart';
import 'package:auto_market/screens/admin_screen.dart';
import 'package:auto_market/screens/admin_register_screen.dart';
import 'package:auto_market/models/vehicle_model.dart';
import 'app.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoMarket',
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: App(),
      debugShowCheckedModeBanner: false,
      // Configuración de rutas
      onGenerateRoute: (settings) {
        switch (settings.name) {
          case '/':
            return MaterialPageRoute(builder: (context) => App());
          case '/home':
            return MaterialPageRoute(builder: (context) => HomeScreen());
          case '/auth':
            return MaterialPageRoute(builder: (context) => AuthScreen());
          case '/add-vehicle':
            return MaterialPageRoute(builder: (context) => AddVehicleScreen());
          case '/profile':
            return MaterialPageRoute(builder: (context) => ProfileScreen());
          case '/edit-profile':
            return MaterialPageRoute(builder: (context) => EditProfileScreen());
          case '/my-publications':
            return MaterialPageRoute(builder: (context) => MyPublicationsScreen());
          case '/favorites':
            return MaterialPageRoute(builder: (context) => FavoritesScreen());
          case '/chat-list':
            return MaterialPageRoute(builder: (context) => ChatListScreen());
          case '/chat':
            final args = settings.arguments as Map<String, dynamic>?;
            return MaterialPageRoute(builder: (context) => ChatScreen(
              chatId: args?['chatId'],
              sellerId: args?['sellerId'],
              sellerEmail: args?['sellerEmail'],
            ));
          case '/vehicle-detail':
            final vehicle = settings.arguments as Vehicle;
            return MaterialPageRoute(builder: (context) => VehicleDetailScreen(vehicle: vehicle));
          case '/edit-vehicle':
            final vehicle = settings.arguments as Vehicle;
            return MaterialPageRoute(builder: (context) => EditVehicleScreen(vehicle: vehicle));
          case '/admin':
            return MaterialPageRoute(builder: (context) => AdminScreen());
          case '/admin-register':
            return MaterialPageRoute(builder: (context) => AdminRegisterScreen());
          default:
            return MaterialPageRoute(builder: (context) => App());
        }
      },
    );
  }
}