import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:image/image.dart' as img;
import 'package:zypto/auth/google_auth.dart';
import 'package:zypto/utils/googelDrive.dart';
import 'package:zypto/components/top_right_popup.dart';
import 'package:zypto/checkConnection/checkConnection.dart';

class SingleCompress extends StatefulWidget {
  const SingleCompress({super.key});

  @override
  State<SingleCompress> createState() => _SingleCompressState();
}

class _SingleCompressState extends State<SingleCompress> {
  final authService = AuthService();
  File? fileImage;
  XFile? compressedImage;
  int sizeInKbAfter = 0;
  int sizeInKbBefore = 0;
  int width = 0;
  int height = 0;
  int compWidth = 0;
  int compHeight = 0;
  final qualityController = TextEditingController(text: "70");
  bool pageLoading = false;
  final accessToken = AuthService().accessToken;
  final drive = GoogleDrive();
  final checkConnection = CheckConnection();
  // bool isConnected = false;
  bool isSignedInWithGoogle = false;

  Future<void> checkStatus() async {
    // bool connected = await checkConnection.isConnectedToInternet();
    bool signedIn = await authService.isUserSignedInWithGoogle();

    print('signedIn: $signedIn');

    if (signedIn) {
      setState(() {
        isSignedInWithGoogle = true;
      });
    }
    setState(() {});
  }

