import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class ImageUploadService {
  static Future<String> convertImageToBase64(File imageFile, {int maxWidth = 800, int quality = 80}) async {
    try {
      List<int> imageBytes = await imageFile.readAsBytes();
      
      Uint8List uint8List = Uint8List.fromList(imageBytes);
      
      final originalImage = img.decodeImage(uint8List);
      if (originalImage == null) {
        throw Exception('No se pudo decodificar la imagen');
      }
      
      int newWidth = originalImage.width;
      int newHeight = originalImage.height;
      
      if (originalImage.width > maxWidth) {
        newWidth = maxWidth;
        newHeight = (originalImage.height * maxWidth / originalImage.width).round();
      }
      
      final resizedImage = img.copyResize(originalImage, width: newWidth, height: newHeight);
      
      List<int> compressedBytes = img.encodeJpg(resizedImage, quality: quality);
      
      String base64Image = base64Encode(compressedBytes);
      
      print('Imagen comprimida: ${imageBytes.length ~/ 1024}KB -> ${compressedBytes.length ~/ 1024}KB');
      
      return base64Image;
    } catch (e) {
      print('Error comprimiendo imagen: $e');
      List<int> imageBytes = await imageFile.readAsBytes();
      return base64Encode(imageBytes);
    }
  }

  static Future<List<String>> convertMultipleImagesToBase64(
    List<File> imageFiles, {
    int maxWidth = 800,
    int quality = 80,
  }) async {
    List<String> base64Images = [];
    
    for (int i = 0; i < imageFiles.length; i++) {
      final base64Image = await convertImageToBase64(
        imageFiles[i],
        maxWidth: maxWidth,
        quality: quality,
      );
      base64Images.add(base64Image);
      
      await Future.delayed(Duration(milliseconds: 100));
    }
    
    return base64Images;
  }

  static int getBase64SizeInKB(String base64String) {
    return (base64String.length * 3 / 4 / 1024).round();
  }

  static bool isImageTooLarge(String base64String, {int maxSizeKB = 500}) {
    return getBase64SizeInKB(base64String) > maxSizeKB;
  }
}