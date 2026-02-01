import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';

class CommentsSection extends StatefulWidget {
  final List<Map<String, dynamic>> comments;
  final Function(String text, [Map<String, dynamic>? parentComment])
      onCommentAdded;
  final Function(Map<String, dynamic> comment, [Map<String, dynamic>? parent])
      onCommentDeleted;
  final Function(Map<String, dynamic> comment) onLikeComment;

  const CommentsSection({
    super.key,
    required this.comments,
    required this.onCommentAdded,
    required this.onCommentDeleted,
    required this.onLikeComment,
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  Map<String, dynamic>? _replyingToComment;
  String? _replyingToUser;
  Map<String, dynamic>? _editingComment;

  void _submitComment() {
    String text = _textController.text.trim();
    if (text.isNotEmpty) {
      if (text[0] != '@' && _replyingToUser == null) {
        text = text[0].toUpperCase() + text.substring(1);
      }
      if (_replyingToUser != null) {
        text = '@$_replyingToUser $text';
      }
      if (_editingComment != null) {
        setState(() {
          _editingComment!['text'] = text;
        });
        _cancelEditing();
      } else {
        widget.onCommentAdded(text, _replyingToComment);
        _cancelReply();
      }
      _textController.clear();
      _focusNode.unfocus();
    }
  }

  void _startReplying(Map<String, dynamic> parentComment, [String? user]) {
    setState(() {
      _replyingToComment = parentComment;
      _replyingToUser = user ?? parentComment['user'] as String;
      _focusNode.requestFocus();
    });
  }

  void _cancelReply() {
    setState(() {
      _replyingToComment = null;
      _replyingToUser = null;
      _focusNode.unfocus();
    });
  }

  void _startEditing(Map<String, dynamic> commentToEdit) {
    setState(() {
      _editingComment = commentToEdit;
      _textController.text = commentToEdit['text'] as String;
      _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length));
      _focusNode.requestFocus();
    });
  }

  void _cancelEditing() {
    setState(() {
      _editingComment = null;
      _textController.clear();
      _focusNode.unfocus();
    });
  }

  void _showCommentOptions(
      BuildContext parentContext, Map<String, dynamic> comment,
      {bool isReply = false, Map<String, dynamic>? parent}) {
    showModalBottomSheet(
      context: parentContext,
      backgroundColor: AppTheme.surface,
      builder: (ctx) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: Colors.white),
              title: const Text('Editar comentario',
                  style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.of(ctx).pop();
                _startEditing(comment);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Eliminar comentario',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(ctx).pop();
                widget.onCommentDeleted(comment, parent);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        builder: (_, scrollController) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.grey[900]?.withValues(alpha: 0.95),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              // ¡LA LÍNEA DEL BORDE HA SIDO ELIMINADA DE AQUÍ!
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Comentarios',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 16.w,
                          fontWeight: FontWeight.bold)),
                ),
                const Divider(color: Colors.white24, height: 1),
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: widget.comments.length,
                    itemBuilder: (context, index) {
                      final comment = widget.comments[index];
                      return _CommentTile(
                        comment: comment,
                        onLongPress: () =>
                            _showCommentOptions(context, comment),
                        onReply: () => _startReplying(comment),
                        onLike: () => widget.onLikeComment(comment),
                        isReply: false,
                        onReplyToReply: (reply) =>
                            _startReplying(comment, reply['user'] as String),
                        onLongPressReply: (reply) => _showCommentOptions(
                            context, reply,
                            isReply: true, parent: comment),
                        onLikeReply: (reply) => widget.onLikeComment(reply),
                      );
                    },
                  ),
                ),
                _buildCommentInputField(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildCommentInputField() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      color: Colors.grey[900]?.withValues(
          alpha: 0.95), // Mantiene el color de fondo del contenedor
      child: Row(
        children: [
          const CircleAvatar(
            backgroundImage: AssetImage('assets/images/placeholder_user.png'),
            radius: 18,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ClipRRect(
              // ClipRRect para redondear el TextField
              borderRadius: BorderRadius.circular(20.r),
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                style: const TextStyle(
                    color: Colors.white), // Color del texto que escribes
                decoration: InputDecoration(
                  hintText: _replyingToUser != null
                      ? 'Respondiendo a $_replyingToUser...'
                      : 'Añade un comentario...',
                  hintStyle: TextStyle(color: Colors.grey[500]),
                  filled: true, // Importante: para que fillColor funcione
                  fillColor: Colors.grey[800], // Color de fondo del TextField
                  contentPadding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 10.h), // Ajusta el padding interno
                ),
              ),
            ),
          ),
          const SizedBox(width: 8), // Pequeño espacio antes del botón
          IconButton(
            icon: Icon(Icons.send,
                color: AppTheme
                    .primaryGold), // Mantengo el color del icono como estaba
            onPressed: _submitComment,
          ),
        ],
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  final Map<String, dynamic> comment;
  final VoidCallback onReply;
  final VoidCallback onLike;
  final VoidCallback onLongPress;
  final bool isReply;
  final Function(Map<String, dynamic>) onReplyToReply;
  final Function(Map<String, dynamic>) onLongPressReply;
  final Function(Map<String, dynamic>) onLikeReply;

  const _CommentTile({
    required this.comment,
    required this.onReply,
    required this.onLike,
    required this.onLongPress,
    this.isReply = false,
    required this.onReplyToReply,
    required this.onLongPressReply,
    required this.onLikeReply,
  });

  @override
  Widget build(BuildContext context) {
    final List<dynamic> replies = comment['replies'] as List<dynamic>? ?? [];

    return InkWell(
      onLongPress: onLongPress,
      child: Padding(
        padding: EdgeInsets.only(
          left: isReply ? 40.0 : 16.0,
          right: 16.0,
          top: 12.0,
          bottom: 12.0,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundImage: AssetImage(comment['avatar'] as String? ??
                      'assets/images/placeholder_user.png'),
                  radius: isReply ? 16 : 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            comment['user'] as String? ?? 'Usuario',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 14.w,
                            ),
                          ),
                          const Spacer(),
                          GestureDetector(
                            onTap: onLike,
                            child: Row(
                              children: [
                                Icon(
                                  (comment['isLiked'] as bool? ?? false)
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: (comment['isLiked'] as bool? ?? false)
                                      ? Colors.red
                                      : Colors.grey,
                                  size: 18.w,
                                ),
                                if ((comment['likeCount'] as int? ?? 0) >
                                    0) ...[
                                  const SizedBox(width: 4),
                                  Text(
                                    '${comment['likeCount']}',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13.w),
                                  ),
                                ]
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        comment['text'] as String? ?? '',
                        style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.9),
                            fontSize: 14.w,
                            height: 1.4),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: onReply,
                        child: Text(
                          'Responder',
                          style: TextStyle(
                              color: Colors.grey[500],
                              fontSize: 12.w,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (replies.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 10.0, left: 10.0),
                child: Column(
                  children: replies.map((reply) {
                    return _CommentTile(
                      comment: reply as Map<String, dynamic>,
                      isReply: true,
                      onLongPress: () => onLongPressReply(reply),
                      onReply: () => onReplyToReply(reply),
                      onLike: () => onLikeReply(reply),
                      onReplyToReply: (_) {},
                      onLongPressReply: (_) {},
                      onLikeReply: (_) {},
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