  void requestPermission() async {
    final mediaStore = MediaStore();
    final androidSdk = await mediaStore.getPlatformSDKInt();
    if (androidSdk > 33) {
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
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
  }

  void pickImage() async {
    setState(() {
      fileImage = null;
      compressedImage = null;
    });
    // requestPermission();
    final mediaStore = MediaStore();
    final androidSdk = await mediaStore.getPlatformSDKInt();
    if (androidSdk > 33) {
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
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

    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
    );

    if (pickedFile != null) {
      setState(() {
        fileImage = File(pickedFile.path);
      });
      await getImageDimensions(fileImage!);
      print('Image dimensions: $width x $height');
      final _sizeInKbBefore = fileImage!.lengthSync() / 1024;
      setState(() {
        sizeInKbBefore = _sizeInKbBefore.toInt();
      });
      print('Size in KB before compression: $_sizeInKbBefore');
    }
  }

  void pickFromCamera() async {
    setState(() {
      fileImage = null;
      compressedImage = null;
    });
    // requestPermission();

    final mediaStore = MediaStore();
    final androidSdk = await mediaStore.getPlatformSDKInt();
    if (androidSdk > 33) {
      final status = await Permission.photos.status;
      if (!status.isGranted) {
        final result = await Permission.photos.request();
        if (!result.isGranted) {
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
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.camera,
    );
    if (pickedFile != null) {
      setState(() {
        fileImage = File(pickedFile.path);
      });
      await getImageDimensions(fileImage!);
      print('Image dimensions: $width x $height');
      final _sizeInKbBefore = fileImage!.lengthSync() / 1024;
      setState(() {
        sizeInKbBefore = _sizeInKbBefore.toInt();
      });
      print('Size in KB before compression: $_sizeInKbBefore');
    }
  }

  Future<void> getImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage != null) {
      final _width = decodedImage.width;
      final _height = decodedImage.height;
      setState(() {
        width = _width;
        height = _height;
      });
      // print('Image dimensions: $width x $height');
    }
  }

  Future<void> getCompImageDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage != null) {
      final _width = decodedImage.width;
      final _height = decodedImage.height;
      setState(() {
        compWidth = _width;
        compHeight = _height;
      });
      // print('Image dimensions: $width x $height');
    }
  }

  Future<XFile> customCompressedImage({
    required File imagePathToCompress,
    quality = 70,
  }) async {
    if (quality > 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quality cannot be greater than 100')),
      );
      return XFile('');
    }
    var path = imagePathToCompress.path;
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
      await getCompImageDimensions(File(result.path));
      print('Image dimensions after compression: $compWidth x $compHeight');
      final _sizeInKbAfter = File(result.path).lengthSync() / 1024;
      setState(() {
        sizeInKbAfter = _sizeInKbAfter.toInt();
      });
      print('Size in KB after compression: $_sizeInKbAfter');
      return result;
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Compression failed')));
      return result!;
    }
  }

  Future<void> saveToGallery(XFile compressedImage) async {
    final mediaStore = MediaStore();
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isAndroid) {
      await MediaStore.ensureInitialized();
    }

    final file = File(compressedImage.path);
    MediaStore.appFolder = "Zypto_Images";
    final result = await mediaStore.saveFile(
      tempFilePath: file.path,
      dirType: DirType.photo,
      relativePath: "Zypto_Images",
      dirName: DirName.pictures,
    );

    if (result != null || result == "") {
      print("Image saved successfully! $result");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Image saved successfully!")),
      );
    } else {
      print("Error saving image: ${result}");
    }
  }

  @override
  void initState() {
    super.initState();
    // checkInternetConnection();
    checkStatus();
  }

  // Future<void> checkInternetConnection() async {
  //   bool result = await checkConnection.isConnectedToInternet();
  //   setState(() {
  //     isConnected = result;
  //   });
  // }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 35,

        actions: [
          IconButton(
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
        /*
pageLoading
            ? const Center(child: CircularProgressIndicator())
            : 
*/
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
                        "Single Image Compress",
                        style: TextStyle(
                          fontSize: 28,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
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
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.8),
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
                              onTap: pickFromCamera,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 10,
                                  horizontal: 20,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.white.withOpacity(0.8),
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
                                  "Click from camera",
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
                      const SizedBox(height: 10),

                      if (fileImage != null)
                        Container(
                          padding: const EdgeInsets.all(15),
                          // height: 240,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withOpacity(0.05)
                                : Colors.white.withOpacity(0.2),
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
                          child: Column(
                            children: [
                              Text(
                                "Original Image",

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
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.file(
                                      fileImage!,
                                      height: 185,
                                      width: 165,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Width: $width px",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Height: $height px",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Size: $sizeInKbBefore KB",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              TextField(
                                controller: qualityController,
                                keyboardType: TextInputType.number,
                                cursorColor: isDark
                                    ? Colors.white
                                    : Colors.black87,
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  icon: Icon(
                                    Icons.high_quality,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black87,
                                  ),
                                  filled: true,
                                  fillColor: isDark
                                      ? Colors.white.withOpacity(0.05)
                                      : Colors.black87.withOpacity(0.05),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.white12
                                          : Colors.black12,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: isDark
                                          ? Colors.white70
                                          : Colors.black87,
                                    ),
                                  ),
                                  labelText: 'Quality',
                                  labelStyle: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    color: isDark
                                        ? Colors.white30
                                        : Colors.black87,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
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
                                    compressedImage =
                                        await customCompressedImage(
                                          imagePathToCompress: fileImage!,
                                          quality: int.parse(
                                            qualityController.text,
                                          ),
                                        );
                                    // await checkInternetConnection();
                                    await checkStatus();
                                    setState(() {});
                                  },
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
                                      "Compress Image",
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
                        ),
                      const SizedBox(height: 20),
                      if (compressedImage != null)
                        Container(
                          padding: const EdgeInsets.all(15),
                          // height: 240,
                          alignment: Alignment.center,
                          margin: const EdgeInsets.symmetric(horizontal: 12),
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
                          child: Column(
                            children: [
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
                              Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Image.file(
                                      File(compressedImage!.path),
                                      height: 185,
                                      width: 165,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Width: $compWidth px",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Height: $compHeight px",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      Text(
                                        "Size: $sizeInKbAfter KB",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,
                                children: [
                                  Material(
                                    borderRadius: BorderRadius.circular(15),
                                    elevation: 1.5,
                                    child: InkWell(
                                      splashColor: isDark
                                          ? Colors.white24
                                          : Colors
                                                .black26, // splash effect color
                                      highlightColor: isDark
                                          ? Colors.white10
                                          : Colors
                                                .black12, // pressed-down color
                                      borderRadius: BorderRadius.circular(15),
                                      onTap: () async {
                                        await saveToGallery(compressedImage!);

                                        setState(() {});
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.4),

                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          border: Border.all(
                                            color: isDark
                                                ? Colors.white.withOpacity(0.1)
                                                : Colors.black.withOpacity(0.1),
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: isDark
                                                  ? Colors.white.withOpacity(
                                                      0.05,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.1,
                                                    ),
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
                                            : Colors
                                                  .black26, // splash effect color
                                        highlightColor: isDark
                                            ? Colors.white10
                                            : Colors
                                                  .black12, // pressed-down color
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
                                                  'No internet connection!',
                                                ),
                                              ),
                                            );
                                            return;
                                          }
                                          setState(() {
                                            pageLoading = true;
                                          });
                                          var response = await drive.upload(
                                            File(compressedImage!.path),
                                            "Zypto_Images",
                                          );
                                          if (response ==
                                              "Internet disconnected!") {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                  'Internet disconnected!',
                                                ),
                                              ),
                                            );
                                          }
                                          setState(() {
                                            pageLoading = false;
                                          });
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
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
                                            color: Colors.green.withOpacity(
                                              0.4,
                                            ),
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                            border: Border.all(
                                              color: isDark
                                                  ? Colors.white.withOpacity(
                                                      0.1,
                                                    )
                                                  : Colors.black.withOpacity(
                                                      0.1,
                                                    ),
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: isDark
                                                    ? Colors.white.withOpacity(
                                                        0.05,
                                                      )
                                                    : Colors.black.withOpacity(
                                                        0.1,
                                                      ),
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
                            ],
                          ),
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
