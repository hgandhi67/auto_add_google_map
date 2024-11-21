import 'dart:io';

import 'package:flutter/material.dart';
import 'package:yaml/yaml.dart';
import 'package:yaml_writer/yaml_writer.dart';

class AutoAddPackageService {
  AutoAddPackageService._();

  static AutoAddPackageService get instance => AutoAddPackageService._();

  void addPackageToPubspec(String projectPath, String packageName) async {
    final pubspecPath = '$projectPath/pubspec.yaml';
    final pubspecFile = File(pubspecPath);

    if (pubspecFile.existsSync()) {
      final content = await pubspecFile.readAsString();
      final doc = loadYaml(content);
      final docCopy = <String, dynamic>{...doc};

      final dependencies = <String, dynamic>{
        ...doc['dependencies'],
      };
      dependencies[packageName] = "any";

      docCopy['dependencies'] = dependencies;
      final writer = YamlWriter();
      await pubspecFile.writeAsString(writer.write(docCopy));
    }
  }

  void runPubGet(String projectPath) async {
    final result = await Process.run('flutter', ['pub', 'get'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      print("Error running flutter pub get: ${result.stderr}");
    }
  }

  Future<String?> promptForApiKey(BuildContext context) async {
    TextEditingController apiKeyController = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter API Key'),
          content: TextField(controller: apiKeyController),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, apiKeyController.text),
              child: const Text('Submit'),
            )
          ],
        );
      },
    );
  }

  void updateAndroidManifest(String projectPath, String apiKey) async {
    final androidManifestPath = '$projectPath/android/app/src/main/AndroidManifest.xml';
    final manifestFile = File(androidManifestPath);

    if (manifestFile.existsSync()) {
      String content = await manifestFile.readAsString();

      // Check if the API key meta-data tag is already present
      if (content.contains('com.google.android.geo.API_KEY')) {
        print("Google Maps API key meta-data is already present in AndroidManifest.xml.");
        return;
      }

      // Locate the <application> tag
      const applicationTagPattern = r'<application[^>]*>';
      final match = RegExp(applicationTagPattern).firstMatch(content);

      if (match != null) {
        // Insert the <meta-data> tag after the <application> tag
        final insertionIndex = match.end;
        final metaDataTag = '''
        <meta-data
            android:name="com.google.android.geo.API_KEY"
            android:value="$apiKey"/>
      ''';
        final updatedContent = content.replaceRange(
          insertionIndex,
          insertionIndex,
          '\n$metaDataTag',
        );

        // Write the updated content back to the file
        await manifestFile.writeAsString(updatedContent);
        print("Google Maps API key added to AndroidManifest.xml.");
      } else {
        print("<application> tag not found in AndroidManifest.xml.");
      }
    } else {
      print("AndroidManifest.xml file not found at $androidManifestPath.");
    }
  }

  // iOS Configuration
  void updateIOSPlist(String projectPath, String apiKey) async {
    final plistPath = '$projectPath/ios/Runner/Info.plist';
    final plistFile = File(plistPath);

    if (plistFile.existsSync()) {
      String content = await plistFile.readAsString();
      if (!content.contains('<key>GMSApiKey</key>')) {
        final apiKeyEntry = '''
      <key>GMSApiKey</key>
      <string>$apiKey</string>
      ''';
        content = content.replaceFirst('</dict>', '$apiKeyEntry\n     </dict>');
        await plistFile.writeAsString(content);
      }
    }
  }

  void updateAppDelegateSwift(String projectPath, String apiKey) async {
    final appDelegatePath = '$projectPath/ios/Runner/AppDelegate.swift';
    final appDelegateFile = File(appDelegatePath);

    if (appDelegateFile.existsSync()) {
      String content = await appDelegateFile.readAsString();

      // Check if the API key is already added
      if (content.contains('GMSServices.provideAPIKey')) {
        print("Google Maps API key is already present in AppDelegate.swift.");
        return;
      }

      // Locate the `didFinishLaunchingWithOptions` method
      const startPattern = r'override\s+func\s+application\([^)]*\)\s+->\s+Bool\s+\{';
      const endPattern =
          r'return\s+super\.application\(application,\s+didFinishLaunchingWithOptions:\s+launchOptions\)';
      final startMatch = RegExp(startPattern).firstMatch(content);
      final endMatch = RegExp(endPattern).firstMatch(content);

      if (startMatch != null && endMatch != null) {
        final insertionIndex = endMatch.start;
        final updatedContent = content.replaceRange(
          insertionIndex,
          insertionIndex,
          '\nGMSServices.provideAPIKey("$apiKey")\n',
        );

        // Write the updated content back to the file
        await appDelegateFile.writeAsString(updatedContent);
        print("Google Maps API key added to AppDelegate.swift.");
      } else {
        print("Could not locate the didFinishLaunchingWithOptions method.");
      }
    } else {
      print("AppDelegate.swift file not found at $appDelegatePath.");
    }
  }

  // Run Flutter Project
  void runFlutterProject(String projectPath) async {
    final result = await Process.run('flutter', ['run'], workingDirectory: projectPath);
    if (result.exitCode != 0) {
      print("Error running Flutter project: ${result.stderr}");
    }
  }

  // Add Google Maps Example
  void addGoogleMapDemo(String projectPath) async {
    final mainPath = '$projectPath/lib/main.dart';
    final mainFile = File(mainPath);

    if (mainFile.existsSync()) {
      await mainFile.writeAsString('''
    import 'package:flutter/material.dart';
    import 'package:google_maps_flutter/google_maps_flutter.dart';

    void main() => runApp(MyApp());

    class MyApp extends StatelessWidget {
      @override
      Widget build(BuildContext context) {
        return MaterialApp(
          home: Scaffold(
            appBar: AppBar(title: Text('Google Maps Demo')),
            body: GoogleMap(
              initialCameraPosition: CameraPosition(
                target: LatLng(37.7749, -122.4194),
                zoom: 12,
              ),
            ),
          ),
        );
      }
    }
    ''');
    }
  }
}
