import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:image/image.dart' as img;
import 'package:zypto/auth/google_auth.dart';
import 'package:video_compress/video_compress.dart';
import 'package:zypto/checkConnection/checkConnection.dart';
import 'package:zypto/components/top_right_popup.dart';
import 'package:video_player/video_player.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:zypto/theme/theme_proivider.dart';
import 'package:zypto/utils/googelDrive.dart';
import 'package:firebase_auth/firebase_auth.dart';

class VideoCompressPage extends StatefulWidget {
  const VideoCompressPage({super.key});

  @override
  State<VideoCompressPage> createState() => _VideoCompressPageState();
}

class _VideoCompressPageState extends State<VideoCompressPage> {
  final authService = AuthService();
  File? fileVideo;
  File? fileCompVideo;
  // File? thumbnail;
  // Uint8List? thumbnailBytes;
  double? sizeInMbBefore;
  double? sizeInMbAfter;
  bool isLoading = false;
  bool isCompLoading = false;
  VideoPlayerController? _controller;
  VideoPlayerController? _compController;
  int width = 0, height = 0;
  int compWidth = 0, compHeight = 0;
  double compressionProgress = 0.0;
  StreamSubscription<dynamic>? _progressSubscription;
  final drive = GoogleDrive();
  final checkConnection = CheckConnection();
  bool pageLoading = false;
  // bool isConnected = false;
  bool isSignedInWithGoogle = true;
  void checkStatus() async {
    bool signedIn = await authService.isUserSignedInWithGoogle();

    if (signedIn) {
      setState(() {
        isSignedInWithGoogle = true;
      });
    }
    setState(() {});
  }

  List qualityOptions = [
    'Default',
    'Low',
    'Medium',
    'High',
    '1280 X 720',
    '1920 X 1080',
    '640 X 480',
    '960 X 540',
  ];
  String selectedQuality = 'Default';
  Future pickVideo() async {
    setState(() {
      isLoading = true;
      fileVideo = null;
      fileCompVideo = null;
    });
    final status = await Permission.videos.status;
    if (!status.isGranted) {
      final result = await Permission.videos.request();
      if (!result.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Permission not granted, enable storage permission from settings',
            ),
          ),
        );
        setState(() {
          isLoading = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        openAppSettings();
        return;
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Permission granted')));
      }
    }

