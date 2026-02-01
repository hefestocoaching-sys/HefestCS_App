import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';


class UserInfoCard extends StatelessWidget {
  final String userName;
  final String planType;
  final double kcalProgress;
  final String fatPercentage;
  final String musclePercentage;
  final String kcalValue;

  const UserInfoCard({
    super.key,
    required this.userName,
    required this.planType,
    required this.kcalProgress,
    required this.fatPercentage,
    required this.musclePercentage,
    required this.kcalValue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: AppTheme.surface.withAlpha(200),
        borderRadius: BorderRadius.all(Radius.circular(16.r)),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90.w,
            height: 90.w,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: kcalProgress,
                  strokeWidth: 7.w,
                  backgroundColor: AppTheme.progressIndicatorBackground,
                  color: AppTheme.primaryGold,
                ),
                Center(
                  child: CircleAvatar(
                    radius: 38.r,
                    backgroundColor: AppTheme.unselectedItemColor,
                    child: Icon(Icons.person, size: 40.w, color: AppTheme.surface),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  userName,
                  style: textTheme.headlineSmall?.copyWith(fontSize: 20.w),
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
                Text(
                  'Plan: $planType',
                  style: textTheme.titleSmall?.copyWith(
                    color: AppTheme.primaryGold,
                    fontSize: 12.w,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    StatColumn(label: 'Grasa', value: fatPercentage),
                    StatColumn(label: 'Músculo', value: musclePercentage),
                    StatColumn(label: 'Kcal', value: kcalValue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const StatColumn({super.key, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Column(
      children: [
        Text(
          label,
          style: textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondary,
            fontSize: 12.w,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 13.w,
          ),
        ),
      ],
    );
  }
}
