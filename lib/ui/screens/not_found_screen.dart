import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/app_router.dart';
import '../widgets/state_views.dart';

/// Exibida quando o endereço não corresponde a nenhuma rota do app.
class NotFoundScreen extends StatelessWidget {
  const NotFoundScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: EmptyView(
          icon: Icons.explore_off_outlined,
          title: 'Página não encontrada',
          message: 'O endereço aberto não existe no app.',
          actionLabel: 'Ir para o início',
          actionIcon: Icons.home_outlined,
          onAction: () => context.goNamed(AppRoutes.home),
        ),
      ),
    );
  }
}
