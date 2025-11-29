import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;

class WebVideoService {
  static final WebVideoService _instance = WebVideoService._internal();
  factory WebVideoService() => _instance;
  WebVideoService._internal();

  bool _isRecording = false;
  bool get isRecording => _isRecording;

  Future<bool> startRecording() async {
    if (!kIsWeb) {
      return false;
    }
    _isRecording = true;
    return true;
  }

  Future<Uint8List?> stopRecording() async {
    if (!kIsWeb) {
      return null;
    }
    _isRecording = false;
    return null;
  }

  void dispose() {
    _isRecording = false;
  }
}
