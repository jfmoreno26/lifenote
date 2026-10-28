import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'screens/auth_screen.dart';
import 'screens/shell.dart';
import 'services/alert_service.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/settings_service.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final prefs = await SharedPreferences.getInstance();
  runApp(MyApp(prefs: prefs));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.prefs});

  final SharedPreferences prefs;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SettingsService(prefs)),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProxyProvider<AuthService, DataService>(
          create: (_) => DataService(),
          update: (_, auth, data) => data!..bind(auth.user?.uid),
        ),
        ChangeNotifierProvider(
          create: (ctx) => AlertService(ctx.read<DataService>(), ctx.read<AuthService>(), ctx.read<SettingsService>()),
        ),
      ],
      child: Consumer<SettingsService>(
        builder: (context, settings, _) => MaterialApp(
          title: 'LifeNote',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          darkTheme: AppTheme.dark(),
          themeMode: settings.themeMode,
          home: const AuthGate(),
        ),
      ),
    );
  }
}

/// Shows the sign-in flow or the app depending on auth state.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();
    if (auth.initializing) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    if (auth.user == null) return const AuthScreen();
    return Shell(key: ValueKey(auth.user!.uid));
  }
}
