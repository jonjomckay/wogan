import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/_seekbar.dart';

class PlayerPlayer extends StatefulWidget {
  final ProgrammeMetadata metadata;

  const PlayerPlayer({Key? key, required this.metadata}) : super(key: key);

  @override
  _PlayerPlayerState createState() => _PlayerPlayerState();
}

class _PlayerPlayerState extends State<PlayerPlayer> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Duration?>(
      stream: getAudioPlayer().positionStream,
      builder: (context, snapshot) {
        var playerPosition = snapshot.data ?? Duration.zero;

        return StreamBuilder<PlaybackEvent>(
          stream: getAudioPlayer().playbackEventStream,
          builder: (context, snapshot) {
            var data = snapshot.data;
            if (data == null || widget.metadata.startsAt == null || widget.metadata.endsAt == null) {
              return SeekBar(
                duration: Duration.zero,
                position: Duration.zero,
                bufferedPosition: Duration.zero,
              );
            }

            var playerDuration = data.duration ?? Duration.zero;

            var now = DateTime.now();

            // Duration of programme
            var aDuration = widget.metadata.duration;

            // Available for programme
            // TODO: Make this work with other time zones
            var aAvailable = now.difference(widget.metadata.startsAt);

            // Position in programme
            var aPosition = data.updateTime.subtract(playerDuration).add(data.updatePosition);
            var aPosition2 = aPosition.difference(widget.metadata.startsAt);
            var aPosition3 = widget.metadata.startsAt.difference(aPosition);
            var aPosition4 = aPosition.difference(widget.metadata.startsAt);


            print('');
            // print(data);
            print(aPosition4);
            print(aAvailable);
            print(aDuration);



            if (widget.metadata.isLive) {
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

              // return SeekBar(
              //   duration: endOfProgramme.difference(startOfStream),
              //   position: currentPosition.difference(startOfStream),
              //   // duration: duration,
              //   // position: position >= Duration.zero ? position : Duration.zero,
              //   bufferedPosition: endOfStream.difference(startOfStream),
              //   onChangeEnd: (newPosition) async {
              //     // var seekPosition = duration.inSeconds - livePosition + newPosition.inSeconds;
              //     if (startOfStream.add(newPosition).isAfter(endOfStream)) {
              //       return;
              //     }
              //
              //     await getAudioHandler().seek(newPosition);
              //   },
              // );

              return SeekBar(
                duration: aDuration,
                position: aPosition4,
                // duration: duration,
                // position: position >= Duration.zero ? position : Duration.zero,
                bufferedPosition: aAvailable,
                onChangeEnd: (newPosition) async {
                  // var seekPosition = duration.inSeconds - livePosition + newPosition.inSeconds;

                  // var aNewPosition =

                  if (startOfStream.add(newPosition).isAfter(endOfStream)) {
                    return;
                  }

                  await getAudioPlayer().seek(newPosition);
                },
              );
            }

            return SeekBar(
              duration: widget.metadata.duration,
              position: playerPosition,
              bufferedPosition: data.bufferedPosition,
              onChangeEnd: (newPosition) async {
                await getAudioPlayer().seek(newPosition);
              },
            );
          },
        );
      },
    );
  }
}
