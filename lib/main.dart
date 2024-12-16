import 'package:camera/camera.dart';
import 'package:camera_app/screens/home.dart';
import 'package:flutter/material.dart';

late List<CameraDescription> cameras;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  cameras = await availableCameras();
  runApp(CameraApp(
    cameras: cameras,
  ));
}
