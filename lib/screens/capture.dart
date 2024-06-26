import 'dart:developer';
import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:senior_project_hair_ai/camera_provider.dart';
import 'package:senior_project_hair_ai/preferences_provider.dart';
import 'package:senior_project_hair_ai/screens/user_profile.dart';

@Deprecated('Use UserProfile.recentItems json instead')
const String recentsListPrefKey = 'recent-captures-list';

class TakePictureScreen extends StatefulWidget {
  const TakePictureScreen({super.key});

  @override
  _TakePictureScreenState createState() => _TakePictureScreenState();
}

class _TakePictureScreenState extends State<TakePictureScreen> {
  CameraController ?_controller;
  late Future<void> _initializeControllerFuture;
  bool _useFrontCamera = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndPrompt() async {
    if (!mounted) return;

    try {
      await _initializeControllerFuture;
      final image = await _controller!.takePicture();

      if (!mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => DisplayPictureScreen(imageCachedFile: image),
        ),
      );
    } catch (e) {
      log(e.toString());
    }
  }

  Future<void> initCamera() async {
    final cameras = Provider.of<Wrapmeras>(context, listen: false);

    await _controller?.dispose();

    _controller = CameraController(
      _useFrontCamera ? cameras.getFrontCamera() : cameras.getBackCamera(),
      ResolutionPreset.veryHigh,
      enableAudio: false,
    );

    _initializeControllerFuture = _controller!.initialize();
    await _initializeControllerFuture;
  }

  @override
  Widget build(BuildContext context) {
    //initCamera();

    return Scaffold(
      appBar: AppBar(title: const Text("Take a Photo")),
      body: FutureBuilder<void>(
        future: initCamera(), //_initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return CameraPreview(_controller!);
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
      floatingActionButton: Row(
        children: [
          SizedBox(
            width: 80.0,
            height: 80.0,
            child: FloatingActionButton(
              heroTag: "capture-take-fab",
              onPressed: _takePictureAndPrompt,
              shape: const CircleBorder(),
              child: const Icon(Icons.camera_alt, size: 45.0),
            ),
          ),
          SizedBox(
            width: 80.0,
            height: 80.0,
            child: FloatingActionButton(
              heroTag: "capture-flip-fab",
              onPressed: () {
                setState(() {
                  _useFrontCamera = !_useFrontCamera;
                });
              },
              shape: const CircleBorder(),
              child: const Icon(Icons.flip_camera_android, size: 45.0),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

class DisplayPictureScreen extends StatelessWidget {
  final XFile imageCachedFile;

  const DisplayPictureScreen({super.key, required this.imageCachedFile});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preview')),
      body: Column(
        children: [
          const SizedBox(height: 20), // Add padding above the caption
          //const Padding(
          //  padding: EdgeInsets.all(8.0),
          //  child: Text(
          //    'Save this image?',
          //    style: TextStyle(
          //       fontSize: 32, fontWeight: FontWeight.bold),
          //  ),
          //),
          Expanded(
            child: Stack(
              alignment: Alignment.center, // Center the overlay text
              children: [
                Center(
                  // Center the image
                  child: Image.file(
                    File(imageCachedFile.path),
                    fit: BoxFit.contain, // Maintain aspect ratio
                  ),
                ),
                Positioned(
                  // Position the overlay text
                  top: 20, // Adjust as needed
                  child: Container(
                    padding: const EdgeInsets.all(8.0),
                    color: Colors.black
                        .withOpacity(0.4), // Semi-transparent background
                    child: const Text(
                      'Save this Image?',
                      style: TextStyle(
                        fontSize: 32,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: SizedBox(
        width: 80.0,
        height: 80.0,
        child: FloatingActionButton(
          onPressed: () async {
            final directory = await getApplicationDocumentsDirectory();
            final path =
                '${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
            final File file = File(path);
            await file.writeAsBytes(await imageCachedFile.readAsBytes());

            if (!context.mounted) return;

            Navigator.of(context).popUntil((route) => route.isFirst);

            Fluttertoast.showToast(msg: 'Image saved as $path');
            UserProfile.activeUserProfile().setRecentItems((list) => list.add(path));
          },
          shape: const CircleBorder(),
          child: const Icon(Icons.save_alt, size: 45.0),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}
