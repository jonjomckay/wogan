import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/_seekbar.dart';

class PlayerPlayer extends StatefulWidget {
  final ProgrammeMetadata metadata;
  final int quality;

  const PlayerPlayer({Key? key, required this.metadata, required this.quality}) : super(key: key);

  @override
  _PlayerPlayerState createState() => _PlayerPlayerState();
}

class _PlayerPlayerState extends State<PlayerPlayer> {
  @override
  void initState() {
    super.initState();

    _init(true);
  }

  _init(bool startFromBeginning) async {
    try {
      var position = getAudioHandler().playbackState.value?.position;

      await getAudioHandler().playFromUri(widget.metadata.playbackUri, {
        'title': widget.metadata.title,
        'artist': widget.metadata.stationName,
        'album': widget.metadata.stationName,
        'duration': widget.metadata.duration,
        'artUri': Uri.parse(widget.metadata.imageUri.replaceAll('{recipe}', '320x320'))
      });

      if (position != null && startFromBeginning == false) {
        await getAudioHandler().seek(position);
      }

      await getAudioHandler().play();
    } catch (e) {
      // TODO: Catch load errors: 404, invalid url ...
      print("An error occurred $e");
    }
  }

  @override
  void didUpdateWidget(PlayerPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.quality != widget.quality) {
      if (oldWidget.metadata.playbackUri != oldWidget.metadata.playbackUri) {
        _init(true);
      } else {
        _init(false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<MediaItem?>(
      stream: getAudioHandler().mediaItem,
      builder: (context, snapshot) {
        var data = snapshot.data;
        if (data == null) {
          return Container();
        }

        var playerDuration = data.duration ?? Duration.zero;

        return StreamBuilder<PlaybackState>(
          stream: getAudioHandler().playbackState,
          builder: (context, snapshot) {
            var data = snapshot.data;
            if (data == null || widget.metadata.startsAt == null || widget.metadata.endsAt == null) {
              return SeekBar(
                duration: Duration.zero,
                position: Duration.zero,
                bufferedPosition: Duration.zero,
              );
            }

            var playerPosition = data.position;


            var now = DateTime.now();

            // TODO: subtract 30 seconds from the end, like bbc sounds does, to solve buffer and skip to end issues
            // start of stream
            // start of programme
            // end of stream = now
            // end of programme

            var startOfStream = now.subtract(playerDuration).toLocal();
            var startOfProgramme = widget.metadata.startsAt.toLocal();
            var currentPosition = startOfStream.add(playerPosition);
            var endOfStream = now.subtract(Duration(seconds: 30)).toLocal();
            var endOfProgramme = widget.metadata.endsAt.toLocal();


            // log('ss: $startOfStream');
            // log('sp: $startOfProgramme');
            // log('cp: $currentPosition');
            // log('es: $endOfStream');
            // log('ep: $endOfProgramme');

            // log('');
            // log('$playerDuration');
            // log('$playerPosition');

            // Determine the "live" position in the current broadcast programme
            var livePosition = ((DateTime.now().millisecondsSinceEpoch - widget.metadata.endsAt.millisecondsSinceEpoch) / 1000).round();

            // Get the duration of the current broadcast, not the stream
            var duration = widget.metadata.duration;

            // Calculate the player's position relative to the current broadcast
            var position = duration - (playerDuration - Duration(seconds: livePosition - (duration.inSeconds - playerPosition.inSeconds)));

            // log('${endOfStream.difference(startOfStream)}');
            // log('${currentPosition.difference(startOfStream)}');

            return SeekBar(
              duration: endOfProgramme.difference(startOfStream),
              position: currentPosition.difference(startOfStream),
              // duration: duration,
              // position: position >= Duration.zero ? position : Duration.zero,
              bufferedPosition: endOfStream.difference(startOfStream),
              onChangeEnd: (newPosition) async {
                // var seekPosition = duration.inSeconds - livePosition + newPosition.inSeconds;
                if (startOfStream.add(newPosition).isAfter(endOfStream)) {
                  return;
                }

                await getAudioHandler().seek(newPosition);
              },
            );
          },
        );
      },
    );
  }
}
