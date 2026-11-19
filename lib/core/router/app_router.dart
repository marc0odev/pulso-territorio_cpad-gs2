import 'package:go_router/go_router.dart';

import '../../data/models/indicator.dart';
import '../../state/settings_provider.dart';
import '../../ui/screens/about_screen.dart';
import '../../ui/screens/alert_detail_screen.dart';
import '../../ui/screens/consent_screen.dart';
import '../../ui/screens/home_shell.dart';
import '../../ui/screens/indicator_detail_screen.dart';
import '../../ui/screens/not_found_screen.dart';
import '../../ui/screens/report_form_screen.dart';
import '../../ui/screens/settings_screen.dart';
import '../../ui/screens/thresholds_screen.dart';

/// Nomes das rotas: as telas navegam por nome, nunca por caminho literal.
class AppRoutes {
  const AppRoutes._();
  static const consent = 'consentimento';
  static const home = 'inicio';
  static const indicator = 'indicador';
  static const alert = 'alerta';
  static const newReport = 'nova-ocorrencia';
  static const thresholds = 'limiares';
  static const settings = 'configuracoes';
  static const about = 'sobre';

  /// Parâmetros de consulta da tela inicial.
  static const tabParam = 'aba';
  static const dashboardParam = 'painel';
}

/// Fluxo principal: visão geral → detalhe do indicador → detalhe do alerta.
/// Enquanto não houver consentimento, toda rota redireciona para a tela de
/// consentimento.
GoRouter buildRouter(SettingsProvider settings) => GoRouter(
  refreshListenable: settings,
  redirect: (context, state) {
    final atConsent = state.matchedLocation == '/consentimento';
    if (!settings.consentGiven) return atConsent ? null : '/consentimento';
    return atConsent ? '/' : null;
  },
  errorBuilder: (context, state) => const NotFoundScreen(),
  routes: [
    GoRoute(
      path: '/consentimento',
      name: AppRoutes.consent,
      builder: (context, state) => const ConsentScreen(),
    ),
    GoRoute(
      path: '/',
      name: AppRoutes.home,
      builder: (context, state) => HomeShell(
        tab: HomeTab.fromSlug(state.uri.queryParameters[AppRoutes.tabParam]),
        dashboard: DashboardKind.fromSlug(
          state.uri.queryParameters[AppRoutes.dashboardParam],
        ),
      ),
      routes: [
        GoRoute(
          path: 'indicador/:indicatorId',
          name: AppRoutes.indicator,
          builder: (context, state) => IndicatorDetailScreen(
            indicatorId: state.pathParameters['indicatorId']!,
          ),
        ),
        GoRoute(
          path: 'alerta/:alertId',
          name: AppRoutes.alert,
          builder: (context, state) =>
              AlertDetailScreen(alertId: state.pathParameters['alertId']!),
        ),
        GoRoute(
          path: 'ocorrencias/nova',
          name: AppRoutes.newReport,
          builder: (context, state) => const ReportFormScreen(),
        ),
        GoRoute(
          path: 'limiares',
          name: AppRoutes.thresholds,
          builder: (context, state) => const ThresholdsScreen(),
        ),
        GoRoute(
          path: 'configuracoes',
          name: AppRoutes.settings,
          builder: (context, state) => const SettingsScreen(),
        ),
        GoRoute(
          path: 'sobre',
          name: AppRoutes.about,
          builder: (context, state) => const AboutScreen(),
        ),
      ],
    ),
  ],
);
