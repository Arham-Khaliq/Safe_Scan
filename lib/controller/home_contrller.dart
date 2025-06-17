import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/predection_response.dart';
import '../services/api_services.dart';

class HomeController extends GetxController {
  final ApiService _apiService = Get.find<ApiService>();
  final ImagePicker _imagePicker = ImagePicker();

  // Observable variables
  var isLoading = false.obs;
  var selectedFile = Rxn<File>();
  var predictionResponse = Rxn<PredictionResponse>();
  var fileType = ''.obs; // 'image' or 'video'

  @override
  void onInit() {
    super.onInit();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.camera,
      Permission.storage,
      Permission.photos,
    ].request();
  }

  void showMediaOptions() {
    Get.bottomSheet(
      Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Select Media Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF0D6E71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.camera_alt,
                  color: Color(0xFF0D6E71),
                ),
              ),
              title: Text('Camera'),
              subtitle: Text('Take a new photo'),
              onTap: () {
                Get.back();
                pickImageFromCamera();
              },
            ),
            Divider(),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF0D6E71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.photo_library,
                  color: Color(0xFF0D6E71),
                ),
              ),
              title: Text('Gallery'),
              subtitle: Text('Choose from your photos'),
              onTap: () {
                Get.back();
                pickImageFromGallery();
              },
            ),
            Divider(),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Color(0xFF0D6E71).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.videocam,
                  color: Color(0xFF0D6E71),
                ),
              ),
              title: Text('Video'),
              subtitle: Text('Select a video file'),
              onTap: () {
                Get.back();
                pickVideo();
              },
            ),
          ],
        ),
      ),
      backgroundColor: Colors.transparent,
    );
  }

  Future<void> pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (image != null) {
        selectedFile.value = File(image.path);
        fileType.value = 'image';
        predictionResponse.value = null;

        // Auto-start analysis after selecting
        uploadAndPredict();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image from camera: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickImageFromGallery() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (image != null) {
        selectedFile.value = File(image.path);
        fileType.value = 'image';
        predictionResponse.value = null;

        // Auto-start analysis after selecting
        uploadAndPredict();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick image from gallery: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> pickVideo() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: false,
      );

      if (result != null && result.files.single.path != null) {
        selectedFile.value = File(result.files.single.path!);
        fileType.value = 'video';
        predictionResponse.value = null;

        // Auto-start analysis after selecting
        uploadAndPredict();
      }
    } catch (e) {
      Get.snackbar(
        'Error',
        'Failed to pick video: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  Future<void> uploadAndPredict() async {
    if (selectedFile.value == null) {
      showMediaOptions();
      return;
    }

    isLoading.value = true;

    try {
      // Show loading dialog
      Get.dialog(
        Center(
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF0D6E71)),
                ),
                SizedBox(height: 20),
                Text(
                  fileType.value == 'image' ? 'Analyzing Image...' : 'Processing Video...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Please wait',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
        barrierDismissible: false,
      );

      PredictionResponse response;
      if (fileType.value == 'image') {
        response = await _apiService.predictImage(selectedFile.value!);
      } else {
        response = await _apiService.predictVideo(selectedFile.value!);
      }

      predictionResponse.value = response;

      // Close loading dialog
      Get.back();

      if (response.hasError) {
        Get.snackbar(
          'Error',
          response.error!,
          backgroundColor: Colors.red[100],
          colorText: Colors.red[900],
          snackPosition: SnackPosition.BOTTOM,
        );
      } else {
        Get.snackbar(
          'Success',
          '${fileType.value.capitalize} processed successfully',
          backgroundColor: Colors.green[100],
          colorText: Colors.green[900],
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      // Close loading dialog if open
      if (Get.isDialogOpen ?? false) {
        Get.back();
      }

      Get.snackbar(
        'Error',
        'Failed to process file: ${e.toString()}',
        backgroundColor: Colors.red[100],
        colorText: Colors.red[900],
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
    }
  }

  void clearSelection() {
    selectedFile.value = null;
    predictionResponse.value = null;
    fileType.value = '';
  }
}
