import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

class VirtualFrame extends StatelessWidget {
  final DateTime createdAt;
  final bool isFullScreen;

  const VirtualFrame({super.key, required this.createdAt, this.isFullScreen = false});

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('dd MMM yyyy', 'es_MX').format(createdAt);
    final logoHeight = isFullScreen ? 35.h : 20.h;
    final fontSize = isFullScreen ? 18.w : 12.w;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withAlpha(180), Colors.transparent],
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Image.asset('assets/hcs.png', height: logoHeight),
            Text(formattedDate, style: TextStyle(fontFamily: 'FINALOLD', color: Colors.white, fontSize: fontSize, shadows: [Shadow(blurRadius: 2, color: Colors.black.withAlpha(200))])),
          ],
        ),
      ),
    );
  }
}
