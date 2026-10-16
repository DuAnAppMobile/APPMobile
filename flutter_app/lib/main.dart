import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import 'screens/welcome_screen.dart';
import 'theme/app_theme.dart';
import 'widgets/rpg_shell.dart';

void main() {
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(const EnglishRpgApp());
}

class EnglishRpgApp extends StatelessWidget {
  const EnglishRpgApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'English Quest',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
        value: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
          statusBarBrightness: Brightness.light,
          systemNavigationBarColor: AppColors.background,
          systemNavigationBarIconBrightness: Brightness.dark,
        ),
        child: RpgShell(child: child ?? const SizedBox()),
      ),
      home: const WelcomeScreen(),
    );
  }
}
