import 'package:wogan/models/station.dart';

class Subscription {
  String id;
  String urn;
  String title;
  String? description;
  Station network;
  String imageUrl;
  DateTime? subscribedAt;

  Subscription(
      {required this.id,
      required this.urn,
      required this.title,
      required this.description,
      required this.network,
      required this.imageUrl,
      required this.subscribedAt});

  factory Subscription.fromMap(Map<String, dynamic> map) {
    int i = 0;

    return Subscription(
      id: map['id'] as String,
      urn: map['urn'] as String,
      title: map['title'] as String,
      description: map['description'] as String?,
      network: Station.fromMap({
        'id': map['n_id'],
        'urn': map['n_urn'],
        'coverage': map['n_coverage'],
        'short_title': map['n_short_title'],
        'long_title': map['n_long_title'],
        'logo_url': map['n_logo_url']
      }),
      imageUrl: map['image_url'] as String,
      subscribedAt: DateTime.fromMillisecondsSinceEpoch(map['subscribed_at']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'urn': urn,
      'title': title,
      'description': description,
      'network_id': network.id,
      'image_url': imageUrl,
      'subscribed_at': subscribedAt?.millisecondsSinceEpoch
    };
  }
}