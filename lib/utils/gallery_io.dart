// lib/utils/gallery_io.dart
// ✅ VERSIÓN FINAL Y COMPLETA (CON LA SOLICITUD DE PERMISO CORRECTA)

import 'dart:io';
import 'dart:typed_data';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart'; // Usando tu dependencia
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart'; // Usando tu dependencia

class GalleryIO {
  // Tu función saveTempPng, sin cambios.
  static Future<File?> saveTempPng(Uint8List bytes, {String name = 'temp_img'}) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final file = await File('${tempDir.path}/$name.png').create();
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      // ignore: avoid_print
      print("Error al crear archivo temporal: $e");
      return null;
    }
  }

  // Tu función saveBytesToGallery, ahora correcta.
  static Future<bool> saveBytesToGallery(Uint8List bytes, {String folderName = 'Progreso_HCS'}) async {
    try {
      if (Platform.isAndroid) {
        // Se pide el permiso correcto y moderno para guardar imágenes en la galería.
        final status = await Permission.photos.request();
        if (!status.isGranted) {
          // ignore: avoid_print
          print("Permiso para acceder a las fotos denegado.");
          return false;
        }
      }

      // El resto de tu lógica de guardado.
      final name = 'progreso_${DateTime.now().millisecondsSinceEpoch}.png';
      String? filePath;

      if (Platform.isAndroid) {
        final List<Directory>? externalStorageDirs = await getExternalStorageDirectories(type: StorageDirectory.pictures);
        if (externalStorageDirs == null || externalStorageDirs.isEmpty) {
          // ignore: avoid_print
          print("No se pudo acceder a los directorios de almacenamiento externo.");
          return false;
        }

        final dir = Directory('${externalStorageDirs.first.path}/$folderName');
        if (!await dir.exists()) {
          await dir.create(recursive: true);
        }

        final file = File('${dir.path}/$name');
        await file.writeAsBytes(bytes);
        filePath = file.path;
      } else {
        final tmp = await saveTempPng(bytes, name: name.replaceAll('.png', ''));
        if (tmp == null) return false;
        filePath = tmp.path;
      }

      final result = await ImageGallerySaverPlus.saveFile(
        filePath,
        name: name,
        isReturnPathOfIOS: true,
      );

      return (result is Map && result['isSuccess'] == true) || (result is String && result.isNotEmpty);

    } catch (e) {
      // ignore: avoid_print
      print("Error al guardar en galería: $e");
      return false;
    }
  }
}
