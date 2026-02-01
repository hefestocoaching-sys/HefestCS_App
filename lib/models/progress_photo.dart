// lib/models/progress_photo.dart
// ✅ VERSIÓN FINAL Y COMPLETA DEL MODELO

import 'dart:io';
import 'dart:typed_data';

class ProgressPhoto {
  // ▼▼▼ PROPIEDAD 'id' AÑADIDA ▼▼▼
  final String id; // ID único para identificar cada foto.
  final File file;
  final DateTime createdAt;
  final Uint8List? bytes;
  final String? notes;

  // Propiedades para gestionar el estado, tal como ya las tenías.
  int likeCount;
  int commentCount;
  bool isLikedByCurrentUser;
  List<Map<String, dynamic>> comments;
  bool isPublic;

  ProgressPhoto({
    required this.file,
    required this.createdAt,
    this.bytes,
    this.notes,
    this.likeCount = 0,
    this.commentCount = 0,
    this.isLikedByCurrentUser = false,
    this.isPublic = false,
    List<Map<String, dynamic>>? comments,
  })  // ▼▼▼ LÓGICA PARA GENERAR EL ID ÚNICO ▼▼▼
  // Se genera automáticamente al crear el objeto, usando datos únicos.
      : id = createdAt.toIso8601String() + file.path.hashCode.toString(),
        comments = comments ?? [];
}
