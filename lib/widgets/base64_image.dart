import 'package:flutter/material.dart';
import 'dart:convert';

class Base64Image extends StatelessWidget {
  final String base64String;
  final double? width;
  final double? height;
  final BoxFit fit;

  const Base64Image({
    Key? key,
    required this.base64String,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    try {
      // Si es una URL de datos (data:image/jpeg;base64,...)
      if (base64String.startsWith('data:image')) {
        final base64Data = base64String.split(',').last;
        return Image.memory(
          base64.decode(base64Data),
          width: width,
          height: height,
          fit: fit,
          errorBuilder: (context, error, stackTrace) {
            return _buildErrorWidget();
          },
        );
      }
      
      // Si es base64 puro (sin prefijo data:image)
      return Image.memory(
        base64.decode(base64String),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return _buildErrorWidget();
        },
      );
    } catch (e) {
      print('Error decoding Base64 image: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Container(
      width: width,
      height: height,
      color: Colors.blueGrey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.directions_car,
              size: 40,
              color: Colors.blueGrey[400],
            ),
            SizedBox(height: 8),
            Text(
              'Imagen no disponible',
              style: TextStyle(
                color: Colors.blueGrey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}