import 'dart:convert';
import 'dart:io';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:crypto/crypto.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:media_store_plus/media_store_plus.dart';
import 'package:zypto/auth/google_auth.dart';
import 'package:zypto/components/top_right_popup.dart';

class EncryptFileScreen extends StatefulWidget {
  const EncryptFileScreen({super.key});

  @override
  State<EncryptFileScreen> createState() => _EncryptFileScreenState();
}

class _EncryptFileScreenState extends State<EncryptFileScreen> {
  final authService = AuthService();
  final TextEditingController _passwordController = TextEditingController();
  File? pickedFile;
  File? _encryptedFile;
  File? _decryptedFile;
  bool _obscurePassword = true;
  bool pageLoading = false;
  // void requestPermission() async {
  //   final mediaStore = MediaStore();
  //   final androidSdk = await mediaStore.getPlatformSDKInt();
  //   if (androidSdk > 33) {
  //     final status = await Permission.photos.status;
  //     if (!status.isGranted) {
  //       final result = await Permission.photos.request();
  //       if (!result.isGranted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text(
  //               'Permission not granted, enable storage permission from settings',
  //             ),
  //           ),
  //         );

  //         await Future.delayed(const Duration(seconds: 2));
  //         openAppSettings();
  //         return;
  //       } else {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Permission granted')));
  //       }
  //     }
  //   } else {
  //     final status = await Permission.storage.status;
  //     if (!status.isGranted) {
  //       final result = await Permission.storage.request();
  //       if (!result.isGranted) {
  //         ScaffoldMessenger.of(context).showSnackBar(
  //           const SnackBar(
  //             content: Text(
  //               'Permission not granted, enable storage permission from settings',
  //             ),
  //           ),
  //         );
  //         await Future.delayed(const Duration(seconds: 2));
  //         openAppSettings();
  //         return;
  //       } else {
  //         ScaffoldMessenger.of(
  //           context,
  //         ).showSnackBar(const SnackBar(content: Text('Permission granted')));
  //       }
  //     }
  //   }
  // }

  AssetImage setImage(file) {
    if (file!.absolute.path.endsWith('.jpg') ||
        file!.absolute.path.endsWith('.jpeg') ||
        file!.absolute.path.endsWith('.png')) {
      return AssetImage("assets/img.png");
    } else if (file!.absolute.path.endsWith('.pdf')) {
      return AssetImage("assets/pdf.png");
    } else if (file!.absolute.path.endsWith('.doc') ||
        file!.absolute.path.endsWith('.docx')) {
      return AssetImage("assets/doc.png");
    } else if (file!.absolute.path.endsWith('.txt')) {
      return AssetImage("assets/file.png");
    } else if (file!.absolute.path.endsWith('.mp4')) {
      return AssetImage("assets/video.png");
    } else if (file!.absolute.path.endsWith('.xls') ||
        file!.absolute.path.endsWith('.xlsx')) {
      return AssetImage("assets/xls.png");
    } else if (file!.absolute.path.endsWith('.ppt') ||
        file!.absolute.path.endsWith('.pptx')) {
      return AssetImage("assets/ppt.png");
    } else if (file!.absolute.path.endsWith('.enc')) {
      return AssetImage("assets/secure.png");
    } else {
      return AssetImage("assets/file.png");
    }
  }

  void pickFile() async {
    setState(() {
      pickedFile = null;
      _encryptedFile = null;
      _decryptedFile = null;
      _passwordController.clear();
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
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowMultiple: false,
      allowedExtensions: [
        'jpg',
        'jpeg',
        'png',
        'pdf',
        'doc',
        'docx',
        'txt',
        'mp4',
        'enc',
        'bin',
      ],
    );

    if (result != null) {
      setState(() {
        pickedFile = File(result.files.single.path!);
      });
    }
  }

  Future<File> encryptedFile(File file, String password) async {
    final bytes = await file.readAsBytes();

    final key = encrypt.Key(
      Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes),
    );

    final iv = encrypt.IV.fromSecureRandom(16); // Random IV
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    final encrypted = encrypter.encryptBytes(bytes, iv: iv);
    final output = iv.bytes + encrypted.bytes; // Prepend IV to ciphertext
    final tempDir = Directory('/data/user/0/com.example.zypto/cache');

    if (!await tempDir.exists()) {
      await tempDir.create(recursive: true);
    }
    final fileName = file.path.split('/').last;
    final tempFile = File('${tempDir.path}/$fileName.enc');
    await tempFile.writeAsBytes(output);
    setState(() {
      _encryptedFile = tempFile;
    });
    return tempFile;
  }

  Future<void> saveFile(File file) async {
    final mediaStore = MediaStore();
    WidgetsFlutterBinding.ensureInitialized();
    if (Platform.isAndroid) {
      await MediaStore.ensureInitialized();
    }
    MediaStore.appFolder = "Zypto_Secure";
    final result = await mediaStore.saveFile(
      tempFilePath: file.path,
      dirName: DirName.download,
      dirType: DirType.download,
      relativePath: 'Zypto_Secure',
    );
    print('✅ Encrypted file saved successfully! $result');
  }

