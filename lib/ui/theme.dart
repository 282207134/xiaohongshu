import 'dart:convert';

import 'package:flutter/material.dart';

const accent = Color(0xFFFF2D55);
const ink = Color(0xFF242429);
const muted = Color(0xFF909096);
const canvas = Color(0xFFF7F7F8);

ThemeData appTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: Colors.white,
  colorScheme: ColorScheme.fromSeed(
    seedColor: accent,
    primary: accent,
    surface: Colors.white,
  ),
  fontFamily: 'Microsoft YaHei',
  fontFamilyFallback: const ['PingFang SC', 'Noto Sans SC', 'sans-serif'],
  textTheme: const TextTheme(
    bodyMedium: TextStyle(color: ink, fontSize: 14, height: 1.5),
  ),
  appBarTheme: const AppBarTheme(
    backgroundColor: Colors.white,
    foregroundColor: ink,
    surfaceTintColor: Colors.transparent,
    centerTitle: true,
    elevation: 0,
    titleTextStyle: TextStyle(
      color: ink,
      fontSize: 17,
      fontWeight: FontWeight.w600,
    ),
  ),
  dividerColor: const Color(0xFFEEEEF0),
  iconButtonTheme: IconButtonThemeData(
    style: IconButton.styleFrom(foregroundColor: ink),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: accent,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      textStyle: const TextStyle(fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: canvas,
    hintStyle: const TextStyle(color: muted, fontSize: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
  ),
  snackBarTheme: SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
);

class AppImage extends StatelessWidget {
  const AppImage(
    this.source, {
    super.key,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });
  final String source;
  final BoxFit fit;
  final double? width, height;
  @override
  Widget build(BuildContext context) {
    Widget fallback(BuildContext c, Object e, StackTrace? s) => Container(
      color: canvas,
      width: width,
      height: height,
      child: const Center(
        child: Icon(Icons.image_not_supported_outlined, color: muted),
      ),
    );
    if (source.startsWith('data:')) {
      try {
        return Image.memory(
          base64Decode(source.split(',').last),
          fit: fit,
          width: width,
          height: height,
          errorBuilder: fallback,
          gaplessPlayback: true,
        );
      } catch (_) {
        return fallback(context, StateError('Invalid image'), null);
      }
    }
    return Image.asset(
      source,
      fit: fit,
      width: width,
      height: height,
      errorBuilder: fallback,
    );
  }
}

class Avatar extends StatelessWidget {
  const Avatar(this.source, {super.key, this.size = 32});
  final String source;
  final double size;
  @override
  Widget build(BuildContext context) => ClipOval(
    child: AppImage(source, width: size, height: size),
  );
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), duration: const Duration(seconds: 2)),
  );
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.auto_awesome_outlined,
    this.action,
  });
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: canvas,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 36, color: muted),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(color: muted),
          ),
          if (action != null)
            Padding(padding: const EdgeInsets.only(top: 20), child: action),
        ],
      ),
    ),
  );
}
