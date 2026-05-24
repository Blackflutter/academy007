import 'package:academy007/core/router/app_routes.dart';
import 'package:academy007/core/theme/app_theme.dart';
import 'package:academy007/data/sources/alarmenotification.dart';
import 'package:academy007/presentation/screens/cadastro_plano_alimentar_screen.dart';
import 'package:academy007/presentation/screens/login_screen.dart';
import 'package:academy007/presentation/screens/registro_screen.dart';
import 'package:academy007/presentation/screens/treino_screen.dart';
import 'package:academy007/presentation/screens/historico_screen.dart';
import 'package:academy007/main_screens.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 🟢 NOVAS IMPORTAÇÕES PARA OS ALARMES
import 'package:academy007/data/sources/notification.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://iwcgylnlfomtxvypvyzc.supabase.co',
    anonKey: 'sb_publishable_iIl04niVpN_RW3LrmJIShQ_NpuC5olA',
  );

  // 🟢 VERIFICAÇÃO AUTOMÁTICA DE SESSÃO:
  final session = Supabase.instance.client.auth.currentSession;
  final bool usuarioEstaLogado = session != null;

  // 🟢 CONFIGURAÇÃO DOS ALARMES SE O USUÁRIO JÁ ESTIVER LOGADO
  if (usuarioEstaLogado) {
    try {
      // 1. Inicializa o serviço e pede as permissões na tela do celular
      final notificacoes = NotificacoesService();
      await notificacoes.inicializar();

      // 2. Busca os horários do banco e agenda os beeps locais
      final alarmeController = AlarmeController();
      await alarmeController.sincronizarAlarmesAluno();
    } catch (e) {
      print('Erro ao carregar alarmes na inicialização: $e');
    }
  }

  // Passa o resultado da checagem para inicializar o Widget do App
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

      initialRoute: iniciarLogado ? AppRoutes.main : AppRoutes.login,

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
