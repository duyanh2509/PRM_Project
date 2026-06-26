// ignore_for_file: avoid_print

import 'dart:io';

import 'package:cloudinary_public/cloudinary_public.dart';

class CloudinaryService {
  static final CloudinaryService instance = CloudinaryService._internal();

  factory CloudinaryService() => instance;

  CloudinaryService._internal();

  // *** THÔNG TIN CLOUDINARY ***
  static const String _cloudName = 'dehyvlweg'; // Cloud Name của bạn
  static const String _uploadPreset =
      'water_meter_preset'; // Tạo preset này trên Cloudinary Dashboard

  late final CloudinaryPublic _cloudinary = CloudinaryPublic(
    _cloudName,
    _uploadPreset,
    cache: false,
  );

  /// Upload ảnh lên Cloudinary và trả về URL công khai
  ///
  /// [imageFile] - File ảnh cần upload
  /// [customerCode] - Mã khách hàng (dùng làm folder/identifier)
  ///
  /// Returns: URL công khai của ảnh, hoặc null nếu upload fail
  Future<String?> uploadMeterImage(File imageFile, String customerCode) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${customerCode}_$timestamp';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromFile(
          imageFile.path,
          resourceType: CloudinaryResourceType.Image,
          folder: 'meter_images', // Folder trên Cloudinary
          publicId: publicId,
        ),
      );

      // URL công khai của ảnh
      final url = response.secureUrl;
      print('Cloudinary upload success: $url');
      return url;
    } on CloudinaryException catch (e) {
      print('Cloudinary error: ${e.message}');
      return null;
    } catch (e) {
      print('Error uploading to Cloudinary: $e');
      return null;
    }
  }

  /// Upload ảnh từ bytes (cho inline base64)
  Future<String?> uploadMeterImageBytes(
    List<int> bytes,
    String customerCode,
  ) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final publicId = '${customerCode}_$timestamp';

      final response = await _cloudinary.uploadFile(
        CloudinaryFile.fromBytesData(
          bytes,
          identifier: '$publicId.jpg',
          resourceType: CloudinaryResourceType.Image,
          folder: 'meter_images',
          publicId: publicId,
        ),
      );

      final url = response.secureUrl;
      print('Cloudinary upload success (bytes): $url');
      return url;
    } on CloudinaryException catch (e) {
      print('Cloudinary error: ${e.message}');
      return null;
    } catch (e) {
      print('Error uploading bytes to Cloudinary: $e');
      return null;
    }
  }

  /// Xóa ảnh từ Cloudinary (optional - để cleanup)
  Future<bool> deleteImage(String publicId) async {
    try {
      // Note: Delete cần API Secret, không thể làm từ client
      // Nên dùng Cloud Functions hoặc backend để xóa
      print('Delete operation requires backend/cloud function');
      return false;
    } catch (e) {
      print('Error deleting from Cloudinary: $e');
      return false;
    }
  }
}
