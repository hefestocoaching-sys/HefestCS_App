// lib/features/progress_photos/views/create_post_screen.dart
// ✅ VERSIÓN FINAL (CON AJUSTES DE TAMAÑO Y CENTRADO DE ICONOS)

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:hefestocs/constants/colors.dart';

class CreatePostScreen extends StatefulWidget {
  final Uint8List imageBytes;
  final String? initialText;

  const CreatePostScreen({
    super.key,
    required this.imageBytes,
    this.initialText,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  late final TextEditingController _notesController;
  late final bool _isEditing;

  @override
  void initState() {
    super.initState();
    _isEditing = widget.initialText != null;
    _notesController = TextEditingController(text: widget.initialText);
  }

  void _onPublish() {
    Navigator.of(context).pop(_notesController.text);
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appBarTitle = _isEditing ? 'Editar información' : 'Nueva publicación';
    final buttonText = _isEditing ? 'Guardar' : 'Publicar';

    return Scaffold(
      backgroundColor: AppTheme.surface,
      appBar: AppBar(
        title: Text(
          appBarTitle,
          style: const TextStyle(
            fontFamily: 'Roboto',
            fontWeight: FontWeight.bold,
            fontSize: 20.0,
          ),
        ),
        centerTitle: false,
        backgroundColor: AppTheme.surface,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12.0, top: 8.0, bottom: 8.0),
            child: ElevatedButton(
              onPressed: _onPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.0),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
              ),
              child: Text(buttonText),
            ),
          ),
        ],
        // ▲▲▲ FIN CAMBIO 2 ▲▲▲
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8.0),
                      image: DecorationImage(
                        image: MemoryImage(widget.imageBytes),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                      decoration: BoxDecoration(
                        color: AppTheme.navBar,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: TextField(
                        controller: _notesController,
                        autofocus: true,
                        maxLines: 5,
                        textCapitalization: TextCapitalization.sentences,
                        style: const TextStyle(color: AppTheme.overlay, fontSize: 16),
                        decoration: const InputDecoration(
                          hintText: 'Ingresa aqui tu texto para postear...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: AppTheme.overlay),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.person_add_alt_1_outlined, color: Colors.white),
                    onPressed: () {
                    },
                  ),
                  const SizedBox(width: 24),
                  IconButton(
                    icon: const Icon(Icons.location_on_outlined, color: Colors.white),
                    onPressed: () {
                    },
                  ),
                ],
              ),
            ),
            const Divider(color: Colors.white24, height: 1),
          ],
        ),
      ),
      bottomNavigationBar: null,
    );
  }
}