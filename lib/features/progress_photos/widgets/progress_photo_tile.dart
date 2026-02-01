import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/features/progress_photos/widgets/single_photo_view.dart';
import 'package:hefestocs/features/progress_photos/widgets/virtual_frame.dart';
import 'package:hefestocs/models/progress_photo.dart';

class ProgressPhotoTile extends StatefulWidget {
  final ProgressPhoto photo;
  final bool isLoading;
  final VoidCallback onDelete;
  final VoidCallback onSaveToGallery;
  final VoidCallback onShare;

  const ProgressPhotoTile({
    super.key,
    required this.photo,
    required this.onDelete,
    required this.onSaveToGallery,
    required this.onShare,
    this.isLoading = false,
  });

  @override
  State<ProgressPhotoTile> createState() => _ProgressPhotoTileState();
}

class _ProgressPhotoTileState extends State<ProgressPhotoTile> with SingleTickerProviderStateMixin {
  double _scale = 1.0;

  void _showMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.delete_rounded, color: AppTheme.textPrimary),
                title: const Text('Borrar'),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.download_rounded, color: AppTheme.textPrimary),
                title: const Text('Guardar'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onSaveToGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.share_rounded, color: AppTheme.textPrimary),
                title: const Text('Compartir'),
                onTap: () {
                  Navigator.pop(context);
                  widget.onShare();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('¿Estás seguro?'),
        content: const Text('Esta foto será eliminada permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
              onPressed: () {
                Navigator.pop(context);
                widget.onDelete();
              },
              child: const Text('Eliminar')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageProvider = widget.photo.bytes != null
        ? MemoryImage(widget.photo.bytes!)
        : FileImage(widget.photo.file) as ImageProvider;

    return Hero(
      tag: widget.photo.createdAt.toIso8601String(),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _scale = 0.96),
        onTapUp: (_) {
          setState(() => _scale = 1.0);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => Scaffold(
                appBar: AppBar(backgroundColor: Colors.black, elevation: 0),
                backgroundColor: Colors.black,
                body: SinglePhotoView(
                  photo: widget.photo,
                  boundaryKey: GlobalKey(),
                ),
              ),
            ),
          );
        },
        onTapCancel: () => setState(() => _scale = 1.0),
        child: AnimatedScale(
          scale: _scale,
          duration: const Duration(milliseconds: 150),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            child: Stack(
              fit: StackFit.expand,
              children: [
                widget.photo.bytes == null
                    ? Container(
                        color: Colors.grey[300],
                        child: const Center(child: CircularProgressIndicator()),
                      )
                    : Image(image: imageProvider, fit: BoxFit.cover),
                Positioned(
                  right: 4.w,
                  top: 4.h,
                  child: GestureDetector(
                    onTap: () => _showMenu(context),
                    child: Container(
                      padding: EdgeInsets.all(4.w),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(20.r),
                      ),
                      child: const Icon(Icons.more_horiz, color: Colors.white, size: 18),
                    ),
                  ),
                ),
                VirtualFrame(createdAt: widget.photo.createdAt),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
