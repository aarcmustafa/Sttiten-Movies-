import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart'; // إضافة دعم اللغة
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'core/device_id.dart';
import 'features/splash/splash_screen.dart';
import 'features/movies/providers/movies_provider.dart';
import 'features/series/providers/series_provider.dart';
import 'features/favorites/providers/favorites_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  ErrorWidget.builder = (FlutterErrorDetails details) {
    return Material(
      color: Colors.black,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text(
            'حدث خطأ تقني:\n\n${details.exceptionAsString()}\n\nمكان الخطأ:\n${details.stack}',
            style: const TextStyle(color: Colors.red, fontSize: 12, fontFamily: 'monospace'),
            textDirection: TextDirection.ltr,
          ),
        ),
      ),
    );
  };

  await DeviceIdManager.getDeviceId();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );
  runApp(const SttitenMoviesApp());
}

class SttitenMoviesApp extends StatelessWidget {
  const SttitenMoviesApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MoviesProvider()),
        ChangeNotifierProvider(create: (_) => SeriesProvider()),
        ChangeNotifierProvider(create: (_) => FavoritesProvider()),
      ],
      child: MaterialApp(
        title: 'Sttiten Movies',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        locale: const Locale('ar'),
        supportedLocales: const [Locale('ar'), Locale('en')],
        // إضافة دعم اللغة العربية هنا:
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        builder: (context, child) {
          return Directionality(
            textDirection: TextDirection.rtl,
            child: child ?? const SizedBox.shrink(),
          );
        },
        home: const SplashScreen(),
      ),
    );
  }
}
// Force build trigger
