// lib/features/progress_photos/views/full_screen_gallery_view.dart
// ✅ VERSIÓN FINAL, COMPLETA Y EN UNA SOLA PIEZA

import 'package:flutter/material.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/features/progress_photos/widgets/comments/comments_section.dart';
import 'package:hefestocs/models/progress_photo.dart';
import 'package:hefestocs/providers/progress_photos_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

// Tu clase StatefulWidget, sin cambios.
class FullScreenGalleryView extends StatefulWidget {
  final int initialIndex;

  const FullScreenGalleryView({
    super.key,
    required this.initialIndex,
  });

  @override
  State<FullScreenGalleryView> createState() => _FullScreenGalleryViewState();
}

// Tu clase State, con la corrección del bug de scroll.
class _FullScreenGalleryViewState extends State<FullScreenGalleryView> {
  late ItemScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _scrollController = ItemScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.isAttached) {
        _scrollController.jumpTo(index: widget.initialIndex, alignment: 0.0);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressPhotosProvider>();
    final photos = provider.photos;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: Colors.white),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/fondo_1.png',
            fit: BoxFit.cover,
          ),
          ScrollablePositionedList.builder(
            itemScrollController: _scrollController,
            padding: EdgeInsets.only(
                top: kToolbarHeight + MediaQuery.of(context).padding.top),
            itemCount: photos.length,
            itemBuilder: (context, index) {
              final photo = photos[index];
              return _PhotoPostItem(
                key: ValueKey(photo.id),
                photo: photo,
              );
            },
          ),
        ],
      ),
    );
  }
}

// --- WIDGET PARA CADA "POST" CON LAS FUNCIONES COMPLETADAS ---
class _PhotoPostItem extends StatefulWidget {
  final ProgressPhoto photo;

  const _PhotoPostItem({
    super.key,
    required this.photo,
  });

  @override
  State<_PhotoPostItem> createState() => __PhotoPostItemState();
}

class __PhotoPostItemState extends State<_PhotoPostItem> {
  // Tu estado
  late bool _isPhotoLiked;
  late int _photoLikeCount;
  late List<Map<String, dynamic>> _comments;
  late bool _isPublic;
  late String? _notes;
  bool _isHeartAnimating = false;

  @override
  void initState() {
    super.initState();
    _isPhotoLiked = widget.photo.isLikedByCurrentUser;
    _photoLikeCount = widget.photo.likeCount;
    _isPublic = widget.photo.isPublic;
    _notes = widget.photo.notes;
    _comments = List<Map<String, dynamic>>.from(
      widget.photo.comments.map((comment) {
        final newComment = Map<String, dynamic>.from(comment);
        if (newComment['replies'] != null && newComment['replies'] is List) {
          newComment['replies'] = List<Map<String, dynamic>>.from(
            (newComment['replies'] as List)
                .map((reply) => Map<String, dynamic>.from(reply)),
          );
        }
        return newComment;
      }),
    );
  }

