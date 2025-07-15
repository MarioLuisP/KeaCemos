import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';          
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:quehacemos_cba/l10n/intl_messages_all.dart';
import 'package:provider/provider.dart';
import 'package:quehacemos_cba/src/navigation/bottom_nav.dart';
import 'package:quehacemos_cba/src/providers/preferences_provider.dart';
import 'package:quehacemos_cba/src/themes/themes.dart';
import 'package:quehacemos_cba/src/providers/favorites_provider.dart';
import 'package:quehacemos_cba/src/providers/home_viewmodel.dart';
import 'package:quehacemos_cba/src/providers/mock_auth_provider.dart';  // CAMBIO: MockAuthProvider en lugar de AuthProvider
import 'package:quehacemos_cba/src/providers/notifications_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await DatabaseHelper.deleteDatabase(); //Solo una vez para resetear db 🔥
  await Firebase.initializeApp();
  await initializeMessages('es');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) {
          final provider = PreferencesProvider();
          provider.init();
          return provider;
        },
      ),
      ChangeNotifierProvider(create: (context) => FavoritesProvider()..init()),
      ChangeNotifierProvider(
        create: (context) {
          print('🏗️ Creando HomeViewModel...');
          final viewModel = HomeViewModel();
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            print('🚀 Auto-inicializando HomeViewModel...');
            await viewModel.initialize();
            print('✅ HomeViewModel inicializado con ${viewModel.filteredEvents.length} eventos');
          });
          return viewModel;
        },
      ),
      // CAMBIO: MockAuthProvider en lugar de AuthProvider
      ChangeNotifierProvider(create: (context) => MockAuthProvider()),
      // NUEVO: Agregar NotificationsProvider  
      ChangeNotifierProvider(create: (context) => NotificationsProvider()),
    ],
      child: Consumer<PreferencesProvider>(
        builder: (context, provider, _) {
          return MaterialApp(
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('es', ''), Locale('en', '')],
            title: 'QuehaCeMos Córdoba',
            theme:
                AppThemes.themes[provider.theme] ??
                ThemeData(
                  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
                  useMaterial3: true,
                  appBarTheme: const AppBarTheme(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                  ),
                ),
            home: const MainScreen(),
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}