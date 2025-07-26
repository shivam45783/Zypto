import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
// import 'package:provider/provider.dart';
import 'package:zypto/auth/google_auth.dart';
import 'package:zypto/components/featureCard.dart';
import 'package:zypto/components/top_right_popup.dart';
// import 'package:zypto/theme/theme_proivider.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});
  final authService = AuthService();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 35,
        title: Text(
          "Welcome, ${user!.displayName}",
          style: TextStyle(
            color: isDark ? Colors.white : Colors.black87,
            fontSize: 15,
          ),
        ),

        actions: [
          // Padding(
          //   padding: const EdgeInsets.only(right: 15),
          //   child: GestureDetector(
          //     onTap: () => Provider.of<ThemeProvider>(
          //       context,
          //       listen: false,
          //     ).toggleTheme(),
          //     child: Icon(
          //       Provider.of<ThemeProvider>(context).appThemeMode ==
          //               AppThemeMode.system
          //           ? Icons.computer
          //           : Provider.of<ThemeProvider>(context).appThemeMode ==
          //                 AppThemeMode.light
          //           ? Icons.light_mode
          //           : Icons.dark_mode,
          //       color: isDark ? Colors.white : Colors.black87,
          //     ),
          //   ),
          // ),
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
        child: Container(
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
                      const Color.fromARGB(255, 255, 255, 255), // pure white
                    ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 30),
                Image(
                  image: isDark
                      ? AssetImage('assets/splash/splash_icon.png')
                      : AssetImage('assets/icon/app_icon.png'),
                  width: 120,
                ),
                // const SizedBox(height: 30),
                Text(
                  'Zypto',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                Text(
                  "Smash That File Size!",
                  style: TextStyle(
                    fontSize: 20,
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Divider(
                  color: isDark ? Colors.white : Colors.black87,
                  height: 2,
                  thickness: 0.3,
                  indent: 20,
                  endIndent: 20,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FeatureCard(
                        animationPath: "assets/animation/single.json",
                        label: "Single Image Compress ",
                        onTap: () =>
                            Navigator.pushNamed(context, '/singleCompress'),
                        isDark: isDark,
                      ),
                      FeatureCard(
                        animationPath: "assets/animation/multiple.json",
                        label: "Bulk Image Compress",
                        onTap: () =>
                            Navigator.pushNamed(context, '/bulkCompress'),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      FeatureCard(
                        animationPath: "assets/animation/video.json",
                        label: "Video Compress",
                        onTap: () =>
                            Navigator.pushNamed(context, '/videoCompress'),
                        isDark: isDark,
                      ),
                      FeatureCard(
                        animationPath: "assets/animation/secure.json",
                        label: "Zypto Secure",
                        onTap: () =>
                            Navigator.pushNamed(context, '/encryptScreen'),
                        isDark: isDark,
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
