import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:pulso_territorio/data/models/alert.dart';
import 'package:pulso_territorio/data/models/thresholds.dart';
import 'package:pulso_territorio/data/repositories/territory_repository.dart';
import 'package:pulso_territorio/data/services/alert_notifier.dart';
import 'package:pulso_territorio/data/services/local_store.dart';
import 'package:pulso_territorio/data/services/open_meteo_api.dart';
import 'package:pulso_territorio/data/services/simulated_city_api.dart';
import 'package:pulso_territorio/state/notifications_provider.dart';
import 'package:pulso_territorio/state/settings_provider.dart';
import 'package:pulso_territorio/state/territory_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Notificador em memória: registra o que seria exibido.
class FakeNotifier implements AlertNotifier {
  FakeNotifier({this.grant = true});

  final bool grant;
  final shown = <String>[];

  @override
  Future<void> init({required void Function(String alertId) onOpen}) async {}

  @override
  Future<bool> requestPermission() async => grant;

  @override
  Future<void> show(TerritoryAlert alert, {required String regionName}) async {
    shown.add(alert.id);
  }
}

void main() {
  late LocalStore store;
  late SettingsProvider settings;
  late TerritoryProvider territory;

  // Limiares altos: nenhum alerta com os dados municipais simulados.
  const calm = Thresholds(
    water: 9999,
    rain: 9999,
    heat: 99,
    pm25: 9999,
    wastePercent: 999,
    servicesGrowthPercent: 999,
  );

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    store = LocalStore(await SharedPreferences.getInstance());
    settings = SettingsProvider(store);
    await settings.setThresholds(calm);
    territory = TerritoryProvider(
      repository: TerritoryRepository(
        store: store,
        cityApi: const SimulatedCityApi(latency: Duration.zero),
        // Sem internet nos testes: o clima falha e só os dados municipais
        // entram no cálculo.
        climateApi: OpenMeteoApi(
          client: MockClient((_) async => http.Response('', 500)),
        ),
      ),
      store: store,
      settings: settings,
    );
    await territory.load();
  });

  NotificationsProvider build(FakeNotifier notifier) => NotificationsProvider(
    store: store,
    territory: territory,
    notifier: notifier,
    onOpenAlert: (_) {},
  );

  test('começa desligado e não avisa nada', () async {
    final notifier = FakeNotifier();
    final notifications = build(notifier);
    await settings.setThresholds(const Thresholds(water: 1));
    expect(notifications.enabled, isFalse);
    expect(notifier.shown, isEmpty);
  });

  test('avisa uma vez quando surge um alerta novo', () async {
    final notifier = FakeNotifier();
    final notifications = build(notifier);
    expect(await notifications.setEnabled(true), isTrue);

    // Limiar de água muito baixo: o consumo passa a disparar alerta.
    await settings.setThresholds(
      const Thresholds(
        water: 1,
        rain: 9999,
        heat: 99,
        pm25: 9999,
        wastePercent: 999,
        servicesGrowthPercent: 999,
      ),
    );
    expect(notifier.shown, ['${territory.selectedRegion.id}-agua']);

    // Recarregar os mesmos dados não repete o aviso.
    await territory.load();
    expect(notifier.shown, hasLength(1));
    expect(
      store.readJson(LocalStore.notifiedAlertsKey),
      contains(startsWith('${territory.selectedRegion.id}-agua')),
    );
  });

  test('permissão negada mantém a opção desligada', () async {
    final notifications = build(FakeNotifier(grant: false));
    expect(await notifications.setEnabled(true), isFalse);
    expect(notifications.enabled, isFalse);
    expect(store.readBool(LocalStore.notificationsKey), isFalse);
  });
}