    final picker = ImagePicker();
    final pickedFile = await picker.pickVideo(source: ImageSource.gallery);
    if (pickedFile != null) {
      final _sizeInMbBefore =
          File(pickedFile.path).lengthSync() / (1024 * 1024);
      setState(() {
        fileVideo = File(pickedFile.path);
        sizeInMbBefore = double.parse(_sizeInMbBefore.toStringAsFixed(2));
      });
      _controller = await VideoPlayerController.file(fileVideo!);
      await _controller!.initialize();
      _controller!.play();

      setState(() {});
      width = _controller!.value.size.width.toInt();
      height = _controller!.value.size.height.toInt();
    }
    setState(() {
      isLoading = false;
    });
  }

  Future generateDimensions(File file) async {
    final bytes = await file.readAsBytes();
    final decodedImage = img.decodeImage(bytes);

    if (decodedImage != null) {
      final _width = decodedImage.width;
      final _height = decodedImage.height;
      setState(() {
        width = _width;
        height = _height;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    VideoCompress.compressProgress$.subscribe((progress) {
      if (!mounted) return;
      setState(() {
        compressionProgress = progress;
      });
    });
    checkStatus();
  }

  VideoQuality getVideoQuality(quality) {
    if (quality == 'Default') {
      return VideoQuality.DefaultQuality;
    } else if (quality == 'Low') {
      return VideoQuality.LowQuality;
    } else if (quality == 'Medium') {
      return VideoQuality.MediumQuality;
    } else if (quality == 'High') {
      return VideoQuality.HighestQuality;
    } else if (quality == '1280 X 720') {
      return VideoQuality.Res1280x720Quality;
    } else if (quality == '1920 X 1080') {
      return VideoQuality.Res1920x1080Quality;
    } else if (quality == '640 X 480') {
      return VideoQuality.Res640x480Quality;
    } else {
      return VideoQuality.Res960x540Quality;
    }
  }

  Future compressVideo() async {
    setState(() {
      isCompLoading = true;
      compressionProgress = 0.0;
      fileCompVideo = null;
    });
    checkStatus();
    final compressedVideo = await VideoCompress.compressVideo(
      fileVideo!.path,
      frameRate: 60,
      quality: getVideoQuality(selectedQuality),
    );
    if (compressedVideo != null) {
      setState(() {
        fileCompVideo = compressedVideo.file;

        isLoading = false;
        sizeInMbAfter = double.parse(
          (File(fileCompVideo!.path).lengthSync() / (1024 * 1024))
              .toStringAsFixed(2),
        );
        compWidth = compressedVideo.width!;
        compHeight = compressedVideo.height!;
        isCompLoading = false;
      });

      _compController = await VideoPlayerController.file(fileCompVideo!);
      await _compController!.initialize();
    }
    setState(() {
      if (isCompLoading) isCompLoading = false;
    });
  }

  Future<void> saveToGallery(File fileCompVideo) async {
    final mediaStore = MediaStore();
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isAndroid) {
      await MediaStore.ensureInitialized();
    }
    // List<Permission> permissions = [Permission.storage];
    // if ((await mediaStore.getPlatformSDKInt()) >= 33) {
    //   permissions.add(Permission.photos);
    // }
    // Map<Permission, PermissionStatus> statuses = await permissions.request();
    // bool allGranted = statuses.values.every((status) => status.isGranted);
    // if (!allGranted) {
    //   ScaffoldMessenger.of(
    //     context,
    //   ).showSnackBar(const SnackBar(content: Text('Permission not granted')));
    //   return;
    // }

    MediaStore.appFolder = "Zypto_Videos";
    final result = await mediaStore.saveFile(
      tempFilePath: fileCompVideo.path,
      dirType: DirType.video,
      relativePath: "Zypto_Videos",
      dirName: DirName.pictures,
    );

    if (result != null || result == "") {
      //  await mediaStore.scanFileWithIntent(result.savedFilePath!);
      print("Video saved successfully! $result");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Video saved successfully!")),
      );
    } else {
      print("Error saving video: ${result}");
    }
  }

  @override
  void dispose() {
    _controller?.dispose(); // Clean up
    _compController?.dispose();
    _progressSubscription?.cancel();
    VideoCompress.dispose();
    // Navigator.pop(context);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final isDark = Theme.of(context).brightness == Brightness.dark;
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
                      Text(
                        "Video Compress",
                        style: TextStyle(
                          fontSize: 30,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
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
                          onTap: pickVideo,
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
                                      : Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Text(
                              "Pick Video",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
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
                      if (fileVideo != null)
                        Container(
                          padding: const EdgeInsets.all(15),
                          height: 360,
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
                                "Original Video",

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
                              Column(
                                children: [
                                  if (fileVideo != null)
                                    Container(
                                      width: 300,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      // child: Image.file(
                                      //   thumbnail!,
                                      //   height: 185,
                                      //   width: 165,
                                      // ),
                                      child: _controller!.value.isInitialized
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                AspectRatio(
                                                  aspectRatio: _controller!
                                                      .value
                                                      .aspectRatio,
                                                  child: Container(
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: VideoPlayer(
                                                      _controller!,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  iconSize: 30,
                                                  icon: Icon(
                                                    _controller!.value.isPlaying
                                                        ? Icons.pause_circle
                                                        : Icons.play_circle,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (_controller!
                                                          .value
                                                          .isPlaying) {
                                                        _controller!.pause();
                                                      } else {
                                                        _controller!.play();
                                                      }
                                                    });
                                                  },
                                                ),
                                              ],
                                            )
                                          : Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black87,
                                              ),
                                            ),
                                    ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Dimensions: $width x $height px",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),

                                      Text(
                                        "Size: $sizeInMbBefore Mb",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceEvenly,
                                    children: [
                                      Text(
                                        "Select Quality",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                      DropdownButton<String>(
                                        value: selectedQuality,
                                        icon: const Icon(Icons.arrow_downward),
                                        elevation: 16,
                                        style: TextStyle(
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        underline: Container(
                                          height: 1,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedQuality = newValue!;
                                          });
                                        },
                                        items: qualityOptions
                                            .map<DropdownMenuItem<String>>((
                                              dynamic value,
                                            ) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            })
                                            .toList(),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (fileVideo != null)
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
                              await compressVideo();
                              // await checkInternetConnection();
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
                                "Compress Video",
                                style: TextStyle(
                                  color: isDark ? Colors.white : Colors.black87,
                                ),
                              ),
                            ),
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (isCompLoading)
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
                              "Compressing video...",
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                fontSize: 14,
                                color: isDark ? Colors.white70 : Colors.black54,
                              ),
                            ),
                          ],
                        ),

                      if (fileCompVideo != null)
                        Container(
                          padding: const EdgeInsets.all(15),
                          height: 332,
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
                                "Compressed Video",

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
                              Column(
                                children: [
                                  if (fileVideo != null)
                                    Container(
                                      width: 300,
                                      height: 180,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      // child: Image.file(
                                      //   thumbnail!,
                                      //   height: 185,
                                      //   width: 165,
                                      // ),
                                      child:
                                          _compController!.value.isInitialized
                                          ? Stack(
                                              alignment: Alignment.center,
                                              children: [
                                                AspectRatio(
                                                  aspectRatio: _compController!
                                                      .value
                                                      .aspectRatio,
                                                  child: Container(
                                                    height: 200,
                                                    decoration: BoxDecoration(
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            10,
                                                          ),
                                                    ),
                                                    child: VideoPlayer(
                                                      _compController!,
                                                    ),
                                                  ),
                                                ),
                                                IconButton(
                                                  iconSize: 30,
                                                  icon: Icon(
                                                    _compController!
                                                            .value
                                                            .isPlaying
                                                        ? Icons.pause_circle
                                                        : Icons.play_circle,
                                                    color: Colors.white
                                                        .withOpacity(0.7),
                                                  ),
                                                  onPressed: () {
                                                    setState(() {
                                                      if (_compController!
                                                          .value
                                                          .isPlaying) {
                                                        _compController!
                                                            .pause();
                                                      } else {
                                                        _compController!.play();
                                                      }
                                                    });
                                                  },
                                                ),
                                              ],
                                            )
                                          : Center(
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: isDark
                                                    ? Colors.white54
                                                    : Colors.black87,
                                              ),
                                            ),
                                    ),
                                  const SizedBox(height: 10),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Dimensions: $compHeight x $compWidth px",
                                        style: TextStyle(
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),

                                      Text(
                                        "Size: $sizeInMbAfter Mb",
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black87,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 20),
                      if (fileCompVideo != null)
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
                                onTap: () async {
                                  await saveToGallery(fileCompVideo!);

                                  setState(() {});
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
                                            'Internet disconnected!',
                                          ),
                                        ),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      pageLoading = true;
                                    });
                                    var response = await drive.upload(
                                      File(fileCompVideo!.path),
                                      "Zypto_Videos",
                                    );
                                    if (response == "Internet disconnected!") {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'No internet connection!',
                                          ),
                                        ),
                                      );
                                    }
                                    setState(() {
                                      pageLoading = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Video uploaded to Drive',
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
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
