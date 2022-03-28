import 'dart:developer';

import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:sqflite_migration_plan/migration/sql.dart';
import 'package:sqflite_migration_plan/sqflite_migration_plan.dart';

const String DATABASE_NAME = 'wogan.db';

const String TABLE_POSITION = 'position';
const String TABLE_STATION = 'station';
const String TABLE_SUBSCRIPTION = 'subscription';

class DB {
  static Future<sqflite.Database> readOnly() async {
    return sqflite.openDatabase(DATABASE_NAME,
        readOnly: true, singleInstance: false);
  }

  static Future<sqflite.Database> writable() async {
    return sqflite.openDatabase(DATABASE_NAME);
  }

  Future<bool> migrate() async {
    MigrationPlan myMigrationPlan = MigrationPlan({
      2: [
        SqlMigration('''
CREATE TABLE IF NOT EXISTS $TABLE_STATION (
  id VARCHAR PRIMARY KEY,
  urn VARCHAR NOT NULL UNIQUE,
  coverage VARCHAR NOT NULL,
  short_title VARCHAR NOT NULL,
  long_title VARCHAR NOT NULL,
  logo_url VARCHAR NOT NULL
)
''', reverseSql: 'DROP TABLE $TABLE_STATION'),
      ],
      3: [
        SqlMigration('''
CREATE TABLE IF NOT EXISTS $TABLE_SUBSCRIPTION (
  id VARCHAR PRIMARY KEY,
  urn VARCHAR NOT NULL UNIQUE,
  title VARCHAR NOT NULL,
  description VARCHAR,
  network_id VARCHAR NOT NULL,
  image_url VARCHAR NOT NULL,
  subscribed_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (network_id) REFERENCES $TABLE_STATION (id)
)
''', reverseSql: 'DROP TABLE $TABLE_SUBSCRIPTION')
      ],
      4: [
        SqlMigration('''
CREATE TABLE IF NOT EXISTS $TABLE_POSITION (
  episode_id VARCHAR PRIMARY KEY,
  position INTEGER NOT NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
)
''', reverseSql: 'DROP TABLE $TABLE_POSITION')
      ]
    });

    await sqflite.openDatabase(DATABASE_NAME,
        version: 4,
        onUpgrade: myMigrationPlan,
        onCreate: myMigrationPlan,
        onDowngrade: myMigrationPlan);

    log('Finished migrating database');

    return true;
  }
}
