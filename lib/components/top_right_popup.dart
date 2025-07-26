import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:zypto/auth/google_auth.dart';
import 'package:zypto/theme/theme_proivider.dart';

class TopRightPopup extends StatelessWidget {
  final AuthService authService;

  const TopRightPopup({super.key, required this.authService});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Align(
      alignment: Alignment.topRight,
      child: Padding(
        padding: const EdgeInsets.only(top: 35),
        child: Material(
          elevation: 4,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            height: 200,
            width: 150,
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color.fromARGB(255, 54, 54, 54)
                  : const Color.fromARGB(255, 253, 235, 215),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                Text(
                  "Settings",
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Divider(
                  color: isDark ? Colors.white : Colors.black87,
                  height: 2,
                  thickness: 0.3,
                  // indent: 10,
                  // endIndent: 10,
                ),
                const SizedBox(height: 7),

                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Container(
                              alignment: Alignment.centerRight,
                              child:
                                  FirebaseAuth.instance.currentUser!.photoURL ==
                                      null
                                  ? const Icon(Icons.person)
                                  : CircleAvatar(
                                      radius: 14, // Half of 50
                                      backgroundImage: NetworkImage(
                                        FirebaseAuth
                                            .instance
                                            .currentUser!
                                            .photoURL
                                            .toString(),
                                      ),
                                    ),
                            ),
                          ),
                          Container(
                            width: 60,
                            child: Text(
                              FirebaseAuth.instance.currentUser!.displayName!,
                              style: TextStyle(
                                color: isDark ? Colors.white : Colors.black87,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 7),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      Provider.of<ThemeProvider>(
                        context,
                        listen: false,
                      ).toggleTheme();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.08)
                            : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(right: 10),
                            child: Icon(
                              themeProvider.appThemeMode == AppThemeMode.system
                                  ? Icons.computer
                                  : themeProvider.appThemeMode ==
                                        AppThemeMode.light
                                  ? Icons.light_mode
                                  : Icons.dark_mode,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          Text(
                            themeProvider.appThemeMode == AppThemeMode.system
                                ? "System"
                                : themeProvider.appThemeMode ==
                                      AppThemeMode.light
                                ? "Light"
                                : "Dark",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      authService.signOut();
                      Navigator.pushNamedAndRemoveUntil(
                        context,
                        "/getStarted",
                        (route) => false,
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.redAccent.withOpacity(0.8),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.logout,
                            color: isDark ? Colors.white : Colors.black87,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "Logout",
                            style: TextStyle(
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
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
