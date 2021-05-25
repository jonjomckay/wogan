import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:pref/pref.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:wogan/api/client.dart';
import 'package:wogan/constants.dart';
import 'package:wogan/home_search_screen.dart';
import 'package:wogan/search/search_delegate.dart';

import 'home_live_screen.dart';

late AudioHandler _audioHandler;

// TODO
AudioHandler getAudioHandler() {
  return _audioHandler;
}

void main() async {
  timeago.setLocaleMessages('en', BbcSoundsMessages());

  WidgetsFlutterBinding.ensureInitialized();

  final service = await PrefServiceShared.init(
    defaults: {
      OPTION_STREAM_QUALITY: 128000,
    },
  );

  final session = await AudioSession.instance;
  await session.configure(AudioSessionConfiguration.music());

  _audioHandler = await AudioService.init(
    builder: () => MyAudioHandler(),
    config: AudioServiceConfig(
      androidNotificationChannelName: 'Wogan',
      androidEnableQueue: true,
    ),
  );

  runApp(PrefService(
    service: service,
    child: MyApp(),
  ));
}

class MyAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  MyAudioHandler() {
    // Broadcast which item is currently playing
    // _player.currentIndexStream.listen((index) {
    //   var queueValue = queue.value;
    //   if (index == null || queueValue == null) {
    //     return;
    //   }
    //
    //   if (queueValue.isNotEmpty) {
    //     mediaItem.add(queueValue[index]);
    //   }
    // });

    _player.currentIndexStream.listen((index) {
      if (index != null) {
        mediaItem.add(queue.value![index]);
      }
    });

    _player.sequenceStream.listen((event) {
      var queueValue = queue.value;
      if (queueValue == null) {
        return;
      }

      if (queueValue.isNotEmpty) {
        mediaItem.add(queueValue.first);
      }
    });

    var onEvent = () {
      var state = playbackState.value;
      if (state == null) {
        return;
      }

      playbackState.add(state.copyWith(
        controls: [
          MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          MediaControl.skipToNext,
        ],
        androidCompactActionIndices: [0, 1, 2],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState]!,
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));

      var item = mediaItem.value;
      if (item == null) {
        return;
      }

      mediaItem.add(item.copyWith(
        duration: _player.duration
      ));
    };

    _player.durationStream.listen((event) {
      onEvent();
    });

    _player.positionStream.listen((event) {
      onEvent();
    });

    // Broadcast the current playback state and what controls should currently
    // be visible in the media notification
    _player.playbackEventStream.listen((event) {
      onEvent();
    });
  }

  play() => _player.play();

  pause() => _player.pause();

  @override
  seek(Duration position) => _player.seek(position);

  seekTo(Duration position) => _player.seek(position);

  stop() async {
    await _player.stop();
    await super.stop();
  }

  @override
  Future playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
    var client = SoundsApi();
    var quality = (await SharedPreferences.getInstance())
        .getInt(OPTION_STREAM_QUALITY)!;

    Uri playbackUri;

    switch (uri.scheme) {
      case 'programme':
        playbackUri = await client.getProgrammePlaybackUri(uri.host, quality);
        break;
      case 'station':
        playbackUri = Uri.parse('http://as-hls-uk-live.akamaized.net/pool_904/live/uk/${uri.host}/${uri.host}.isml/${uri.host}-audio%3d${quality}.m3u8');
        break;
      default:
        log('The playback URI $uri is not supported');
        return;
    }

    // If we're already playing the same programme or station, continue from the same position
    var position = playbackState.value?.position;
    var seekBack = position != null && this.mediaItem.value?.id == uri.toString();

    log('Playing $playbackUri');

    var mediaItem = MediaItem(
      id: uri.toString(),
      title: extras!['title'],
      artist: extras['artist'],
      album: extras['album'],
      duration: extras['duration'],
      artUri: extras['artUri'],
    );

    await updateQueue([mediaItem]);

    await _player.setUrl(playbackUri.toString());

    // If we're already playing the same programme or station, continue from the same position
    if (seekBack) {
      log('Seeking back to $position');

      await seek(position!);
    }

    await play();
  }

  @override
  Future<dynamic> customAction(String name, Map<String, dynamic>? arguments) async {
    switch (name) {
      case 'changeQuality':
        var item = mediaItem.value;
        if (item != null) {
          await playFromUri(Uri.parse(item.id), {
            'title': item.title,
            'artist': item.artist,
            'album': item.album,
            'duration': item.duration,
            'artUri': item.artUri
          });
        }

        break;
      case 'setVolume':
        _player.setVolume(arguments!['volume']);
        break;
    }
  }
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.deepOrange,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,

        // TODO: These are only required due to https://github.com/flutter/flutter/issues/19089
        accentColor: Colors.deepOrange[500],
        toggleableActiveColor: Colors.deepOrange[500],
        textSelectionColor: Colors.deepOrange[200],
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  List<Widget> _children = [
    HomeLiveScreen(),
    Text('not yet'),
    HomeSearchScreen(),
  ];


  @override
  void initState() {
    super.initState();

    PrefService.of(context, listen: false)
        .addKeyListener(OPTION_STREAM_QUALITY, this.onChangeQuality);
  }

  void onChangeQuality() {
    getAudioHandler().customAction('changeQuality', null);
  }

  @override
  void dispose() {
    PrefService.of(context, listen: false)
        .removeKeyListener(OPTION_STREAM_QUALITY, this.onChangeQuality);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var bottomSheetHeight = 64.0;

    return StreamBuilder<MediaItem?>(
      stream: getAudioHandler().mediaItem,
      builder: (context, snapshot) {
        Widget player = Container(height: 0);
        EdgeInsets padding = EdgeInsets.zero;

        var data = snapshot.data;
        if (data != null) {
          padding = EdgeInsets.only(bottom: bottomSheetHeight);
          player = Container(
            color: Theme.of(context).cardColor,
            height: bottomSheetHeight,
            padding: EdgeInsets.symmetric(horizontal: 16),
            width: MediaQuery.of(context).size.width,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: Text(data.title),
                      ),
                      Container(
                        margin: EdgeInsets.symmetric(vertical: 2),
                        child: Text(data.album, style: TextStyle(
                            color: Theme.of(context).hintColor
                        )),
                      ),
                    ],
                  ),
                ),
                StreamBuilder<PlaybackState>(
                  stream: getAudioHandler().playbackState,
                  builder: (context, snapshot) {
                    var state = snapshot.data;
                    if (state == null) {
                      return Container();
                    }

                    if (state.playing) {
                      return IconButton(
                        icon: Icon(Icons.pause_circle_outline, size: 44),
                        onPressed: () async => await getAudioHandler().pause(),
                      );
                    }

                    return IconButton(
                      icon: Icon(Icons.play_circle_outline, size: 44),
                      onPressed: () async => await getAudioHandler().play(),
                    );
                  },
                )
              ],
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Wogan'),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(context: context, delegate: SoundsSearchDelegate());
                },
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (value) {
              setState(() {
                _currentIndex = value;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Live'),
              BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Music'),
              BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
            ],
          ),
          bottomSheet: player,
          body: Container(
            padding: padding,
            child: _children[_currentIndex],
          ),
        );
      },
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
