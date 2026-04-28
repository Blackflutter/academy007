import 'package:academy007/core/theme/app_theme.dart';
import 'package:academy007/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: 'https://iwcgylnlfomtxvypvyzc.supabase.co',
    anonKey: 'sb_publishable_iIl04niVpN_RW3LrmJIShQ_NpuC5olA',
  );

  runApp(const FutevoluiApp());
}

class FutevoluiApp extends StatelessWidget {
  const FutevoluiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(theme: AppTheme.theme, home: const LoginScreen());
  }
}