  // ▼▼▼ FUNCIÓN DE LIKE ACTUALIZADA PARA QUITAR LIKE CON DOBLE TOQUE ▼▼▼
  void _togglePhotoLike({bool fromDoubleTap = false}) {
    if (fromDoubleTap) {
      // Lógica de doble toque
      setState(() {
        if (_isPhotoLiked) {
          // Si ya tiene like y se hace doble toque, se lo quitamos.
          _isPhotoLiked = false;
          _photoLikeCount--;
        } else {
          // Si no tiene like, se lo damos y animamos.
          _isPhotoLiked = true;
          _photoLikeCount++;
          _isHeartAnimating = true;
        }
      });
      // La animación del corazón solo se muestra si se AÑADE un like.
      if (_isPhotoLiked && _isHeartAnimating) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) setState(() => _isHeartAnimating = false);
        });
      }
    } else {
      // Lógica para el botón de corazón normal (tap simple)
      setState(() {
        if (_isPhotoLiked) {
          _isPhotoLiked = false;
          _photoLikeCount--;
        } else {
          _isPhotoLiked = true;
          _photoLikeCount++;
        }
      });
    }
    // Aquí notificarías al provider para persistir el cambio
  }

  // ▼▼▼ FUNCIONES AHORA COMPLETAS ▼▼▼

  void _toggleVisibility(bool value) {
    setState(() {
      _isPublic = value;
    });
    context
        .read<ProgressPhotosProvider>()
        .setPhotoVisibility(widget.photo, value);
  }

  void _showComments() {
    if (!_isPublic) return;
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
                  'user': 'Atleta Hefesto',
                  'avatar': 'assets/images/placeholder_user.png',
                  'text': text,
                  'isLiked': false,
                  'likeCount': 0,
                  'replies': <Map<String, dynamic>>[],
                };
                modalSetState(() {
                  if (parentComment != null) {
                    if (parentComment['replies'] == null) {
                      parentComment['replies'] = <Map<String, dynamic>>[];
                    }
                    (parentComment['replies'] as List).insert(0, newComment);
                  } else {
                    _comments.insert(0, newComment);
                  }
                });
                setState(() {});
              },
              onCommentDeleted: (comment, [parent]) {
                modalSetState(() {
                  if (parent == null) {
                    _comments.remove(comment);
                  } else {
                    (parent['replies'] as List).remove(comment);
                  }
                });
                setState(() {});
              },
              onLikeComment: (likedComment) {
                modalSetState(() {
                  likedComment['isLiked'] = !(likedComment['isLiked'] as bool);
                  if (likedComment['isLiked'] as bool) {
                    likedComment['likeCount']++;
                  } else {
                    likedComment['likeCount']--;
                  }
                });
              },
            );
          },
        );
      },
    );
  }

  int _countTotalComments(List<Map<String, dynamic>> comments) {
    int count = 0;
    for (final comment in comments) {
      count++;
      if (comment.containsKey('replies') &&
          comment['replies'] != null &&
          (comment['replies'] as List).isNotEmpty) {
        final replies =
            (comment['replies'] as List).cast<Map<String, dynamic>>();
        count += _countTotalComments(replies);
      }
    }
    return count;
  }

  void _showPostOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading:
                  const Icon(Icons.photo_library_outlined, color: Colors.white),
              title: const Text('Guardar con marca de agua',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                context
                    .read<ProgressPhotosProvider>()
                    .saveToGallery(context, widget.photo, withWatermark: true);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_size_select_actual_outlined,
                  color: Colors.white),
              title: const Text('Guardar sin marca de agua',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                context
                    .read<ProgressPhotosProvider>()
                    .saveToGallery(context, widget.photo, withWatermark: false);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Eliminar publicación',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                _confirmDeletePhotoDialog();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePhotoDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar borrado'),
        content: const Text(
            '¿Estás seguro de que quieres eliminar esta publicación?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context
                  .read<ProgressPhotosProvider>()
                  .deletePhotoByObject(widget.photo);
              if (context.read<ProgressPhotosProvider>().photos.isEmpty) {
                Navigator.of(context).pop();
              }
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            color: AppTheme.navBar,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: [
                const CircleAvatar(
                    radius: 18,
                    backgroundImage:
                        AssetImage('assets/images/placeholder_user.png')),
                const SizedBox(width: 12),
                const Text('Atleta Hefesto',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16)),
                const Spacer(),
                IconButton(
                    icon: const Icon(Icons.more_vert, color: Colors.white),
                    onPressed: _showPostOptions),
              ],
            ),
          ),
          GestureDetector(
            onDoubleTap: () => _togglePhotoLike(fromDoubleTap: true),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: Image.file(widget.photo.file,
                      fit: BoxFit.cover, width: double.infinity),
                ),
                Positioned(
                  bottom: 12.0,
                  left: 12.0,
                  child: Image.asset('assets/hcs.png',
                      height: 40, color: Colors.white.withAlpha(230)),
                ),
                Positioned(
                  bottom: 12.0,
                  right: 12.0,
                  child: Text(
                    DateFormat('dd/MM/yyyy').format(widget.photo.createdAt),
                    style: const TextStyle(
                        fontFamily: 'FINALOLD',
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        shadows: [
                          Shadow(blurRadius: 2.0, color: Colors.black)
                        ]),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: _isHeartAnimating ? 1.0 : 0.0,
                  child: Icon(
                    Icons.favorite,
                    color: Colors.red[400],
                    size: 100,
                    shadows: [
                      Shadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 10)
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            color: AppTheme.navBar,
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    GestureDetector(
                      onTap: () => _togglePhotoLike(),
                      child: Icon(
                        _isPhotoLiked ? Icons.favorite : Icons.favorite_border,
                        color: _isPublic
                            ? (_isPhotoLiked ? Colors.red : Colors.white)
                            : Colors.grey[700],
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 6),
                    if (_isPublic && _photoLikeCount > 0)
                      Text('$_photoLikeCount',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: _showComments,
                      child: Icon(Icons.chat_bubble_outline,
                          color: _isPublic ? Colors.white : Colors.grey[700],
                          size: 28),
                    ),
                    const SizedBox(width: 6),
                    if (_isPublic && _comments.isNotEmpty)
                      Text('${_countTotalComments(_comments)}',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold)),
                    const SizedBox(width: 24),
                    GestureDetector(
                      onTap: () => context
                          .read<ProgressPhotosProvider>()
                          .sharePhoto(context, widget.photo),
                      child: const Icon(Icons.share_outlined,
                          color: Colors.white, size: 28),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(_isPublic ? 'Público' : 'Privado',
                        style: TextStyle(
                            color: _isPublic ? Colors.white : Colors.grey[400],
                            fontSize: 12)),
                    const SizedBox(width: 4),
                    Transform.scale(
                      scale: 0.8,
                      child: Switch(
                        value: _isPublic,
                        onChanged: _toggleVisibility,
                        activeThumbColor: AppTheme.primaryGold,
                        activeTrackColor: AppTheme.primaryGold.withAlpha(100),
                        inactiveThumbColor: Colors.grey,
                        inactiveTrackColor: Colors.grey[800],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_notes != null && _notes!.isNotEmpty) ...[
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(color: Colors.white, fontSize: 14),
                      children: [
                        const TextSpan(
                            text: 'Atleta Hefesto ',
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        TextSpan(text: _notes!),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                Text(
                  'Publicado el ${DateFormat('d \'de\' MMMM \'de\' y', 'es_ES').format(widget.photo.createdAt)}',
                  style: TextStyle(color: Colors.grey[600], fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
