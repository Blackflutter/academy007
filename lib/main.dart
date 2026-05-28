import 'package:academy007/core/router/app_routes.dart';
import 'package:academy007/core/theme/app_theme.dart';
import 'package:academy007/presentation/screens/assinatura_screen.dart'; // ← Adicionado
import 'package:academy007/presentation/screens/cadastro_plano_alimentar_screen.dart';
import 'package:academy007/presentation/screens/login_screen.dart';
import 'package:academy007/presentation/screens/registro_screen.dart';
import 'package:academy007/presentation/screens/treino_screen.dart';
import 'package:academy007/presentation/screens/historico_screen.dart';
import 'package:academy007/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iwcgylnlfomtxvypvyzc.supabase.co',
    anonKey: 'sb_publishable_iIl04niVpN_RW3LrmJIShQ_NpuC5olA',
  );

  final session = Supabase.instance.client.auth.currentSession;
  final bool usuarioEstaLogado = session != null;

  runApp(Academy007App(iniciarLogado: usuarioEstaLogado));
}

class Academy007App extends StatelessWidget {
  final bool iniciarLogado;

  const Academy007App({super.key, required this.iniciarLogado});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Academy 007',
      theme: AppTheme.theme,
      debugShowCheckedModeBanner: false,

      initialRoute: iniciarLogado ? AppRoutes.main : AppRoutes.login,

      routes: {
        AppRoutes.login: (context) => const LoginScreen(),
        AppRoutes.registro: (context) => const RegistroScreen(),
        AppRoutes.main: (context) => const MainScreen(),
        AppRoutes.historico: (context) => const HistoricoScreen(),
        AppRoutes.cadastroPlanoAlimentar: (context) =>
            const CadastroPlanoAlimentarScreen(),
        AppRoutes.assinatura: (context) =>
            const AssinaturaScreen(), // ← Adicionado
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
