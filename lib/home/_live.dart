import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:just_audio/just_audio.dart';
import 'package:just_audio_background/just_audio_background.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:wogan/api/client.dart';
import 'package:wogan/constants.dart';
import 'package:wogan/database.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/player_screen.dart';
import 'package:wogan/ui/image.dart';
import 'package:wogan/ui/timeago.dart';

class HomeLiveScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeLiveScreenState();
}

Future<dynamic> changeQuality() async {
  var item = getAudioPlayer().sequenceState?.currentSource?.tag as MediaItem?;
  if (item == null) {
    return;
  }

  await playFromUri(Uri.parse(item.id), {
    'title': item.title,
    'artist': item.artist,
    'album': item.album,
    'duration': item.duration,
    'artUri': item.artUri,
    'metadata': ProgrammeMetadata.fromMap(item.extras!['metadata'])
  });
}

Future playFromUri(Uri uri, [Map<String, dynamic>? extras]) async {
  var client = SoundsApi();
  var quality = (await SharedPreferences.getInstance())
      .getInt(OPTION_STREAM_QUALITY)!;

  Uri playbackUri;

  switch (uri.scheme) {
    case 'programme':
      playbackUri = await client.getEpisodePlaybackUri(uri.host, quality);
      break;
    case 'station':
      playbackUri = Uri.parse('http://as-hls-uk-live.akamaized.net/pool_904/live/uk/${uri.host}/${uri.host}.isml/${uri.host}-audio%3d${quality}.m3u8');
      break;
    default:
      log('The playback URI $uri is not supported');
      return;
  }

  bool seekBack = false;

  var currentlyPlayingItem = getAudioPlayer().sequenceState?.currentSource?.tag as MediaItem?;

  var position = getAudioPlayer().position;
  if (position != null) {
    // If we're already playing the same programme or station, continue from the same position (e.g. the quality was changed)
    if (currentlyPlayingItem?.id == uri.toString()) {
      seekBack = true;
    }
  }

  if (seekBack == false) {
    // If we've played this programme before, continue from the stored position
    var database = await DB.readOnly();

    var storedPosition = sqflite.Sqflite.firstIntValue(await database.rawQuery('SELECT position FROM $TABLE_POSITION WHERE episode_id = ?', [uri.host]));
    if (storedPosition != null) {
      position = Duration(seconds: storedPosition);
      seekBack = true;
    }
  }

  log('Playing $playbackUri');

  var metadata = extras!['metadata'] as ProgrammeMetadata;

  var mediaItem = MediaItem(
      id: uri.toString(),
      title: metadata.title,
      artist: metadata.stationName,
      album: metadata.stationName,
      duration: metadata.duration,
      artUri: Uri.parse(metadata.imageUri.replaceAll('{recipe}', '320x320')),
      extras: {
        'metadata': metadata.toMap()
      }
  );

  var audioSource = AudioSource.uri(playbackUri, tag: mediaItem);

  await getAudioPlayer().setAudioSource(audioSource);

  // If we're already playing the same programme or station, continue from the same position
  if (seekBack) {
    log('Seeking back to $position');

    await getAudioPlayer().seek(position);
  }

  await getAudioPlayer().play();
}


class _HomeLiveScreenState extends State<HomeLiveScreen> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();

    this._future = SoundsApi().listStations();
  }

  Future onTapStation(ProgrammeMetadata metadata) async {
    var uri = Uri(scheme: 'station', host: metadata.stationId);

    await playFromUri(uri, {
      'metadata': metadata
    });

    Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _future,
      builder: (context, snapshot) {
        var error = snapshot.error;
        if (error != null) {
          log('Oops', error: error, stackTrace: snapshot.stackTrace);

          return Center(child: Text('Something went wrong searching. The error was $error'));
        }

        var data = snapshot.data;
        if (data == null) {
          return Center(child: CircularProgressIndicator());
        }

        // TODO: Check what happens when no internet... display snackbar?
        // TODO: Maybe refresh every minute? If a programme ends, the previous one is still displayed

        final stations = List.from(data['data'])
          .map((station) => ProgrammeMetadata(
            date: station['titles']['secondary'],
            description: station['synopses']?['short'] ?? '',
            duration: Duration(seconds: station['duration']['value']),
            endsAt: DateTime.now().add(Duration(seconds: station['duration']['value'] - station['progress']['value'])),
            id: station['id'],
            imageUri: station['image_url'],
            isLive: true,
            startsAt: DateTime.now().subtract(Duration(seconds: station['progress']['value'])),
            stationId: station['network']['id'],
            stationLogo: station['network']['logo_url'],
            stationName: station['network']['short_title'],
            title: station['titles']['primary'],
          ))
          .toList(growable: false);
        
        return OrientationLayoutBuilder(
          portrait: (context) => HomeLiveScreenPortrait(programmes: stations, onTap: this.onTapStation),
          landscape: (context) => HomeLiveScreenLandscape(programmes: stations, onTap: this.onTapStation),
        );
      },
    );
  }
}

class HomeLiveScreenLandscape extends StatelessWidget {
  final List<ProgrammeMetadata> programmes;
  final Future Function(ProgrammeMetadata metadata) onTap;

  const HomeLiveScreenLandscape({Key? key, required this.programmes, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 160,
          childAspectRatio: 100 / 80
        ),
        itemCount: programmes.length,
        itemBuilder: (context, index) {
          var metadata = programmes[index];

          return RawMaterialButton(
            onPressed: () => onTap(metadata),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CachedImage(
                    uri: metadata.stationLogo.replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                    height: 48,
                    width: 48
                ),
                Container(
                  margin: EdgeInsets.only(top: 16),
                  child: Text(metadata.stationName,
                      textAlign: TextAlign.center
                  ),
                )
              ],
            ),
          );
        },
    );
  }
}


class HomeLiveScreenPortrait extends StatelessWidget {
  final List<ProgrammeMetadata> programmes;
  final Future Function(ProgrammeMetadata metadata) onTap;
  
  const HomeLiveScreenPortrait({Key? key, required this.programmes, required this.onTap}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      key: UniqueKey(),
      child: ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: programmes.length,
          itemBuilder: (BuildContext context, int index) {
            var metadata = programmes[index];

            return AnimationConfiguration.staggeredList(
              position: index,
              duration: const Duration(milliseconds: 250),
              child: SlideAnimation(
                horizontalOffset: 50,
                child: FadeInAnimation(
                  child: ListTile(
                    onTap: () => onTap(metadata),
                    title: Text(metadata.stationName),
                    subtitle: Text(metadata.title),
                    trailing: TimeAgo(date: metadata.endsAt),
                    leading: CachedImage(
                        uri: metadata.stationLogo.replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                        height: 48,
                        width: 48
                    ),
                  ),
                ),
              ),
            );
          }
      ),
    );
  }
}
