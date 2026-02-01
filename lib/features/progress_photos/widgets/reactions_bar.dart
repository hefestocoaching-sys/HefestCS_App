import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ReactionsBar extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final VoidCallback onLikeTapped;
  final VoidCallback onCommentTapped;

  const ReactionsBar({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.onLikeTapped,
    required this.onCommentTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      color: Colors.black,
      child: Row(
        children: [
          GestureDetector(
            onTap: onLikeTapped,
            child: Row(
              children: [
                Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? Colors.red : Colors.white, size: 28.w),
                SizedBox(width: 8.w),
                if (likeCount > 0) Text(likeCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          SizedBox(width: 24.w),
          GestureDetector(
            onTap: onCommentTapped,
            child: Row(
              children: [
                Icon(Icons.chat_bubble_outline, color: Colors.white, size: 26.w),
                SizedBox(width: 8.w),
                if (commentCount > 0) Text(commentCount.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
