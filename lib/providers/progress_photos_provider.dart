// lib/providers/progress_photos_provider.dart
// ✅ VERSIÓN FINAL Y COMPLETA (BASADA 100% EN TU CÓDIGO)

import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/features/progress_photos/views/create_post_screen.dart';
import 'package:hefestocs/models/progress_photo.dart';
import 'package:hefestocs/utils/gallery_io.dart';
import 'package:hefestocs/utils/permissions.dart';
import 'package:hefestocs/utils/snack.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:pro_image_editor/pro_image_editor.dart';
import 'package:share_plus/share_plus.dart';

// Tu clase y propiedades, sin cambios.
class ProgressPhotosProvider with ChangeNotifier {
  final ImagePicker _picker = ImagePicker();
  final List<ProgressPhoto> _photos = [];
  bool _isLoading = false;

  List<ProgressPhoto> get photos => _photos;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  // Tu función startImageFlow, sin cambios.
  Future<void> startImageFlow(BuildContext context, ImageSource source, {required bool isPublic}) async {
    if (_isLoading) return;
    _setLoading(true);

    try {
      final editedBytes = await _pickAndEditImage(context, source);
      if (editedBytes == null || !context.mounted) {
        _setLoading(false);
        return;
      }

      final String? notes = await Navigator.of(context).push<String>(
        MaterialPageRoute(builder: (_) => CreatePostScreen(imageBytes: editedBytes)),
      );
      if (!context.mounted || notes == null) {
        _setLoading(false);
        return;
      }

      await _saveFinalImage(context, editedBytes, notes, isPublic: isPublic);
    } catch (e, st) {
      debugPrint('Error en el flujo de imagen: $e\n$st');
      if (context.mounted) Snacks.of(context).err('Ocurrió un error inesperado.');
    } finally {
      if (context.mounted) _setLoading(false);
    }
  }

