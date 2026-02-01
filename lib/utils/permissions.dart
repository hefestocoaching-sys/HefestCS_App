import 'dart:io';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hefestocs/constants/colors.dart';

class AppPermissions {
  static Future<void> openSettings() async {
    await openAppSettings();
  }

  static void _explain(BuildContext context, String rationale, {VoidCallback? onSettings}) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          rationale,
          style: const TextStyle(color: AppTheme.textPrimary, fontFamily: 'FINALOLD'),
        ),
        backgroundColor: AppTheme.surface,
        behavior: SnackBarBehavior.floating,
        action: onSettings != null
            ? SnackBarAction(
          label: 'Ajustes',
          onPressed: onSettings,
          textColor: AppTheme.primaryGold,
        )
            : null,
      ),
    );
  }

  static Future<bool> ensureCamera(BuildContext context) async {
    final status = await Permission.camera.status;
    if (status.isGranted) return true;

    final result = await Permission.camera.request();
    if (!context.mounted) return false;

    if (result.isGranted) return true;

    _explain(context, 'Permiso de cámara requerido para tomar fotos.', onSettings: openSettings);
    return false;
  }

  static Future<bool> ensurePickImage(BuildContext context) async {
    Permission? perm;
    String rationale;

    if (Platform.isIOS) {
      perm = Permission.photos;
      rationale = 'Permiso de fotos requerido para abrir la galería.';
    } else if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      if (!context.mounted) return false;

      final sdkInt = androidInfo.version.sdkInt;
      if (sdkInt >= 33) {
        perm = Permission.photos;
        rationale = 'Permiso de fotos requerido para abrir la galería.';
      } else {
        perm = Permission.storage;
        rationale = 'Permiso de almacenamiento requerido para abrir la galería.';
      }
    } else {
      return false;
    }

    final status = await perm.status;
    if (status.isGranted || status.isLimited) return true;

    final result = await perm.request();
    if (!context.mounted) return false;

    if (result.isGranted || result.isLimited) return true;

    _explain(context, rationale, onSettings: openSettings);
    return false;
  }
}