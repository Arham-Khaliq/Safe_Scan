import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart'; // Used for debugPrint

class ApiService {
  // Base URL for your Flask server.
  // IMPORTANT: Replace '192.168.100.8' with the actual IP address
  // of the machine running your Flask server.
  // If running on an emulator, '10.0.2.2' often points to your host machine.
  // If running on a physical device, it must be the actual local network IP.
  static const String _baseUrl = 'http://192.168.100.8:5000';
  static const String imageUrl = '$_baseUrl/predict_image';
  static const String videoUrl = '$_baseUrl/predict_video';

  // Define a timeout for video uploads to prevent indefinite waits.
  // Video processing can take time, so this should be generous.
  static const Duration _videoUploadTimeout = Duration(minutes: 5); // 5 minutes

  /// Uploads an image file to the Flask server for prediction.
  /// Returns a [File] object representing the predicted image (JPG) on success,
  /// or `null` if the upload or prediction fails.
  static Future<File?> uploadImage(File file) async {
    debugPrint('ApiService: Attempting to upload image: ${file.path}');
    try {
      // Create a multipart request to send the image file
      var request = http.MultipartRequest('POST', Uri.parse(imageUrl))
        ..files.add(await http.MultipartFile.fromPath('image', file.path));

      // Send the request and await the response
      var response = await request.send();
      debugPrint('ApiService: Image upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // If successful, read the bytes from the response stream
        final bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();

        // Create a unique filename for the result image to avoid conflicts
        final String uniqueFileName = 'result_image_${DateTime.now().millisecondsSinceEpoch}.jpg';
        final resultFile = File('${tempDir.path}/$uniqueFileName');

        // Write the received bytes to the new file
        await resultFile.writeAsBytes(bytes);
        debugPrint('ApiService: Image prediction successful. Result saved to: ${resultFile.path}');
        return resultFile; // Return the saved file
      } else {
        // If the server returns an error status, read the error message
        final errorBody = await response.stream.bytesToString();
        debugPrint('ApiService: Image upload failed with status ${response.statusCode}: $errorBody');
        return null; // Return null on failure
      }
    } catch (e) {
      // Catch any exceptions during the process (e.g., network errors, file system errors)
      debugPrint('ApiService: Error uploading image: $e');
      return null; // Return null on error
    }
  }

  /// Uploads a video file to the Flask server for prediction and MP4 conversion.
  /// Returns a [File] object representing the predicted and converted video (MP4) on success,
  /// or `null` if the upload, prediction, or conversion fails.
  static Future<File?> uploadVideo(File file) async {
    debugPrint('ApiService: Attempting to upload video: ${file.path}');
    try {
      // Create a multipart request to send the video file
      var request = http.MultipartRequest('POST', Uri.parse(videoUrl))
        ..files.add(await http.MultipartFile.fromPath('video', file.path));

      // Send the request and apply a timeout.
      // The timeout covers the entire round trip: upload, server processing, and download.
      var response = await request.send().timeout(_videoUploadTimeout, onTimeout: () {
        debugPrint('ApiService: Video upload timed out after ${_videoUploadTimeout.inMinutes} minutes.');
        // Throw a specific exception to indicate a timeout
        throw http.ClientException('Video upload and processing timed out.');
      });

      debugPrint('ApiService: Video upload response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        // If successful, read the bytes from the response stream
        final bytes = await response.stream.toBytes();
        final tempDir = await getTemporaryDirectory();

        // Create a unique filename for the result video.
        // IMPORTANT: Expecting an MP4 file from the server after conversion.
        final String uniqueFileName = 'result_video_${DateTime.now().millisecondsSinceEpoch}.mp4';
        final resultFile = File('${tempDir.path}/$uniqueFileName');

        // Write the received bytes to the new file
        await resultFile.writeAsBytes(bytes);
        debugPrint('ApiService: Video prediction successful. Result saved to: ${resultFile.path}');
        return resultFile; // Return the saved file
      } else {
        // If the server returns an error status, read the error message
        final errorBody = await response.stream.bytesToString();
        debugPrint('ApiService: Video upload failed with status ${response.statusCode}: $errorBody');
        return null; // Return null on failure
      }
    } on http.ClientException catch (e) {
      // Catch specific HTTP client errors (e.g., network issues, timeouts)
      debugPrint('ApiService: Client-side HTTP error uploading video: $e');
      return null;
    } catch (e) {
      // Catch any other unexpected exceptions
      debugPrint('ApiService: Unexpected error uploading video: $e');
      return null;
    }
  }
}