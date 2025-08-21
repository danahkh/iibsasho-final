import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:flutter/material.dart';
import '../utils/supabase_helper.dart';

class ImageUploadService {
  static final ImagePicker _picker = ImagePicker();
  
  /// Maximum number of images allowed per listing
  static const int maxImages = 15;
  
  /// Maximum number of videos allowed per listing
  static const int maxVideos = 5;
  
  /// Maximum file size in bytes (10MB)
  static const int maxFileSize = 10 * 1024 * 1024;
  
  /// Allowed image formats
  static const List<String> allowedImageFormats = ['jpg', 'jpeg', 'png', 'webp'];
  
  /// Allowed video formats
  static const List<String> allowedVideoFormats = ['mp4', 'mov', 'avi', 'mkv'];

  /// Pick multiple images from gallery (up to 15)
  static Future<List<XFile>> pickMultipleImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage();
      
      if (images.length > maxImages) {
        throw Exception('Maximum $maxImages images allowed. You selected ${images.length} images.');
      }
      
      // Validate each image
      List<XFile> validImages = [];
      for (XFile image in images) {
        if (await _validateImageFile(image)) {
          validImages.add(image);
        }
      }
      
      return validImages;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick single image from gallery or camera
  static Future<XFile?> pickSingleImage({ImageSource source = ImageSource.gallery}) async {
    try {
      final XFile? image = await _picker.pickImage(source: source);
      
      if (image != null && await _validateImageFile(image)) {
        return image;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Pick video from gallery
  static Future<XFile?> pickVideo() async {
    try {
      final XFile? video = await _picker.pickVideo(source: ImageSource.gallery);
      
      if (video != null && await _validateVideoFile(video)) {
        return video;
      }
      
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Upload images to Supabase Storage
  static Future<List<String>> uploadImages(List<XFile> images, {String folder = 'listing_images'}) async {
    List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < images.length; i++) {
        final image = images[i];
        final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}_${i}_${image.name}';
        
        try {
          String url;
          if (kIsWeb) {
            final bytes = await image.readAsBytes();
            await SupabaseHelper.client.storage.from('listings').uploadBinary(fileName, bytes);
          } else {
            final file = File(image.path);
            await SupabaseHelper.client.storage.from('listings').upload(fileName, file);
          }
          
          url = SupabaseHelper.client.storage.from('listings').getPublicUrl(fileName);
          uploadedUrls.add(url);
        } catch (uploadError) {
          // If bucket doesn't exist, provide helpful error message
          if (uploadError.toString().contains('404') || uploadError.toString().contains('bucket')) {
            throw Exception('Storage bucket not found. Please contact support to set up file storage.');
          }
          rethrow;
        }
      }
    } catch (e) {
      // Clean up any uploaded files if there's an error
      for (String url in uploadedUrls) {
        try {
          final fileName = url.split('/').last;
          await SupabaseHelper.client.storage.from('listings').remove([fileName]);
        } catch (cleanupError) {
          // Ignore cleanup errors
        }
      }
      rethrow;
    }
    
    return uploadedUrls;
  }

  /// Upload multiple videos to Supabase Storage
  static Future<List<String>> uploadVideos(List<XFile> videos, {String folder = 'listing_videos'}) async {
    List<String> uploadedUrls = [];
    
    try {
      for (int i = 0; i < videos.length; i++) {
        final video = videos[i];
        final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}_${i}_${video.name}';
        
        try {
          String url;
          if (kIsWeb) {
            final bytes = await video.readAsBytes();
            await SupabaseHelper.client.storage.from('listings').uploadBinary(fileName, bytes);
          } else {
            final file = File(video.path);
            await SupabaseHelper.client.storage.from('listings').upload(fileName, file);
          }
          
          url = SupabaseHelper.client.storage.from('listings').getPublicUrl(fileName);
          uploadedUrls.add(url);
        } catch (uploadError) {
          // If bucket doesn't exist, provide helpful error message
          if (uploadError.toString().contains('404') || uploadError.toString().contains('bucket')) {
            throw Exception('Storage bucket not found. Please contact support to set up file storage.');
          }
          rethrow;
        }
      }
    } catch (e) {
      // Clean up any uploaded files if there's an error
      for (String url in uploadedUrls) {
        try {
          final fileName = url.split('/').last;
          await SupabaseHelper.client.storage.from('listings').remove([fileName]);
        } catch (cleanupError) {
          // Ignore cleanup errors
        }
      }
      rethrow;
    }
    
    return uploadedUrls;
  }

  /// Upload single video to Supabase Storage
  static Future<String?> uploadVideo(XFile video, {String folder = 'listing_videos'}) async {
    try {
      final fileName = '$folder/${DateTime.now().millisecondsSinceEpoch}_${video.name}';
      
      String url;
      if (kIsWeb) {
        final bytes = await video.readAsBytes();
        await SupabaseHelper.client.storage.from('listings').uploadBinary(fileName, bytes);
      } else {
        final file = File(video.path);
        await SupabaseHelper.client.storage.from('listings').upload(fileName, file);
      }
      
      url = SupabaseHelper.client.storage.from('listings').getPublicUrl(fileName);
      return url;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate image file
  static Future<bool> _validateImageFile(XFile image) async {
    try {
      // Check file extension
      final extension = image.name.split('.').last.toLowerCase();
      if (!allowedImageFormats.contains(extension)) {
        throw Exception('Invalid image format. Allowed formats: ${allowedImageFormats.join(', ')}');
      }
      
      // Check file size
      final fileSize = kIsWeb ? (await image.readAsBytes()).length : await File(image.path).length();
      if (fileSize > maxFileSize) {
        throw Exception('Image file too large. Maximum size: ${(maxFileSize / (1024 * 1024)).toStringAsFixed(1)}MB');
      }
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Validate video file
  static Future<bool> _validateVideoFile(XFile video) async {
    try {
      // Check file extension
      final extension = video.name.split('.').last.toLowerCase();
      if (!allowedVideoFormats.contains(extension)) {
        throw Exception('Invalid video format. Allowed formats: ${allowedVideoFormats.join(', ')}');
      }
      
      // Check file size (larger limit for videos - 50MB)
      const int maxVideoSize = 50 * 1024 * 1024;
      final fileSize = kIsWeb ? (await video.readAsBytes()).length : await File(video.path).length();
      if (fileSize > maxVideoSize) {
        throw Exception('Video file too large. Maximum size: ${(maxVideoSize / (1024 * 1024)).toStringAsFixed(1)}MB');
      }
      
      return true;
    } catch (e) {
      rethrow;
    }
  }

  /// Delete file from Supabase Storage
  static Future<void> deleteFile(String url) async {
    try {
      final fileName = url.split('/').last;
      await SupabaseHelper.client.storage.from('listings').remove([fileName]);
    } catch (e) {
      // Ignore delete errors for now
    }
  }

  /// Get upload progress widget
  static Widget buildUploadProgress(int uploaded, int total) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LinearProgressIndicator(
            value: total > 0 ? uploaded / total : 0,
            backgroundColor: Colors.blue.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
          ),
          SizedBox(height: 8),
          Text(
            'Uploading... $uploaded of $total files',
            style: TextStyle(
              fontSize: 14,
              color: Colors.blue.shade700,
            ),
          ),
        ],
      ),
    );
  }
}
