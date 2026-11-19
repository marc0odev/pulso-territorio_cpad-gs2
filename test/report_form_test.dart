import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:pulso_territorio/core/theme/app_theme.dart';
import 'package:pulso_territorio/core/utils/validators.dart';
import 'package:pulso_territorio/data/repositories/territory_repository.dart';
import 'package:pulso_territorio/data/services/local_store.dart';
import 'package:pulso_territorio/data/services/open_meteo_api.dart';
import 'package:pulso_territorio/data/services/simulated_city_api.dart';
import 'package:pulso_territorio/state/reports_provider.dart';
import 'package:pulso_territorio/state/settings_provider.dart';
import 'package:pulso_territorio/state/territory_provider.dart';
import 'package:pulso_territorio/ui/screens/report_form_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late LocalStore store;
  late ReportsProvider reports;

  Future<void> pumpForm(WidgetTester tester) async {
    tester.view.physicalSize = const Size(900, 2400);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
    final settings = SettingsProvider(store);
    reports = ReportsProvider(store);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider.value(value: settings),
          ChangeNotifierProvider.value(value: reports),
          ChangeNotifierProvider(
            create: (_) => TerritoryProvider(
              repository: TerritoryRepository(
                store: store,
                cityApi: const SimulatedCityApi(latency: Duration.zero),
                climateApi: OpenMeteoApi(),
              ),
              store: store,
              settings: settings,
            ),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: GoRouter(
            initialLocation: '/form',
            routes: [
              GoRoute(
                path: '/',
                builder: (_, _) => const Scaffold(body: Text('início')),
                routes: [
                  GoRoute(
                    path: 'form',
                    builder: (_, _) => const ReportFormScreen(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  testWidgets('envio vazio mostra os erros e não salva nada', (tester) async {
    await pumpForm(tester);

    await tester.tap(find.widgetWithText(FilledButton, 'Registrar ocorrência'));
    await tester.pumpAndSettle();

    expect(find.text('Escolha o tipo de ocorrência.'), findsOneWidget);
    expect(find.text(Validators.requiredMessage), findsOneWidget);
    expect(
      find.text('É preciso concordar para registrar a ocorrência.'),
      findsOneWidget,
    );
    expect(reports.reports, isEmpty);
  });

  testWidgets('descrição curta informa quantos caracteres faltam', (
    tester,
  ) async {
    await pumpForm(tester);

    await tester.enterText(find.byType(TextFormField).first, 'Vazamento');
    await tester.tap(find.widgetWithText(FilledButton, 'Registrar ocorrência'));
    await tester.pumpAndSettle();

    expect(find.textContaining('faltam 6'), findsOneWidget);
    expect(reports.reports, isEmpty);
  });

  testWidgets(
    'envio válido salva o relato anonimizado e volta à tela anterior',
    (tester) async {
      await pumpForm(tester);

      await tester.tap(find.text('Tipo de ocorrência *'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alagamento').last);
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextFormField).first,
        'Rua alagada desde cedo, avisar joao@exemplo.com',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.tap(
        find.widgetWithText(FilledButton, 'Registrar ocorrência'),
      );
      await tester.pumpAndSettle();

      expect(reports.reports, hasLength(1));
      final saved = reports.reports.single;
      expect(saved.category.label, 'Alagamento');
      expect(saved.description, isNot(contains('joao@exemplo.com')));
      expect(saved.anonymousCode, hasLength(4));
      expect(find.text('início'), findsOneWidget);
    },
  );
}
