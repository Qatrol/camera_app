import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class CameraApp extends StatefulWidget {
  final List<CameraDescription> cameras;

  const CameraApp({super.key, required this.cameras});

  @override
  State<CameraApp> createState() => _CameraAppState();
}

class _CameraAppState extends State<CameraApp> {
  late CameraController _cameraController;
  late Position _currentPosition;
  final TextEditingController _commentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _getCurrentLocation();
  }

  Future<void> _initializeCamera() async {
    try {
      _cameraController = CameraController(
        widget.cameras.first,
        ResolutionPreset.max,
      );
      await _cameraController.initialize();
      if (!mounted) return;
      setState(() {});
    } catch (e) {
      if (e is CameraException) {
        debugPrint('Camera Exception: ${e.code} - ${e.description}');
      } else {
        debugPrint('Unknown Error: $e');
      }
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('Location services are disabled.');
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          debugPrint('Location permissions are denied.');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        debugPrint('Location permissions are permanently denied.');
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: LocationSettings(accuracy: LocationAccuracy.high),
      );
      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error retrieving location: $e');
    }
  }

  Future<void> _takePhotoAndUpload() async {
    if (!_cameraController.value.isInitialized) {
      debugPrint('Camera is not initialized');
      return;
    }

    try {
      final XFile picture = await _cameraController.takePicture();
      final File photoFile = File(picture.path);
      final String comment = _commentController.text;
      final double latitude = _currentPosition.latitude;
      final double longitude = _currentPosition.longitude;

      final Uri uri =
          Uri.parse('https://flutter-sandbox.free.beeceptor.com/upload_photo/');
      final http.MultipartRequest request = http.MultipartRequest('POST', uri)
        ..fields['comment'] = comment
        ..fields['latitude'] = latitude.toString()
        ..fields['longitude'] = longitude.toString()
        ..files.add(await http.MultipartFile.fromPath('photo', photoFile.path));

      final http.StreamedResponse response = await request.send();

      if (response.statusCode == 200) {
        debugPrint('Photo uploaded successfully');
      } else {
        debugPrint(
            'Failed to upload photo. Status code: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error while taking the photo or uploading: $e');
    }
  }

  @override
  void dispose() {
    _cameraController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_cameraController.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Camera App'),
        ),
        body: SingleChildScrollView(
          child: Column(
            children: [
              AspectRatio(
                aspectRatio: _cameraController.value.aspectRatio,
                child: CameraPreview(_cameraController),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: TextField(
                  controller: _commentController,
                  decoration: const InputDecoration(
                    labelText: 'Comment',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _takePhotoAndUpload,
                child: const Text("Upload Photo"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
