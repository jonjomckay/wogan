import 'dart:async';
import 'dart:developer';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart' as sqflite;
import 'package:wogan/api/client.dart';
import 'package:wogan/constants.dart';
import 'package:wogan/database.dart';
import 'package:wogan/player/_metadata.dart';

class WoganAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final _player = AudioPlayer();

  late Timer _positionTimer;

  WoganAudioHandler() {
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

    // Every few seconds, store the current position of the playing episode
    _positionTimer = Timer.periodic(Duration(seconds: 5), (timer) async {
      var item = mediaItem.value;
      if (item == null) {
        return;
      }

      var state = playbackState.value;
      if (state == null) {
        return;
      }

      var database = await Database.writable();

      await database.insert(TABLE_POSITION, {
        'episode_id': Uri.parse(item.id).host,
        'position': state.position.inSeconds,
        'updated_at': DateTime.now().millisecondsSinceEpoch
      }, conflictAlgorithm: sqflite.ConflictAlgorithm.replace);
    });

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
    _positionTimer.cancel();
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

    var position = playbackState.value?.position;
    if (position != null) {
      // If we're already playing the same programme or station, continue from the same position (e.g. the quality was changed)
      if (this.mediaItem.value?.id == uri.toString()) {
        seekBack = true;
      }
    }

    if (seekBack == false) {
      // If we've played this programme before, continue from the stored position
      var database = await Database.readOnly();

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
            'artUri': item.artUri,
            'metadata': ProgrammeMetadata.fromMap(item.extras!['metadata'])
          });
        }

        break;
      case 'setVolume':
        _player.setVolume(arguments!['volume']);
        break;
    }
  }
}
