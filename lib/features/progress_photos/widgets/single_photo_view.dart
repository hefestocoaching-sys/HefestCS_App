// lib/features/progress_photos/widgets/single_photo_view.dart
// ✅ VERSIÓN FINAL Y COMPLETA

import 'package:flutter/material.dart';
import 'package:hefestocs/features/progress_photos/widgets/comments/comments_section.dart';
import 'package:hefestocs/features/progress_photos/widgets/reactions_bar.dart';
import 'package:hefestocs/features/progress_photos/widgets/virtual_frame.dart';
import 'package:hefestocs/models/progress_photo.dart';
import 'package:hefestocs/utils/snack.dart';

class SinglePhotoView extends StatefulWidget {
  final ProgressPhoto photo;
  final GlobalKey boundaryKey;

  const SinglePhotoView({
    super.key,
    required this.photo,
    required this.boundaryKey,
  });

  @override
  State<SinglePhotoView> createState() => _SinglePhotoViewState();
}

class _SinglePhotoViewState extends State<SinglePhotoView> {
  // La lógica de estado (likes, comentarios) se queda aquí
  bool _isPhotoLiked = false;
  int _photoLikeCount = 12; // TODO: Cargar desde tu backend/provider
  final List<Map<String, dynamic>> _comments = [
    {'user': 'Juan Pérez', 'text': 'Gran progreso!', 'isLiked': false, 'likeCount': 5, 'replies': []},
    {'user': 'Ana Gómez', 'text': '¡Sigue así!', 'isLiked': true, 'likeCount': 23, 'replies': [{'user': 'Pedro', 'text': 'Gracias!', 'isLiked': false, 'likeCount': 2, 'replies': []}]},
  ];

  // Las funciones relacionadas a los likes y comentarios permanecen aquí
  void _togglePhotoLike() {
    setState(() {
      _isPhotoLiked = !_isPhotoLiked;
      _photoLikeCount = _isPhotoLiked ? _photoLikeCount + 1 : _photoLikeCount - 1;
    });
  }

  int _countTotalComments(List<Map<String, dynamic>> comments) {
    int count = 0;
    for (final comment in comments) {
      count++;
      if (comment.containsKey('replies') && (comment['replies'] as List).isNotEmpty) {
        final replies = (comment['replies'] as List).map((reply) => reply as Map<String, dynamic>).toList();
        count += _countTotalComments(replies);
      }
    }
    return count;
  }

  void _showComments() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter modalSetState) {
            return CommentsSection(
              comments: _comments,
              onCommentAdded: (text, [parentComment]) {
                final newComment = {
                  'user': 'Pedro', // TODO: Usar el usuario actual
                  'text': text,
                  'isLiked': false,
                  'likeCount': 0,
                  'replies': []
                };
                modalSetState(() {
                  if (parentComment != null) {
                    (parentComment['replies'] as List).add(newComment);
                  } else {
                    _comments.insert(0, newComment);
                  }
                });

                setState(() {}); // Actualiza el contador en la barra de reacciones
              },
              onCommentDeleted: (comment, [parent]) {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Eliminar comentario'),
                    content: const Text('¿Estás seguro de que quieres eliminar este comentario?'),
                    actions: [
                      TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancelar')),
                      TextButton(
                        onPressed: () {
                          modalSetState(() {
                            if (parent == null) {
                              _comments.remove(comment);
                            } else {
                              (parent['replies'] as List).remove(comment);
                            }
                          });
                          setState(() {}); // Actualiza el contador
                          Navigator.of(ctx).pop();
                          Snacks.of(context).ok("Comentario eliminado");
                        },
                        child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );
              },
              // ▼▼▼ CORRECCIÓN APLICADA AQUÍ ▼▼▼
              // Se añade el parámetro 'onLikeComment' que faltaba.
              onLikeComment: (likedComment) {
                // Usamos 'modalSetState' para actualizar la UI del modal de comentarios.
                modalSetState(() {
                  // Cambiamos el estado del 'like' del comentario específico.
                  likedComment['isLiked'] = !(likedComment['isLiked'] as bool);
                  // Actualizamos el contador de likes.
                  likedComment['isLiked']
                      ? likedComment['likeCount']++
                      : likedComment['likeCount']--;
                });
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = widget.photo.bytes != null
        ? MemoryImage(widget.photo.bytes!)
        : FileImage(widget.photo.file) as ImageProvider;

    // El Scaffold y AppBar se han movido a la vista de galería
    return Align(
      alignment: Alignment.topCenter,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: InteractiveViewer(
              minScale: 1.0,
              maxScale: 4.0,
              // RepaintBoundary usa el key que le pasamos desde el widget padre
              child: RepaintBoundary(
                key: widget.boundaryKey,
                child: Hero(
                  tag: widget.photo.createdAt.toIso8601String(),
                  child: Stack(
                    children: [
                      Image(image: imageProvider, fit: BoxFit.contain),
                      VirtualFrame(createdAt: widget.photo.createdAt, isFullScreen: true),
                    ],
                  ),
                ),
              ),
            ),
          ),
          ReactionsBar(
            isLiked: _isPhotoLiked,
            likeCount: _photoLikeCount,
            commentCount: _countTotalComments(_comments),
            onLikeTapped: _togglePhotoLike,
            onCommentTapped: _showComments,
          ),
        ],
      ),
    );
  }
}
