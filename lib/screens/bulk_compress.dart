import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:image/image.dart' as img;
import 'package:zypto/auth/google_auth.dart';
import 'package:zypto/checkConnection/checkConnection.dart';
import 'package:zypto/components/compressed_image_card.dart';
import 'package:zypto/components/input_image_card.dart';
import 'package:zypto/utils/googelDrive.dart';
import 'package:zypto/components/top_right_popup.dart';
import 'package:googleapis/drive/v3.dart' as ga;
import 'package:path/path.dart' as path;

class BulkCompress extends StatefulWidget {
  const BulkCompress({super.key});

  @override
  State<BulkCompress> createState() => _BulkCompressState();
}

class _BulkCompressState extends State<BulkCompress> {
  final authService = AuthService();
  File? fileImage;
  XFile? compressedImage;
  int sizeInKbAfter = 0;
  int sizeInKbBefore = 0;
  int width = 0;
  int height = 0;
  int compWidth = 0;
  int compHeight = 0;
  List<Map<String, dynamic>> _imageFiles = [];
  List<Map<String, dynamic>> _compresedFiles = [];
  bool isLoading = false;
  bool isCompLoading = false;
  double compressionProgress = 0.0;
  final checkConnection = CheckConnection();
  bool isConnected = false;
  final qualityController = TextEditingController(text: "70");
  final drive = GoogleDrive();
  bool pageLoading = false;
  bool isSignedInWithGoogle = false;
  Future<void> checkStatus() async {
    bool signedIn = await authService.isUserSignedInWithGoogle();

    if (signedIn) {
      setState(() {
        isSignedInWithGoogle = true;
      });
    }
    setState(() {});
  }

  void removeImages() {
    for (var image in _imageFiles) {
      (image['qualityController'] as TextEditingController).dispose();
    }
    setState(() {
      _imageFiles.clear();
      _compresedFiles.clear();
    });
  }

  @override
  void initState() {
    super.initState();
    checkStatus();
  }

