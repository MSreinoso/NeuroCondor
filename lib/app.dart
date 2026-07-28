import 'package:flutter/material.dart';

import 'ble/condor_ble_service.dart';
import 'data/local_progress_repository.dart';
import 'screens/home_screen.dart';
import 'screens/registration_screen.dart';

class NeuroCondorApp extends StatefulWidget {
  const NeuroCondorApp({super.key, required this.repository});
  final LocalProgressRepository repository;

  @override
  State<NeuroCondorApp> createState() => _NeuroCondorAppState();
}

class _NeuroCondorAppState extends State<NeuroCondorApp> {
  late final CondorBleService ble = CondorBleService();

  @override
  void initState() {
    super.initState();
    if (ble.isWebIos) ble.enableDemoMode();
  }

  @override
  void dispose() {
    ble.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const primary = Color(0xff0e5966);
    const secondary = Color(0xffe35d3f);
    const surface = Color(0xfffffbf2);
    final scheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: Brightness.light,
    ).copyWith(
      primary: primary,
      onPrimary: Colors.white,
      secondary: secondary,
      onSecondary: Colors.white,
      tertiary: const Color(0xffffb547),
      surface: surface,
      onSurface: const Color(0xff1d302f),
      primaryContainer: const Color(0xffd4ece8),
      secondaryContainer: const Color(0xffffd8ca),
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Neuro Cóndor',
      theme: ThemeData(
        colorScheme: scheme,
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xfff7f2e7),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xfff7f2e7),
          foregroundColor: Color(0xff173f4b),
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: Color(0xff173f4b),
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: surface,
          indicatorColor: scheme.primaryContainer,
          labelTextStyle: WidgetStateProperty.resolveWith(
            (states) => TextStyle(
              fontWeight: states.contains(WidgetState.selected)
                  ? FontWeight.w800
                  : FontWeight.w600,
            ),
          ),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          margin: EdgeInsets.zero,
          color: surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: const TextStyle(fontWeight: FontWeight.w800),
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: surface,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: Color(0xffd9d3c5)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
        ),
      ),
      home: AnimatedBuilder(
        animation: widget.repository,
        builder: (context, _) => widget.repository.profile == null
            ? RegistrationScreen(repository: widget.repository)
            : HomeScreen(repository: widget.repository, ble: ble),
      ),
    );
  }
}
