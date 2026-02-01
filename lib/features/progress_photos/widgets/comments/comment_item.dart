import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';

// REFACTOR: Widget para un solo comentario, ahora en su propio archivo.

class CommentItem extends StatefulWidget {
  final Map<String, dynamic> comment;
  final Function(String) onReply;
  final VoidCallback onDelete;
  final Function(Map<String, dynamic>) onDeleteReply;

  const CommentItem(
      {super.key, 
      required this.comment, 
      required this.onReply, 
      required this.onDelete, 
      required this.onDeleteReply});

  @override
  State<CommentItem> createState() => _CommentItemState();
}

class _CommentItemState extends State<CommentItem> {
  bool _isLiked = false;
  int _likeCount = 0;
  final _replyController = TextEditingController();
  bool _showReplyField = false;

  @override
  void initState() {
    super.initState();
    _isLiked = widget.comment['isLiked'] ?? false;
    _likeCount = widget.comment['likeCount'] ?? 0;
  }

  void _toggleLike() {
    setState(() {
      _isLiked = !_isLiked;
      _likeCount = _isLiked ? _likeCount + 1 : _likeCount - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List replies = widget.comment['replies'] ?? [];
    return GestureDetector(
      onLongPress: widget.onDelete,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(radius: 20.r, child: Text(widget.comment['user']![0])),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(color: Colors.grey[850], borderRadius: BorderRadius.circular(12.r)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(widget.comment['user']!, style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                            SizedBox(height: 4.h),
                            Text(widget.comment['text']!, style: const TextStyle(color: Colors.white, fontSize: 14)),
                          ],
                        ),
                      ),
                      SizedBox(height: 4.h),
                      GestureDetector(
                        onTap: () => setState(() => _showReplyField = !_showReplyField),
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 4.h),
                          child: Text('Responder', style: TextStyle(color: Colors.grey[400], fontSize: 12.w, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                Padding(
                  padding: EdgeInsets.only(top: 8.h),
                  child: Column(
                    children: [
                      GestureDetector(onTap: _toggleLike, child: Icon(_isLiked ? Icons.favorite : Icons.favorite_border, color: _isLiked ? Colors.red : Colors.grey[400], size: 18.w)),
                      SizedBox(height: 2.h),
                      if (_likeCount > 0) Text(_likeCount.toString(), style: TextStyle(color: Colors.grey[400], fontSize: 12.w)),
                    ],
                  ),
                ),
              ],
            ),
            if (replies.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(left: 50.w, top: 8.h),
                child: Column(
                  children: replies.map((reply) {
                    return CommentItem(
                      comment: reply,
                      onReply: widget.onReply,
                      onDelete: () => widget.onDeleteReply(reply),
                      onDeleteReply: (nestedReply) {},
                    );
                  }).toList(),
                ),
              ),
            if (_showReplyField)
              Padding(
                padding: EdgeInsets.only(left: 50.w, top: 8.h, right: 10.w),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _replyController,
                        autofocus: true,
                        style:  TextStyle(color: Colors.grey[850]),
                        decoration: InputDecoration(
                          hintText: 'Escribe una respuesta...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          filled: true,
                          fillColor: Colors.grey[850],
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20.r)),
                          contentPadding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                        ),
                      ),
                    ),
                    SizedBox(width: 8.w),
                    GestureDetector(
                      onTap: () {
                        widget.onReply(_replyController.text);
                        setState(() => _showReplyField = false);
                      },
                      child: Icon(Icons.send, color: AppTheme.primaryGold, size: 24.w),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
