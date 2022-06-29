import 'dart:developer';

import 'package:audio_session/audio_session.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:pref/pref.dart';
import 'package:provider/provider.dart';
import 'package:rxdart/rxdart.dart';
import 'package:sqflite/sqflite.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wogan/constants.dart';
import 'package:wogan/database.dart';
import 'package:wogan/home/home_screen.dart';
import 'package:wogan/models/station_model.dart';
import 'package:wogan/models/subscription_model.dart';

late AudioPlayer _audioPlayer;

// TODO
AudioPlayer getAudioPlayer() {
  return _audioPlayer;
}

void main() async {
  timeago.setLocaleMessages('en', BbcSoundsMessages());

  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  final service = await PrefServiceShared.init(
    defaults: {
      OPTION_STREAM_QUALITY: 128000,
    },
  );

  // Run the database migrations
  try {
    final database = DB();
    await database.migrate();

    log('Completed');
  } catch (e, stackTrace) {
    log('Unable to run the database migrations', error: e, stackTrace: stackTrace);
  }

  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  _audioPlayer = AudioPlayer(androidOffloadSchedulingEnabled: true);

  // TODO: Extract all this out somewhere
  _audioPlayer.positionStream.throttleTime(Duration(seconds: 5)).listen((position) async {
    // Every few seconds, store the current position of the playing episode
    var item = _audioPlayer.sequenceState?.currentSource?.tag as MediaItem?;
    if (item == null) {
      return;
    }

    var database = await DB.writable();

    await database.insert(TABLE_POSITION, {
      'episode_id': Uri.parse(item.id).host,
      'position': position.inSeconds,
      'updated_at': DateTime.now().millisecondsSinceEpoch
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  });

  await JustAudioBackground.init(
    androidNotificationChannelId: 'com.jonjomckay.wogan',
    androidNotificationChannelName: 'Audio playback',
    androidNotificationOngoing: true,
  );

  runApp(PrefService(
    service: service,
    child: DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => WoganApp(),
    ),
  ));
}

class WoganApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const baseColour = Colors.deepOrange;

    return MaterialApp(
      title: 'Wogan',
      locale: DevicePreview.locale(context),
      builder: DevicePreview.appBuilder,
      theme: ThemeData(
        primarySwatch: baseColour,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: baseColour,

        // TODO: These are only required due to https://github.com/flutter/flutter/issues/19089
        accentColor: baseColour[500],
        toggleableActiveColor: baseColour[500],
        textSelectionColor: baseColour[200],
      ),
      themeMode: ThemeMode.system,
      home: MultiProvider(
        child: HomeScreen(),
        providers: [
          ChangeNotifierProvider(create: (context) => StationModel()),
          ChangeNotifierProvider(create: (context) => SubscriptionModel()),
        ],
      ),
    );
  }
}

class BbcSoundsMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => '';

  @override
  String suffixAgo() => '';

  @override
  String suffixFromNow() => '';

  @override
  String lessThanOneMinute(int seconds) => 'less than 1 min';

  @override
  String aboutAMinute(int minutes) => '1 min';

  @override
  String minutes(int mins) => '$mins mins';

  @override
  String aboutAnHour(int mins) => minutes(mins);

  @override
  String hours(int hours) => '$hours hours';

  @override
  String aDay(int hours) => '~1 d';

  @override
  String days(int days) => '$days d';

  @override
  String aboutAMonth(int days) => '~1 mo';

  @override
  String months(int months) => '$months mo';

  @override
  String aboutAYear(int year) => '~1 yr';

  @override
  String years(int years) => '$years yr';

  @override
  String wordSeparator() => ' ';
}
