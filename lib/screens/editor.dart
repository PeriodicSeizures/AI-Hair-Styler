import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:senior_project_hair_ai/Navigation.dart';
import 'package:senior_project_hair_ai/api_access.dart';
import 'package:senior_project_hair_ai/preferences_provider.dart';
import 'package:senior_project_hair_ai/screens/capture.dart';
import 'package:senior_project_hair_ai/screens/results.dart';
import 'package:senior_project_hair_ai/screens/settings.dart';

// TODO properly implement

class MyEditorPage extends StatefulWidget {
  const MyEditorPage({super.key, required this.inputImagePath});

  final String inputImagePath; //the camera image path will be saved here

  @override
  State<MyEditorPage> createState() => _MyEditorPageState();
}

class _MyEditorPageState extends State<MyEditorPage> {
  /*
    editor
      will contain options relating to ai generation? (more such as weights)
  */

  void styleSelector(int styleIndex) {
    setState(() {
      if (selectedStyle == styleIndex) {
        selectedStyle = -1;
      } else {
        selectedStyle = styleIndex;
      }
    });
  }

  void colorSelector(int colorIndex) {
    setState(() {
      if (selectedColor == colorIndex) {
        selectedColor = -1;
      } else {
        selectedColor = colorIndex;
      }
    });
  }

  String iterate(dynamic funIndex) {
    return "assets/images/IMG ($funIndex).png";
  }

  bool imageChange = false;
  //String finalPath = '';
  int selectedStyle = -1;
  int selectedColor = -1;
  File? imageUploaded;

  Future uploadImage() async {
    final returnedImage =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    if (returnedImage == null) {
      return;
    }
    setState(() {
      imageUploaded = File(returnedImage.path);
      //Provider.of<RecentsProvider>(context, listen: false).addFile(returnedImage.path);
      //Provider.of<PreferencesProvider>(context, listen: false).
      Provider.of<PreferencesProvider>(context, listen: false)
          .createListOrAdd(recentsListPrefKey, <String>[returnedImage.path]);
      //finalPath = returnedImage.path;
      imageChange = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Editor'),
      ),
      body: Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            GestureDetector(
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext context) {
                    return AlertDialog(
                      title: const Text('Change Image'),
                      content:
                          const Text('Would you like to change this image?'),
                      actions: <Widget>[
                        TextButton(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          child: const Text('No'),
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to the gallery here
                            uploadImage();
                            imageChange = true;
                            Navigator.pop(context); // Close the dialog
                          },
                          child: const Text('Yes'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: Container(
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: (imageChange == true && imageUploaded != null)
                      //? Image.file(File(finalPath))
                      ? Image.file(imageUploaded!)
                      : (widget.inputImagePath == '')
                          ? Image.asset(
                              'assets/images/default.png',
                              fit: BoxFit.cover,
                            )
                          : Image.file(
                              File(widget.inputImagePath),
                              fit: BoxFit.cover,
                            ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              "Select Your Hairstyle:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18.0,
              ),
            ),
            Container(
              height: 260,
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepPurple, // Border color
                  width: 3, // Border width
                ),
                borderRadius: BorderRadius.circular(7), // Border radius
              ),
              child: SingleChildScrollView(
                child: GridView.count(
                  shrinkWrap: true,
                  crossAxisCount: 4,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  physics: const NeverScrollableScrollPhysics(),
                  children: List.generate(
                    20,
                    (index) => GestureDetector(
                      onTap: () {
                        styleSelector(index);
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: selectedStyle == index
                                ? Colors.deepPurpleAccent
                                : Colors.transparent,
                            width: 4,
                          ),
                        ),
                        child: Image.asset(
                          iterate(index),
                          fit: BoxFit.cover,
                        ), //Text('Item $index'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
            const Text(
              "Select Your Hair Color:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 18.0,
              ),
            ),
            Container(
              height: 100, // Set a smaller height for the container
              decoration: BoxDecoration(
                border: Border.all(
                  color: Colors.deepPurple, // Border color
                  width: 5, // Border width
                ),
                borderRadius: BorderRadius.circular(7), // Border radius
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    Colors.redAccent,
                    Colors.brown,
                    Colors.black,
                    Colors.yellow,
                    Colors.white,
                  ].asMap().entries.map((entry) {
                    final index = entry.key;
                    final color = entry.value;

                    return GestureDetector(
                      onTap: () {
                        colorSelector(index);
                      },
                      child: Container(
                        width: 50,
                        height: 50,
                        margin: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: color,
                          border: Border.all(
                            color: selectedColor == index
                                ? Colors.deepPurpleAccent
                                : Colors.transparent,
                            width: 4,
                          ),
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Spacer(),
            ElevatedButton(
              onPressed: (selectedColor != -1 || selectedStyle != -1)
                  ? () {
                      // TODO
                      // The API is ready here:
                      final prefs = Provider.of<PreferencesProvider>(
                        context,
                        listen: false,
                      );
                      apiBarberPost(
                        prefs.get<String>(apiHostPrefKey)!,
                        prefs.get<String>(apiTokenPrefKey)!,
                        imageUploaded!.path,
                        selectedStyle.toString(), // 'bob', // style
                        selectedColor.toString(), // 'dark-blonde' // color
                      ).then((response) {
                        if (response.statusCode == 200) {
                          // TODO submit to job queue
                          Fluttertoast.showToast(msg: 'Success!');
                        } else if (response.statusCode == 422) {
                          Fluttertoast.showToast(msg: 'Invalid access token');
                        } else {
                          Fluttertoast.showToast(
                            msg: 'Status Code: ${response.statusCode}',
                          );
                        }
                      }).onError((error, stackTrace) {
                        log(error.toString());
                        Fluttertoast.showToast(
                          msg: 'Failed to connect: $error',
                          toastLength: Toast.LENGTH_LONG,
                        );
                      });

                      // Because the AI process takes a while, use a job queue that shows submitted jobs
                      //  When the user sends to the API, the API will respond with a path of the eventual generated image
                      //  as a served file.
                      // The user can query this image path to see if the job has completed.
                      // The job queue will store a list of these job paths for the client to poll
                      //  Polling will query the server for the served image
                      // A non-200 response code means the image does not exist, or that the process is still busy

                      //TODO Values to barbershop, navigate to the final screen, display results
                      navigateTo(
                        context: context,
                        screen: const MyResultsPage(),
                        style: NavigationRouteStyle.material,
                      );
                    }
                  : null,
              child: const Text(
                'Generate',
                style: TextStyle(fontSize: 24),
              ),
            ),
            // Add a SizedBox after the Container to create space between the rows
          ],
        ),
      ),
    );
  }
}
