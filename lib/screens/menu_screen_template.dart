import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/constants/colors.dart';

class HorizontalMenuItem {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const HorizontalMenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });
}

class MenuScreenTemplate extends StatelessWidget {
  const MenuScreenTemplate({
    super.key,
    required this.title,
    required this.featuredCardTitle,
    required this.featuredCardSubtitle,
    required this.featuredCardIcon,
    required this.featuredCardOnTap,
    required this.horizontalMenuItems,
  });

  final String title;
  final String featuredCardTitle;
  final String featuredCardSubtitle;
  final IconData featuredCardIcon;
  final VoidCallback featuredCardOnTap;
  final List<HorizontalMenuItem> horizontalMenuItems;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      children: [
        SizedBox(height: 20.h),
        Center(
          child: Text(
            title,
            style: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold, fontSize: 20.w), // Reducido
            textAlign: TextAlign.center,
          ),
        ),
        SizedBox(height: 24.h),
        _FeaturedActionCard(
          title: featuredCardTitle,
          subtitle: featuredCardSubtitle,
          icon: featuredCardIcon,
          onTap: featuredCardOnTap,
        ),
        SizedBox(height: 24.h),
        _HorizontalMenu(items: horizontalMenuItems),
      ],
    );
  }
}

class _FeaturedActionCard extends StatelessWidget {
  const _FeaturedActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTransparent,
          borderRadius: BorderRadius.all(Radius.circular(16.r)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 38.w), // Reducido
            SizedBox(width: 16.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 16.w, // Reducido
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                      fontSize: 13.w, // Reducido
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: AppTheme.textSecondary, size: 15.w), // Reducido
          ],
        ),
      ),
    );
  }
}

class _HorizontalMenu extends StatelessWidget {
  const _HorizontalMenu({required this.items});

  final List<HorizontalMenuItem> items;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 90.h,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: items.map((item) {
          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8.w),
              child: _HorizontalMenuItemWidget(
                icon: item.icon,
                title: item.title,
                onTap: item.onTap,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HorizontalMenuItemWidget extends StatelessWidget {
  const _HorizontalMenuItemWidget({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Container(
        padding: EdgeInsets.all(8.w),
        decoration: BoxDecoration(
          color: AppTheme.surfaceTransparent,
          borderRadius: BorderRadius.all(Radius.circular(16.r)),
          boxShadow: AppTheme.cardShadow,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.primaryGold, size: 28.w), // Reducido
            SizedBox(height: 8.h),
            Text(
              title,
              style: textTheme.bodyLarge?.copyWith(fontSize: 13.w), // Reducido
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
