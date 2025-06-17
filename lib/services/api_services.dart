import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:get/get.dart';

import '../models/predection_response.dart';

class ApiService extends GetxService {
  static const String baseUrl = 'http://192.168.100.9:5000'; // Update with your server IP

  // For Android emulator, use: http://10.0.2.2:5000
  // For iOS simulator, use: http://localhost:5000
  // For physical device, use your computer's IP: http://192.168.100.9:5000

  Future<PredictionResponse> predictImage(File imageFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict_image'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send().timeout(
        Duration(minutes: 2),
        onTimeout: () {
          throw Exception('Request timed out. The server might be busy or offline.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return PredictionResponse.fromJson(jsonData);
      } else {
        var errorData = json.decode(response.body);
        return PredictionResponse.error(
          errorData['error'] ?? 'Server error: ${response.statusCode}',
        );
      }
    } catch (e) {
      return PredictionResponse.error('Network error: ${e.toString()}');
    }
  }

  Future<PredictionResponse> predictVideo(File videoFile) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/predict_video'),
      );

      request.files.add(
        await http.MultipartFile.fromPath('video', videoFile.path),
      );

      var streamedResponse = await request.send().timeout(
        Duration(minutes: 5),
        onTimeout: () {
          throw Exception('Video processing timed out. Try a shorter video or check server status.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var jsonData = json.decode(response.body);
        return PredictionResponse.fromJson(jsonData);
      } else {
        var errorData = json.decode(response.body);
        throw Exception(errorData['error'] ?? 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: ${e.toString()}');
    }
  }
}
