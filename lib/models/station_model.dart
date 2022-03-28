import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:wogan/database.dart';
import 'package:wogan/models/station.dart';

class StationModel extends ChangeNotifier {
  Future<List<Station>> listStations() async {
    var database = await DB.readOnly();

    return (await database.query(TABLE_STATION))
        .map((e) => Station.fromMap(e))
        .toList(growable: false);
  }

  Future<void> saveStations(List<Station> stations) async {
    log('Saving stations');

    var database = await DB.writable();
    
    var batch = database.batch();

    // First, delete all the existing stations so we don't have any removed ones
    batch.delete(TABLE_STATION);

    // Then insert all the stations as new
    for (var station in stations) {
      batch.insert(TABLE_STATION, station.toMap());
    }

    await batch.commit();
  }
}