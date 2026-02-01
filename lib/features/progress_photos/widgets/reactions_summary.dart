import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// REFACTOR: Se convierte en un widget interactivo
class ReactionsSummary extends StatelessWidget {
  final Map<String, int> reactions;
  final VoidCallback onCommentsTapped;
  final int commentCount;
  // Nuevos parámetros para la funcionalidad de Like
  final bool isLiked;
  final VoidCallback onLikeTapped;
  final VoidCallback onReactionsTapped;

  const ReactionsSummary({
    super.key,
    required this.reactions,
    required this.onCommentsTapped,
    required this.commentCount,
    required this.isLiked,
    required this.onLikeTapped,
    required this.onReactionsTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: Colors.black.withAlpha(204), // REFACTOR: Se usa withAlpha
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Botón de Like interactivo
          GestureDetector(
            onTap: onLikeTapped, // Tocar para dar/quitar like
            onLongPress: onReactionsTapped, // Mantener presionado para otras reacciones
            child: Row(
              children: [
                Icon(
                  isLiked ? Icons.favorite : Icons.favorite_border,
                  color: isLiked ? Colors.red : Colors.white,
                  size: 26.w,
                ),
                SizedBox(width: 8.w),
                if (reactions['corazon']! > 0) 
                  Text(
                    reactions['corazon']!.toString(),
                    style: TextStyle(color: Colors.white, fontSize: 14.w, fontWeight: FontWeight.bold),
                  ),
              ],
            ),
          ),
          // Botón de Comentarios
          GestureDetector(
            onTap: onCommentsTapped,
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 24.w),
                SizedBox(width: 8.w),
                Text(
                  commentCount.toString(),
                  style: TextStyle(color: Colors.white, fontSize: 14.w, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
