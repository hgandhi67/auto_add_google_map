import 'dart:io';

import 'package:auto_add_google_map/add_package_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Flutter Project Automator',
      home: NewPage(),
    );
  }
}

class NewPage extends StatelessWidget {
  const NewPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Project Automator')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            final service = AutoAddPackageService.instance;
            if (Platform.isAndroid || Platform.isIOS) {
              Map<Permission, PermissionStatus> statuses = await [
                Permission.manageExternalStorage,
                Permission.photos,
                Permission.videos,
              ].request();

              if (statuses.containsValue(PermissionStatus.denied)) {
                return;
              }
            }

            String? projectPath = await selectProject();
            if (projectPath == null || !isFlutterProject(projectPath)) {
              return;
            }

            // Add the package
            service.addPackageToPubspec(projectPath, 'google_maps_flutter');
            service.runPubGet(projectPath);

            final apiKey = await service.promptForApiKey(context);
            if (apiKey != null) {
              service.updateAndroidManifest(projectPath, apiKey);
              service.updateIOSPlist(projectPath, apiKey);
              service.updateAppDelegateSwift(projectPath, apiKey);

              // Run the Flutter project
              service.runFlutterProject(projectPath);

              service.addGoogleMapDemo(projectPath);

              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Done")));
            } else {
              ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text("You've not provided API key.")));
            }
          },
          child: const Text('Start Automation'),
        ),
      ),
    );
  }

  bool isFlutterProject(String path) {
    return File('$path/pubspec.yaml').existsSync();
  }

  Future<String?> selectProject() async {
    final String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    return selectedDirectory;
  }
}
