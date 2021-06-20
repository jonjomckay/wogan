class Station {
  String id;
  String urn;
  String coverage;
  String shortTitle;
  String longTitle;
  String logoUrl;

  Station(
      {required this.id,
      required this.urn,
      required this.coverage,
      required this.shortTitle,
      required this.longTitle,
      required this.logoUrl});

  factory Station.fromMap(Map<String, dynamic> map) {
    int i = 0;

    return Station(
        id: map['id'],
        urn: map['urn'],
        coverage: map['coverage'],
        shortTitle: map['short_title'],
        longTitle: map['long_title'],
        logoUrl: map['logo_url']
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'urn': urn,
      'coverage': coverage,
      'short_title': shortTitle,
      'long_title': longTitle,
      'logo_url': logoUrl
    };
  }
}
