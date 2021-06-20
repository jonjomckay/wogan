import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:wogan/database.dart';
import 'package:wogan/models/subscription.dart';

class SubscriptionModel extends ChangeNotifier {
  Future<void> deleteSubscription(String id) async {
    var database = await Database.writable();

    await database.delete(TABLE_SUBSCRIPTION, where: 'id = ?', whereArgs: [id]);

    notifyListeners();
  }

  Future<List<Subscription>> listSubscriptions() async {
    var database = await Database.writable();

    // await database.delete(TABLE_SUBSCRIPTION);

    return (await database.rawQuery('SELECT s.id, s.urn, s.title, s.description, s.image_url, s.subscribed_at, n.id AS n_id, n.urn AS n_urn, n.coverage AS n_coverage, n.short_title AS n_short_title, n.long_title AS n_long_title, n.logo_url AS n_logo_url FROM $TABLE_SUBSCRIPTION s LEFT JOIN $TABLE_STATION n ON n.id = s.network_id'))
        .map((e) => Subscription.fromMap(e))
        .toList(growable: false);
  }

  Future<void> saveSubscription(Subscription subscription) async {
    var database = await Database.writable();

    subscription.subscribedAt = DateTime.now();

    await database.insert(TABLE_SUBSCRIPTION, subscription.toMap(),
        conflictAlgorithm: sqflite.ConflictAlgorithm.replace);

    notifyListeners();
  }
}