  // Tu función _pickAndEditImage, sin cambios.
  Future<Uint8List?> _pickAndEditImage(BuildContext context, ImageSource source) async {
    bool hasPermission;
    if (source == ImageSource.camera) {
      hasPermission = await AppPermissions.ensureCamera(context);
    } else {
      hasPermission = await AppPermissions.ensurePickImage(context);
    }

    if (!hasPermission || !context.mounted) return null;

    final xfile = await _picker.pickImage(source: source, imageQuality: 80);
    if (xfile == null || !context.mounted) return null;

    final bytes = await xfile.readAsBytes();
    if (!context.mounted) return null;

    final nav = Navigator.of(context);
    final completer = Completer<Uint8List?>();

    nav.push(
      MaterialPageRoute(
        builder: (builderContext) {
          return ProImageEditor.memory(
            bytes,
            callbacks: ProImageEditorCallbacks(
              onImageEditingComplete: (Uint8List editedBytes) async {
                if (!completer.isCompleted) {
                  completer.complete(editedBytes);
                  Navigator.of(builderContext).pop();
                }
              },
              onCloseEditor: (_) {
                if (!completer.isCompleted) {
                  completer.complete(null);
                  Navigator.of(builderContext).pop();
                }
              },
            ),
            configs: ProImageEditorConfigs(
              theme: ThemeData(
                brightness: Brightness.dark,
                appBarTheme: const AppBarTheme(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  actionsIconTheme: IconThemeData(color: AppTheme.primaryGold),
                ),
                scaffoldBackgroundColor: Colors.black,
                bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                  backgroundColor: Colors.black,
                ),
                colorScheme: const ColorScheme.dark().copyWith(
                  primary: AppTheme.primaryGold,
                  secondary: AppTheme.primaryGold,
                ),
              ),
              mainEditor: const MainEditorConfigs(
                tools: [
                  SubEditorMode.cropRotate,
                  SubEditorMode.tune,
                  SubEditorMode.filter,
                  SubEditorMode.text,
                ],
              ),
            ),
          );
        },
      ),
    );
    return completer.future;
  }

  // Tu función _saveFinalImage, sin cambios.
  Future<void> _saveFinalImage(BuildContext context, Uint8List finalBytes, String notes, {required bool isPublic}) async {
    final newFile = await GalleryIO.saveTempPng(finalBytes);
    if (newFile == null || !context.mounted) {
      if (context.mounted) Snacks.of(context).err('No se pudo guardar el archivo.');
      return;
    }

    final newPhoto = ProgressPhoto(
      file: newFile,
      createdAt: DateTime.now(),
      bytes: finalBytes,
      notes: notes,
      isPublic: isPublic,
      likeCount: isPublic ? 15 : 0,
      isLikedByCurrentUser: isPublic ? true : false,
      comments: isPublic
          ? [
        {'user': 'Coach Hefesto', 'avatar': 'assets/hcs.png', 'text': '¡Excelente progreso esta semana!', 'isLiked': true, 'likeCount': 5, 'replies': []}
      ]
          : [],
    );
    newPhoto.commentCount = newPhoto.comments.length;

    _photos.insert(0, newPhoto);
    notifyListeners();
    Snacks.of(context).ok('Publicación agregada');
  }

  // Tu función deletePhotoByObject, sin cambios.
  Future<void> deletePhotoByObject(ProgressPhoto photo) async {
    try {
      if (await photo.file.exists()) {
        await photo.file.delete();
      }
      _photos.remove(photo);
      notifyListeners();
    } catch (e) {
      debugPrint('Error al eliminar foto: $e');
    }
  }

  // Tu función saveToGallery, sin cambios.
  Future<void> saveToGallery(BuildContext context, ProgressPhoto photo, {required bool withWatermark}) async {
    _setLoading(true);
    Uint8List? bytesToSave;

    if (withWatermark) {
      bytesToSave = await _generateWatermarkedImage(photo);
    } else {
      bytesToSave = photo.bytes;
    }

    if (bytesToSave == null) {
      if (context.mounted) Snacks.of(context).err("No se pudo generar la imagen para guardar.");
      _setLoading(false);
      return;
    }

    final ok = await GalleryIO.saveBytesToGallery(bytesToSave);
    if (context.mounted) {
      if (ok) {
        Snacks.of(context).ok("Guardado en galería");
      } else {
        Snacks.of(context).err("No se pudo guardar la imagen");
      }
    }
    _setLoading(false);
  }

  // Tu función sharePhoto, sin cambios.
  Future<void> sharePhoto(BuildContext context, ProgressPhoto photo) async {
    _setLoading(true);
    final bytesToShare = await _generateWatermarkedImage(photo);
    _setLoading(false);

    if (bytesToShare == null) {
      if (context.mounted) Snacks.of(context).err("No se pudo generar la imagen para compartir.");
      return;
    }

    final tempFile = await GalleryIO.saveTempPng(bytesToShare, name: "progreso_hefesto_cs");
    if (tempFile == null || !context.mounted) return;

    await SharePlus.instance.share(ShareParams(
      files: [XFile(tempFile.path)],
      text: 'Mira mi progreso con #HefestoCS',
    ));
  }

  // ▼▼▼ ESTA ES LA ÚNICA FUNCIÓN MODIFICADA PARA SINCRONIZAR EL DISEÑO ▼▼▼
  Future<Uint8List?> _generateWatermarkedImage(ProgressPhoto photo) async {
    try {
      if (photo.bytes == null) return null;

      final Completer<ui.Image> imageCompleter = Completer();
      ui.decodeImageFromList(photo.bytes!, imageCompleter.complete);
      final ui.Image baseImage = await imageCompleter.future;

      final ByteData logoData = await rootBundle.load('assets/hcs.png'); // Tu ruta, sin cambios
      final Completer<ui.Image> logoCompleter = Completer();
      ui.decodeImageFromList(logoData.buffer.asUint8List(), logoCompleter.complete);
      final ui.Image logoImage = await logoCompleter.future;

      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, baseImage.width.toDouble(), baseImage.height.toDouble()));
      final paint = Paint();
      final imageSize = Size(baseImage.width.toDouble(), baseImage.height.toDouble());

      // Dibuja la imagen base (sin cambios)
      canvas.drawImageRect(
        baseImage,
        Rect.fromLTWH(0, 0, baseImage.width.toDouble(), baseImage.height.toDouble()),
        Rect.fromLTWH(0, 0, imageSize.width, imageSize.height),
        paint,
      );

      // --- LÓGICA DE DIBUJO SINCRONIZADA CON TU UI ---
      const double padding = 24.0; // Padding consistente

      // 1. Dibuja el logo en la esquina inferior izquierda
      const double logoHeight = 140.0; // Tamaño 40pt * 2 para alta resolución
      final double logoWidth = (logoHeight / logoImage.height) * logoImage.width;
      paint.colorFilter = ColorFilter.mode(Colors.white.withAlpha(230), BlendMode.srcIn); // Color consistente
      canvas.drawImageRect(
        logoImage,
        Rect.fromLTWH(0, 0, logoImage.width.toDouble(), logoImage.height.toDouble()),
        Rect.fromLTWH(padding, imageSize.height - logoHeight - padding, logoWidth, logoHeight),
        paint,
      );

      // 2. Prepara y dibuja el texto de la fecha en la esquina inferior derecha
      final dateText = DateFormat('dd/MM/yyyy').format(photo.createdAt);
      final textPainter = TextPainter(
        text: TextSpan(
          text: dateText,
          style: TextStyle(
            fontFamily: 'FINALOLD', // Tu fuente
            fontWeight: FontWeight.bold,
            fontSize: 70, // Tamaño 20pt * 2 para alta resolución
            shadows: const [Shadow(blurRadius: 2.0, color: Colors.black)],
          ),
        ),
        textDirection: ui.TextDirection.ltr,
      );
      textPainter.layout();

      textPainter.paint(canvas, Offset(
        imageSize.width - textPainter.width - padding,
        imageSize.height - textPainter.height - padding,
      ));

      // Exporta el lienzo (sin cambios)
      final picture = recorder.endRecording();
      final finalImage = await picture.toImage(imageSize.width.toInt(), imageSize.height.toInt());
      final byteData = await finalImage.toByteData(format: ui.ImageByteFormat.png);

      return byteData?.buffer.asUint8List();

    } catch (e) {
      // ignore: avoid_print
      print("Error al generar marca de agua: $e");
      return null;
    }
  }

  // Tu función setPhotoVisibility, sin cambios.
  void setPhotoVisibility(ProgressPhoto photo, bool isPublic) {
    final int index = _photos.indexWhere((p) => p.id == photo.id);
    if (index != -1) {
      _photos[index].isPublic = isPublic;
      notifyListeners();
    }
  }
}
