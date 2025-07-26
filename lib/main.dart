import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:zypto/screens/bulk_compress.dart';
import 'package:zypto/screens/encrypt_file_screen.dart';
import 'package:zypto/screens/get_started_screen.dart';
import 'package:zypto/screens/home_screen.dart';
import 'package:zypto/screens/sign_in_screen.dart';
import 'package:zypto/screens/sign_up_screen.dart';
import 'package:zypto/screens/single_compress.dart';
import 'package:zypto/screens/video_compress.dart';
// import 'package:zypto/theme/theme.dart';
import 'package:zypto/theme/theme_proivider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:zypto/firebase_options.dart';
import 'package:firebase_auth/firebase_auth.dart';
// import 'theme/theme.dart';

// import 'package:zypto/screens/sign_up_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(
    ChangeNotifierProvider(
      create: (context) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    // final isDark = themeProvider.themeData.brightness == Brightness.dark;

    // SystemChrome.setSystemUIOverlayStyle(
    //   SystemUiOverlayStyle(
    //     statusBarColor: isDark
    //         ? const Color.fromARGB(255, 54, 54, 54)
    //         : const Color.fromARGB(255, 253, 235, 215),
    //     statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
    //   ),
    // );

    return MaterialApp(
      routes: {
        "/getStarted": (context) => const GetStartedScreen(),
        "/signUp": (context) => const SignUpScreen(),
        "/signIn": (context) => const SignInScreen(),
        "/singleCompress": (context) => const SingleCompress(),
        "/bulkCompress": (context) => const BulkCompress(),
        "/home": (context) => HomeScreen(),
        "/videoCompress": (context) => const VideoCompressPage(),
        "/encryptScreen": (context) => const EncryptFileScreen(),
      },
      title: 'Zypto',
      debugShowCheckedModeBanner: false,
      theme: themeProvider.themeData,
      // theme: lightMode,
      // darkTheme: darkMode,
      // themeMode: ThemeMode.system,
      // home: const GetStartedScreen(),
      home: StreamBuilder(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return HomeScreen();
          } else {
            return const GetStartedScreen();
          }
        },
      ),
    );
  }
}
