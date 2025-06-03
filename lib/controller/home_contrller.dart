// lib/controllers/home_controller.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_player/video_player.dart';

import '../services/api_services.dart';

class HomeController extends GetxController {
  var loading = false.obs;
  var resultFile = Rxn<File>();
  var isVideo = false.obs;
  var videoController = Rxn<VideoPlayerController>();

  void uploadFile(File file, bool video) async {
    loading.value = true;
    isVideo.value = video;

    if (video) {
      final result = await ApiService.uploadVideo(file);
      if (result != null) {
        resultFile.value = result;
        videoController.value = VideoPlayerController.file(result)
          ..initialize().then((_) {
            videoController.value!.play();
            update();
          });
      }
    } else {
      final result = await ApiService.uploadImage(file);
      if (result != null) resultFile.value = result;
    }

    loading.value = false;
  }
}