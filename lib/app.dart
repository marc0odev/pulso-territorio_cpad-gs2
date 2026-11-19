import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'data/repositories/territory_repository.dart';
import 'data/services/alert_notifier.dart';
import 'data/services/local_store.dart';
import 'data/services/open_meteo_api.dart';
import 'data/services/simulated_city_api.dart';
import 'state/decisions_provider.dart';
import 'state/notifications_provider.dart';
import 'state/reports_provider.dart';
import 'state/settings_provider.dart';
import 'state/territory_provider.dart';

const kAppName = 'Pulso do Território';

/// Raiz do app: monta as dependências, o estado global e o roteador.
class PulsoApp extends StatefulWidget {
  const PulsoApp({
    super.key,
    required this.store,
    this.repository,
    this.notifier,
  });

  final LocalStore store;

  /// Permite injetar um repositório falso nos testes.
  final TerritoryRepository? repository;

  /// Permite injetar um notificador em memória nos testes.
  final AlertNotifier? notifier;

  @override
  State<PulsoApp> createState() => _PulsoAppState();
}

class _PulsoAppState extends State<PulsoApp> {
  late final SettingsProvider _settings = SettingsProvider(widget.store);
  late final TerritoryProvider _territory = TerritoryProvider(
    repository:
        widget.repository ??
        TerritoryRepository(
          store: widget.store,
          cityApi: const SimulatedCityApi(),
          climateApi: OpenMeteoApi(),
        ),
    store: widget.store,
    settings: _settings,
  );
  late final ReportsProvider _reports = ReportsProvider(widget.store);
  late final DecisionsProvider _decisions = DecisionsProvider(widget.store);
  late final GoRouter _router = buildRouter(_settings);
  late final NotificationsProvider _notifications = NotificationsProvider(
    store: widget.store,
    territory: _territory,
    notifier: widget.notifier ?? LocalAlertNotifier(),
    // Tocar no aviso abre direto o detalhe do alerta.
    onOpenAlert: (alertId) => _router.pushNamed(
      AppRoutes.alert,
      pathParameters: {'alertId': alertId},
    ),
  );

  @override
  void initState() {
    super.initState();
    // Cria o observador de alertas antes da primeira carga de dados.
    _notifications.enabled;
    _territory.load();
  }

  @override
  void dispose() {
    _router.dispose();
    _notifications.dispose();
    _territory.dispose();
    _reports.dispose();
    _decisions.dispose();
    _settings.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _settings),
        ChangeNotifierProvider.value(value: _territory),
        ChangeNotifierProvider.value(value: _reports),
        ChangeNotifierProvider.value(value: _decisions),
        ChangeNotifierProvider.value(value: _notifications),
      ],
      child: MaterialApp.router(
        title: kAppName,
        debugShowCheckedModeBanner: false,
        routerConfig: _router,
        // Um único tema visual; o alto contraste entra sozinho quando o
        // aparelho está com essa opção de acessibilidade ligada.
        theme: AppTheme.light(),
        themeMode: ThemeMode.light,
        highContrastTheme: AppTheme.highContrast(),
        highContrastDarkTheme: AppTheme.highContrast(),
      ),
    );
  }
}
