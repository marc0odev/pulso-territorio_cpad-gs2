/// Recorte territorial acompanhado pelo app (regiões do município de São Paulo).
class Region {
  const Region({
    required this.id,
    required this.name,
    required this.reference,
    required this.latitude,
    required this.longitude,
    required this.population,
  });

  final String id;
  final String name;

  /// Bairro usado como ponto de referência das coordenadas.
  final String reference;
  final double latitude;
  final double longitude;

  /// População aproximada (ordem de grandeza, valor ilustrativo).
  final int population;
}

class Regions {
  const Regions._();

  static const all = <Region>[
    Region(
      id: 'centro',
      name: 'Centro',
      reference: 'Sé',
      latitude: -23.5505,
      longitude: -46.6333,
      population: 430000,
    ),
    Region(
      id: 'norte',
      name: 'Zona Norte',
      reference: 'Tucuruvi',
      latitude: -23.4800,
      longitude: -46.6030,
      population: 2200000,
    ),
    Region(
      id: 'sul',
      name: 'Zona Sul',
      reference: 'Santo Amaro',
      latitude: -23.6540,
      longitude: -46.7100,
      population: 2700000,
    ),
    Region(
      id: 'leste',
      name: 'Zona Leste',
      reference: 'Itaquera',
      latitude: -23.5360,
      longitude: -46.4550,
      population: 4000000,
    ),
    Region(
      id: 'oeste',
      name: 'Zona Oeste',
      reference: 'Pinheiros',
      latitude: -23.5670,
      longitude: -46.7020,
      population: 1000000,
    ),
  ];

  static Region byId(String? id) =>
      all.firstWhere((r) => r.id == id, orElse: () => all.first);
}
