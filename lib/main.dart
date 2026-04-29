import 'package:academy007/core/router/app_routes.dart';
import 'package:academy007/core/theme/app_theme.dart';
import 'package:academy007/presentation/screens/cadastro_plano_alimentar_screen.dart';
import 'package:academy007/presentation/screens/login_screen.dart';
import 'package:academy007/presentation/screens/registro_screen.dart';
import 'package:academy007/presentation/screens/treino_screen.dart';
import 'package:academy007/presentation/screens/historico_screen.dart';
import 'package:academy007/main_screens.dart'; // Onde fica seu BottomNavigationBar
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iwcgylnlfomtxvypvyzc.supabase.co',
    anonKey: 'sb_publishable_iIl04niVpN_RW3LrmJIShQ_NpuC5olA',
  );

  runApp(const Academy007App());
}

class Academy007App extends StatelessWidget {
  const Academy007App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academy 007',
      theme: AppTheme.theme,
      initialRoute: AppRoutes.login, // Usando a constante

      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.registro: (context) => const RegistroScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.historico: (context) => const HistoricoScreen(),
        AppRoutes.cadastroPlanoAlimentar: (context) =>
            const CadastroPlanoAlimentarScreen(),
      },

      onGenerateRoute: (settings) {
        if (settings.name == AppRoutes.treino) {
          final int id = settings.arguments as int;
          return MaterialPageRoute(
            builder: (context) => TreinoScreen(categoriaId: id),
          );
        }
        return null;
      },
    );
  }
}