  void pickImage() async {
    setState(() {
      isLoading = true;
    });
    final mediaStore = MediaStore();
    final androidSdk = await mediaStore.getPlatformSDKInt();
    if (androidSdk > 33) {
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission not granted, enable storage permission from settings',
              ),
            ),
          );

          await Future.delayed(const Duration(seconds: 2));
          openAppSettings();

          return;
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Permission granted')));
        }
      }
    } else {
      final status = await Permission.storage.status;
      if (!status.isGranted) {
        final result = await Permission.storage.request();
        if (!result.isGranted) {
          setState(() {
            isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Permission not granted, enable storage permission from settings',
              ),
            ),
          );
          await Future.delayed(const Duration(seconds: 2));
          openAppSettings();

          return;
        } else {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Permission granted')));
        }
      }
    }
    final ImagePicker picker = ImagePicker();
    final List<XFile>? images = await picker.pickMultiImage();
    if (images == null || images.isEmpty) {
      setState(() {
        isLoading = false;
      });
      return;
    }
    if (images == null) return;

    for (var xFile in images) {
      final file = File(xFile.path);
      final bytes = await file.readAsBytes();
      final decodedImage = img.decodeImage(bytes);
      final sizeInKb = file.lengthSync() / 1024;
      TextEditingController qualityController = TextEditingController(
        text: "70",
      );
      qualityController.addListener(() {
        setState(() {}); // Triggers rebuild on text change
      });
      if (decodedImage != null) {
        _imageFiles.add({
          'file': file,
          'width': decodedImage.width,
          'height': decodedImage.height,
          'sizeInKbBefore': sizeInKb.toInt(),
          'qualityController': qualityController,
        });
      }
    }

    setState(() {
      isLoading = false;
    });
  }

  @override
  void dispose() {
    for (var image in _imageFiles) {
      (image['qualityController'] as TextEditingController).dispose();
    }
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> customCompressedImage() async {
    setState(() {
      isCompLoading = true;
      _compresedFiles.clear();
    });
    for (var image in _imageFiles) {
      File file = image['file'];
      // int width = imageFiles['width'];
      // int height = imageFiles['height'];
      // int size = imageFiles['sizeInKbBefore'];
      int quality = int.parse(image['qualityController'].text);
      var path = file.path;
      var time = DateTime.now().millisecondsSinceEpoch;
      final String basePath = path.replaceAll(
        RegExp(r'\.(jpg|jpeg|png)$', caseSensitive: false),
        '',
      );
      final String newPath = '${basePath}_$time.zypto_compressed.jpg';
      var result = await FlutterImageCompress.compressAndGetFile(
        path,
        newPath,
        quality: quality,
      );
      if (result != null) {
        File compFile = File(result.path);
        final bytes = await compFile.readAsBytes();
        final decodedImage = img.decodeImage(bytes);
        final sizeInKb = compFile.lengthSync() / 1024;

        setState(() {
          _compresedFiles.add({
            'file': compFile,
            'width': decodedImage!.width,
            'height': decodedImage.height,
            'sizeInKbAfter': sizeInKb.toInt(),
          });
          if (_imageFiles.isNotEmpty && _compresedFiles.isNotEmpty) {
            compressionProgress =
                (_compresedFiles.length / _imageFiles.length) * 100;
          } else {
            compressionProgress = 0;
          }
        });
      }
    }
    setState(() {
      isCompLoading = false;
    });
    print("Compresed files: $_compresedFiles");
    return _compresedFiles;
  }

  Future<void> saveToGallery() async {
    final mediaStore = MediaStore();
    bool saved = false;
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isAndroid) {
      await MediaStore.ensureInitialized();
    }
    for (var compressedImage in _compresedFiles) {
      File file = compressedImage['file'];

      MediaStore.appFolder = "Zypto_Images";
      final result = await mediaStore.saveFile(
        tempFilePath: file.path,
        dirType: DirType.photo,
        relativePath: "Zypto_Images",
        dirName: DirName.pictures,
      );
      if (result != null || result == "") {
        print("Image saved successfully! $result");
        saved = true;
      } else {
        print("Error saving image: ${result}");
      }
    }
    if (saved) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Images saved successfully')),
      );
    }
  }

  Future<void> saveToDrive() async {
    
    var client = await drive.getClient();
    var drive1 = ga.DriveApi(client);

    final folderId = await drive.getOrCreateFolder("Zypto_Images");

    for (var compressedImage in _compresedFiles) {
      File file = compressedImage['file'];
      final fileMetadata = ga.File()
        ..name = path.basename(file.path)
        ..parents = [folderId];
      final media = ga.Media(file.openRead(), file.lengthSync());
      try {
        final response = await drive1.files.create(
          fileMetadata,
          uploadMedia: media,
        );
        print("Uploaded File ID: ${response.id}");
      } catch (e) {
        if (e is SocketException || e.toString().contains('SocketException')) {
          print("Internet disconnected!");

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No Internet connection!')),
          );
          return;
        } else {
          print("Upload failed: $e");
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 35,

        actions: [
          IconButton(
            // focusColor: Colors.transparent,
            // highlightColor: Colors.white,
            padding: EdgeInsets.all(8),
            icon: Icon(
              Icons.settings,
              color: isDark ? Colors.white : Colors.black87,
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => TopRightPopup(authService: authService),
              );
            },
          ),
        ],

        backgroundColor: isDark
            ? const Color.fromARGB(255, 54, 54, 54)
            : const Color.fromARGB(255, 253, 235, 215),
      ),
      body: SafeArea(
        child: pageLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                height: double.infinity,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isDark
                        ? [
                            const Color.fromARGB(255, 54, 54, 54),
                            const Color.fromARGB(255, 0, 0, 0),
                          ]
                        : [
                            const Color.fromARGB(
                              255,
                              253,
                              235,
                              215,
                            ), // soft light gray
                            const Color.fromARGB(
                              255,
                              255,
                              255,
                              255,
                            ), // pure white
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Text(
                        "Bulk Image Compress",
                        style: TextStyle(
                          fontSize: 30,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        spacing: 10,
                        children: [
                          Material(
                            borderRadius: BorderRadius.circular(15),
                            elevation: 1.5,
                            child: InkWell(
                              splashColor: isDark
                                  ? Colors.white24
                                  : Colors.black26, // splash effect color
                              highlightColor: isDark
                                  ? Colors.white10
                                  : Colors.black12, // pressed-down color
                              borderRadius: BorderRadius.circular(15),
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.1)
                                        : Colors.black.withOpacity(0.1),
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.05)
                                          : Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  "Pick from gallery",
                                  style: TextStyle(
                                    color: isDark
                                        ? Colors.white
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                            ),
                          ),

                          if (_imageFiles.isNotEmpty)
                            Material(
                              borderRadius: BorderRadius.circular(15),
                              elevation: 1.5,
                              child: InkWell(
                                splashColor: isDark
                                    ? Colors.white24
                                    : Colors.black26, // splash effect color
                                highlightColor: isDark
                                    ? Colors.white10
                                    : Colors.black12, // pressed-down color
                                borderRadius: BorderRadius.circular(15),
                                onTap: removeImages,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.white.withOpacity(0.3),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "Remove Images",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      if (isLoading)
                        SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: isDark ? Colors.white54 : Colors.black87,
                          ),
                        ),

                      if (_imageFiles.isNotEmpty)
                        Text(
                          "Original Images",
                          style: TextStyle(
                            decoration: TextDecoration.underline,
                            decorationColor: isDark
                                ? Colors.white
                                : Colors.black87,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),

                      const SizedBox(height: 10),
                      if (_imageFiles.isNotEmpty)
                        SizedBox(
                          height:
                              300, // or whatever height your InputImageCard needs
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _imageFiles.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: InputImageCard(
                                  isDark: isDark,
                                  fileImage: _imageFiles[index]['file'],
                                  width: _imageFiles[index]['width'],
                                  height: _imageFiles[index]['height'],
                                  sizeInKbBefore:
                                      _imageFiles[index]['sizeInKbBefore'],
                                  qualityController:
                                      _imageFiles[index]['qualityController'],
                                ),
                              );
                            },
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (_imageFiles.isNotEmpty)
                        Material(
                          borderRadius: BorderRadius.circular(15),
                          elevation: 1.5,
                          child: InkWell(
                            splashColor: isDark
                                ? Colors.white24
                                : Colors.black26, // splash effect color
                            highlightColor: isDark
                                ? Colors.white10
                                : Colors.black12, // pressed-down color
                            borderRadius: BorderRadius.circular(15),
                            onTap: customCompressedImage,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                vertical: 10,
                                horizontal: 20,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(15),
                                border: Border.all(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.1)
                                      : Colors.black.withOpacity(0.1),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: isDark
                                        ? Colors.white.withOpacity(0.05)
                                        : Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                "Compress",
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (isCompLoading) ...[
                        Column(
                          children: [
                            const SizedBox(height: 10),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 15,
                              ),
                              child: Stack(
                                alignment: Alignment.centerLeft,
                                children: [
                                  // Background track
                                  Container(
                                    height: 20,
                                    decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.white24
                                          : Colors.black12,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  // Progress fill
                                  Container(
                                    height: 20,
                                    width:
                                        MediaQuery.of(context).size.width *
                                        0.9 * // 90% width
                                        (compressionProgress /
                                            100), // dynamic width based on progress
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: isDark
                                            ? [
                                                Colors.blueAccent,
                                                Colors.lightBlueAccent,
                                              ]
                                            : [Colors.blue, Colors.cyan],
                                      ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  // Optional overlay text
                                  Center(
                                    child: Text(
                                      "${compressionProgress.toStringAsFixed(2)}%",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "Compressing images...",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                      ],

                      if (_compresedFiles.isNotEmpty) ...[
                        Text(
                          "Compressed Image",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                            decoration: TextDecoration.underline,
                            decorationColor: isDark
                                ? Colors.white
                                : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height:
                              300, // or whatever height your InputImageCard needs
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            itemCount: _compresedFiles.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: CompressedImageCard(
                                  isDark: isDark,
                                  compressedImage:
                                      _compresedFiles[index]['file'],
                                  compWidth: _compresedFiles[index]['width'],
                                  compHeight: _compresedFiles[index]['height'],
                                  sizeInKbAfter:
                                      _compresedFiles[index]['sizeInKbAfter'],
                                  qualityController:
                                      _imageFiles[index]['qualityController'],
                                ),
                              );
                            },
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),
                      if (_compresedFiles.isNotEmpty)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Material(
                              borderRadius: BorderRadius.circular(15),
                              elevation: 1.5,
                              child: InkWell(
                                splashColor: isDark
                                    ? Colors.white24
                                    : Colors.black26, // splash effect color
                                highlightColor: isDark
                                    ? Colors.white10
                                    : Colors.black12, // pressed-down color
                                borderRadius: BorderRadius.circular(15),
                                onTap: saveToGallery,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                    horizontal: 20,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.4),
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withOpacity(0.1)
                                          : Colors.black.withOpacity(0.1),
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black.withOpacity(0.1),
                                        blurRadius: 10,
                                        spreadRadius: 1,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "Save",
                                    style: TextStyle(
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black87,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            if (isSignedInWithGoogle)
                              Material(
                                borderRadius: BorderRadius.circular(15),
                                elevation: 1.5,
                                child: InkWell(
                                  splashColor: isDark
                                      ? Colors.white24
                                      : Colors.black26, // splash effect color
                                  highlightColor: isDark
                                      ? Colors.white10
                                      : Colors.black12, // pressed-down color
                                  borderRadius: BorderRadius.circular(15),
                                  onTap: () async {
                                    bool status = await checkConnection
                                        .isConnectedToInternet();
                                    if (!status) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No internet connection',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      pageLoading = true;
                                    });
                                    await saveToDrive();
                                    setState(() {
                                      pageLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Image uploaded to Drive',
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 10,
                                      horizontal: 20,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.withOpacity(0.4),
                                      borderRadius: BorderRadius.circular(15),
                                      border: Border.all(
                                        color: isDark
                                            ? Colors.white.withOpacity(0.1)
                                            : Colors.black.withOpacity(0.1),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.black.withOpacity(0.1),
                                          blurRadius: 10,
                                          spreadRadius: 1,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Row(
                                      children: [
                                        Image.asset(
                                          "assets/google-drive.png",
                                          width: 20,
                                          height: 20,
                                        ),
                                        const SizedBox(width: 5),
                                        Text(
                                          "Save to Drive",
                                          style: TextStyle(
                                            color: isDark
                                                ? Colors.white
                                                : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