  Future<File> decryptedFile(File encryptedFile, String password) async {
    print('password: $password');
    final encryptedData = await encryptedFile.readAsBytes();

    final key = encrypt.Key(
      Uint8List.fromList(sha256.convert(utf8.encode(password)).bytes),
    );
    final iv = encrypt.IV(encryptedData.sublist(0, 16));
    final encryptedBytes = encryptedData.sublist(16);

    final encrypter = encrypt.Encrypter(encrypt.AES(key));

    try {
      final decrypted = encrypter.decryptBytes(
        encrypt.Encrypted(encryptedBytes),
        iv: iv,
      );

      final tempDir = Directory('/data/user/0/com.example.zypto/cache');
      if (!await tempDir.exists()) {
        await tempDir.create(recursive: true);
      }
      final fileName = encryptedFile.path.split('/').last.split('.enc')[0];
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(decrypted);
      setState(() {
        _decryptedFile = tempFile;
      });
      if (await encryptedFile.exists()) {
        print('Deleting file at: ${encryptedFile.path}');

        await encryptedFile.delete();
        print('Encrypted file deleted successfully.');
      } else {
        print('Encrypted file not found for deletion.');
      }
      return tempFile;
    } catch (e) {
      print("error in decryption" + e.toString());
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password is incorrect')));
      return File('');
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                            const Color.fromARGB(255, 253, 235, 215),
                            const Color.fromARGB(255, 255, 255, 255),
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
                        "Zypto Secure",
                        style: TextStyle(
                          fontSize: 28,
                          color: isDark ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      Material(
                        borderRadius: BorderRadius.circular(15),
                        elevation: 1.5,
                        child: InkWell(
                          splashColor: isDark ? Colors.white24 : Colors.black26,
                          highlightColor: isDark
                              ? Colors.white10
                              : Colors.black12,
                          borderRadius: BorderRadius.circular(15),
                          onTap: pickFile,
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
                              "Pick File",
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 10),
                      if (pickedFile != null)
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
                                "Picked File",
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

                              // Image(image: FileImage(pickedFile!), height: 100),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,

                                children: [
                                  Image(
                                    image: setImage(pickedFile),
                                    height: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(
                                      pickedFile!.absolute.path.split('/').last,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 20),
                              Container(
                                child: Column(
                                  children: [
                                    Text(
                                      "Enter Password",
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                      textAlign: TextAlign.start,
                                    ),
                                    const SizedBox(height: 10),
                                    TextField(
                                      controller: _passwordController,
                                      obscureText: _obscurePassword,
                                      decoration: InputDecoration(
                                        icon: Icon(
                                          Icons.password,
                                          color: isDark
                                              ? Colors.white30
                                              : Colors.black87,
                                        ),
                                        filled: true,
                                        fillColor: isDark
                                            ? Colors.white.withOpacity(0.05)
                                            : Colors.black87.withOpacity(0.05),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide(
                                            color: Colors.white30,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                            15,
                                          ),
                                          borderSide: BorderSide(
                                            color: isDark
                                                ? Colors.white70
                                                : Colors.black87,
                                          ),
                                        ),
                                        labelText: 'Password',
                                        labelStyle: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w900,
                                          color: isDark
                                              ? Colors.white30
                                              : Colors.black87,
                                        ),
                                        suffixIcon: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              _obscurePassword =
                                                  !_obscurePassword;
                                            });
                                          },
                                          icon: Icon(
                                            _obscurePassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                          ),
                                        ),
                                      ),
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                        fontSize: 15,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
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
                                        setState(() {
                                          pageLoading = true;
                                        });
                                        var response = await encryptedFile(
                                          pickedFile!,
                                          _passwordController.text,
                                        );
                                        setState(() {
                                          pageLoading = false;
                                        });
                                        print("path: " + response.path);
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white.withOpacity(0.8),
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
                                          "Encrypt",
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
                                          : Colors
                                                .black26, // splash effect color
                                      highlightColor: isDark
                                          ? Colors.white10
                                          : Colors
                                                .black12, // pressed-down color
                                      borderRadius: BorderRadius.circular(15),
                                      onTap: () {
                                        setState(() {
                                          pageLoading = true;
                                        });
                                        var response = decryptedFile(
                                          pickedFile!,
                                          _passwordController.text,
                                        );
                                        setState(() {
                                          pageLoading = false;
                                        });
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 10,
                                          horizontal: 20,
                                        ),
                                        decoration: BoxDecoration(
                                          color: isDark
                                              ? Colors.white.withOpacity(0.05)
                                              : Colors.white.withOpacity(0.8),
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
                                          "Decrypt",
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
                              // const SizedBox(height: 20),
                            ],
                          ),
                        ),
                      const SizedBox(height: 30),
                      if (_encryptedFile != null)
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
                                "Encrypted File",
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

                              // Image(image: FileImage(pickedFile!), height: 100),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,

                                children: [
                                  Image(
                                    image: setImage(_encryptedFile!),
                                    height: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(
                                      _encryptedFile!.absolute.path
                                          .split('/')
                                          .last,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
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
                                  onTap: () {
                                    saveFile(_encryptedFile!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'File saved successfully in Downloads!',
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
                            ],
                          ),
                        ),
                      if (_decryptedFile != null)
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
                                "Decrypted File",
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

                              // Image(image: FileImage(pickedFile!), height: 100),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceEvenly,

                                children: [
                                  Image(
                                    image: setImage(_decryptedFile),
                                    height: 40,
                                  ),
                                  const SizedBox(width: 10),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width * 0.7,
                                    child: Text(
                                      _decryptedFile!.absolute.path
                                          .split('/')
                                          .last,
                                      style: TextStyle(
                                        color: isDark
                                            ? Colors.white
                                            : Colors.black87,
                                      ),
                                    ),
                                  ),
                                ],
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
                                  onTap: () {
                                    saveFile(_decryptedFile!);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'File saved successfully in Downloads!',
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
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
