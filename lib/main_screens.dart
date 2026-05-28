import 'package:academy007/presentation/screens/dashboard_screen.dart';
import 'package:academy007/presentation/screens/historico_treino_aluno.dart';
import 'package:academy007/presentation/screens/nutricao_screen.dart';
import 'package:academy007/presentation/screens/perfil_screen.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/router/app_routes.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final SupabaseClient supabase = Supabase.instance.client;

  int _currentIndex = 0;
  bool _isCheckingPlano = true;

  final List<Widget> _paginas = const [
    DashboardScreen(),
    NutricaoScreen(),
    HistoricoAlunosScreen(),
    PerfilScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _verificarAssinatura();
  }

  Future<void> _verificarAssinatura() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final perfil = await supabase
          .from('perfis')
          .select()
          .eq('id', user.id)
          .single();

      final academiaId = perfil['academia_id'];

      if (academiaId != null) {
        final assinatura = await supabase
            .from('assinaturas')
            .select()
            .eq('academia_id', academiaId)
            .eq('status', 'ativo')
            .maybeSingle();

        if (assinatura == null) {
          if (mounted) {
            Navigator.pushReplacementNamed(context, AppRoutes.assinatura);
          }
          return;
        }
      }
    } catch (_) {}

    if (mounted) {
      setState(() => _isCheckingPlano = false);
    }
  }

  Future<void> _fazerLogout(BuildContext context) async {
    try {
      await supabase.auth.signOut();
      if (context.mounted) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.login);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao sair: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingPlano) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _paginas),
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          labelTextStyle: WidgetStateProperty.all(
            const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) =>
              setState(() => _currentIndex = index),
          backgroundColor: AppTheme.glassColor,
          indicatorColor: AppTheme.primaryNeon,
          surfaceTintColor: Colors.transparent,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: Colors.black),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.food_bank_outlined),
              selectedIcon: Icon(Icons.fitness_center, color: Colors.black),
              label: 'Food',
            ),
            NavigationDestination(
              icon: Icon(Icons.history),
              selectedIcon: Icon(Icons.history, color: Colors.black),
              label: 'Histórico',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person, color: Colors.black),
              label: 'Perfil',
            ),
          ],
        ),
      ),
    );
  }
}
