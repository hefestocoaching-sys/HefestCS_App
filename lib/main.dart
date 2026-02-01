import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:hefestocs/navigation_provider.dart';
import 'package:hefestocs/providers/charts_navigation_provider.dart';
import 'package:hefestocs/providers/client_store.dart';
import 'package:hefestocs/providers/nutrition_navigation_provider.dart';
import 'package:hefestocs/providers/progress_photos_provider.dart';
import 'package:hefestocs/providers/session_provider.dart';
import 'package:hefestocs/providers/training_navigation_provider.dart';
import 'package:hefestocs/widgets/app_bootstrap.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:hefestocs/config/app_config.dart';
import 'package:hefestocs/constants/colors.dart';
import 'package:hefestocs/gen_l10n/l10n.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // ⚙️ generado automáticamente por FlutterFire CLI

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 🔥 Inicializa Firebase antes de arrancar la app
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // 🌎 Inicializa formato de fechas en español
  await initializeDateFormatting('es_ES', null);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SessionProvider()),
        ChangeNotifierProvider(create: (_) => ClientStore()..load()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ProgressPhotosProvider()),
        ChangeNotifierProvider(create: (_) => TrainingNavigationProvider()),
        ChangeNotifierProvider(create: (_) => NutritionNavigationProvider()),
        ChangeNotifierProvider(create: (_) => ChartsNavigationProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        minTextAdapt: false,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: AppBrand.name,
            debugShowCheckedModeBanner: false,

            // 🌎 Localización
            localizationsDelegates: const [
              S.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: S.supportedLocales,
            locale: const Locale('es', 'MX'),

            theme: _buildTheme(),
            home: child,
          );
        },
        child: const AppBootstrap(),
      ),
    );
  }

  ThemeData _buildTheme() {
    const colorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: AppTheme.primaryGold,
      onPrimary: Colors.black,
      secondary: AppTheme.primaryGold,
      onSecondary: Colors.black,
      error: Colors.redAccent,
      onError: Colors.white,
      surface: AppTheme.wrapperBackground,
      onSurface: AppTheme.textPrimary,
    );

    final baseTheme = ThemeData.from(
      colorScheme: colorScheme,
      useMaterial3: true,
      textTheme: ThemeData.dark().textTheme.apply(fontFamily: 'Roboto'),
    );

    return baseTheme.copyWith(
      scaffoldBackgroundColor: colorScheme.surface,
      appBarTheme: baseTheme.appBarTheme.copyWith(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: 'FINALOLD',
          fontSize: 24.w,
          color: AppTheme.textPrimary,
        ),
        iconTheme: const IconThemeData(color: AppTheme.textPrimary),
      ),
      snackBarTheme: baseTheme.snackBarTheme.copyWith(
        backgroundColor: AppTheme.surface,
        contentTextStyle: TextStyle(
          color: AppTheme.textPrimary,
          fontFamily: 'Roboto',
          fontSize: 13.w,
        ),
        actionTextColor: AppTheme.primaryGold,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        hintStyle: TextStyle(
          color: Colors.black54,
          fontFamily: 'Roboto',
          fontSize: 15.w,
        ),
        contentPadding: EdgeInsets.symmetric(vertical: 16.h, horizontal: 20.w),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppTheme.primaryGold, width: 2.w),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10.r),
          borderSide: BorderSide(color: AppTheme.primaryGold, width: 3.w),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 16.h),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10.r)),
          backgroundColor: AppTheme.primaryGold,
          foregroundColor: Colors.black,
          textStyle: TextStyle(
            fontSize: 15.w,
            fontWeight: FontWeight.bold,
            fontFamily: 'Roboto',
          ),
        ),
      ),
    );
  }
}
