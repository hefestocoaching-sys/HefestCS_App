import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/features/progress_photos/views/full_screen_gallery_view.dart';
import 'package:hefestocs/models/progress_photo.dart';
import 'package:hefestocs/providers/progress_photos_provider.dart';
import 'package:hefestocs/widgets/user_info_card.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'widgets/virtual_frame.dart';

// Vuelve a ser un StatelessWidget, como debe ser.
class ProgressPhotosScreen extends StatelessWidget {
  const ProgressPhotosScreen({super.key});

  // Tus constantes y funciones de menú, sin cambios.
  static const String _userName = 'Atleta Hefesto';
  static const String _planType = 'Transformación';
  static const String _fatPercentage = '15%';
  static const String _musclePercentage = '40%';
  static const String _kcalValue = '1850/2200';
  static const double _kcalProgress = 0.75;

  void _showImageSourceMenu(BuildContext context, ProgressPhotosProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppTheme.textPrimary, size: 22.w),
              title: Text('Elegir de la Galería', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15.w)),
              onTap: () {
                Navigator.of(ctx).pop();
                _askForPostType(context, provider, ImageSource.gallery);
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt_outlined, color: AppTheme.textPrimary, size: 22.w),
              title: Text('Tomar Foto', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15.w)),
              onTap: () {
                Navigator.of(ctx).pop();
                _askForPostType(context, provider, ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _askForPostType(BuildContext context, ProgressPhotosProvider provider, ImageSource source) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.photo_album_outlined, color: AppTheme.textPrimary, size: 22.w),
              title: Text('Subir al carrusel (Pública)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15.w)),
              subtitle: Text('Visible para tu coach y otros', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.w)),
              onTap: () {
                Navigator.of(ctx).pop();
                provider.startImageFlow(context, source, isPublic: true);
              },
            ),
            ListTile(
              leading: Icon(Icons.lock_outline, color: AppTheme.textPrimary, size: 22.w),
              title: Text('Guardar solo para mí (Privada)', style: TextStyle(color: AppTheme.textPrimary, fontSize: 15.w)),
              subtitle: Text('Solo tú podrás ver esta foto', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12.w)),
              onTap: () {
                Navigator.of(ctx).pop();
                provider.startImageFlow(context, source, isPublic: false);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ProgressPhotosProvider>();
    final allPhotos = provider.photos;

    // Se devuelve al Scaffold simple que solo muestra la cuadrícula.
    return Scaffold(
      backgroundColor: AppTheme.wrapperBackground,
      appBar: AppBar(
        title: const Text('Progreso Visual'),
        backgroundColor: AppTheme.navBar,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showImageSourceMenu(context, provider),
        backgroundColor: AppTheme.primaryGold,
        child: provider.isLoading
            ? const CircularProgressIndicator(color: Colors.black)
            : Icon(Icons.camera_alt, color: Colors.black, size: 24.w),
      ),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/fondo_1.png',
            fit: BoxFit.cover,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            child: Column(
              children: [
                SizedBox(height: 16.h),
                const UserInfoCard(
                  userName: _userName,
                  planType: _planType,
                  kcalProgress: _kcalProgress,
                  fatPercentage: _fatPercentage,
                  musclePercentage: _musclePercentage,
                  kcalValue: _kcalValue,
                ),
                SizedBox(height: 24.h),
                Expanded(
                  child: allPhotos.isEmpty
                      ? const _EmptyState()
                      : GridView.builder(
                    padding: const EdgeInsets.only(bottom: 80.0),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 12.w,
                      mainAxisSpacing: 12.h,
                      childAspectRatio: 0.7,
                    ),
                    itemCount: allPhotos.length,
                    itemBuilder: (context, index) {
                      return _PhotoTile(
                        // La Key aquí es una buena práctica y no causa problemas.
                        key: ValueKey(allPhotos[index].id),
                        photo: allPhotos[index],
                        index: index, // Se pasa el índice para el Hero y la navegación
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// El widget _EmptyState, sin cambios.
class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Text(
          'Agrega tu primera foto de progreso',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 15.w,
          ),
        ),
      ),
    );
  }
}

// El widget _PhotoTile ahora navega a la galería de pantalla completa.
class _PhotoTile extends StatelessWidget {
  final ProgressPhoto photo;
  final int index;

  const _PhotoTile({super.key, required this.photo, required this.index});

  @override
  Widget build(BuildContext context) {
    final imageProvider = photo.bytes != null
        ? MemoryImage(photo.bytes!)
        : FileImage(photo.file) as ImageProvider;

    return Hero(
      tag: photo.id,
      child: GestureDetector(
        onTap: () {
          // Navegación estándar a la pantalla completa.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => FullScreenGalleryView(
                initialIndex: index,
              ),
            ),
          );
        },
        child: ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image(image: imageProvider, fit: BoxFit.cover, errorBuilder: (c, e, s) => const Icon(Icons.error)),
              VirtualFrame(createdAt: photo.createdAt),
            ],
          ),
        ),
      ),
    );
  }
}
