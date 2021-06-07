import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:wogan/main.dart';

class PlayerControls extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    var player = getAudioHandler();

    var buttonSize = MediaQuery.of(context).size.width * 0.12;

    return StreamBuilder<PlaybackState>(
      stream: player.playbackState,
      builder: (context, snapshot) {
        var data = snapshot.data;
        if (data == null) {
          return Center(child: CircularProgressIndicator());
        }

        final processingState = data.processingState;
        final playing = data.playing;

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: MaterialButton(
                child: Icon(Icons.replay, size: buttonSize / 2, color: Colors.white),
                height: buttonSize,
                shape: CircleBorder(side: BorderSide(
                    width: 2,
                    color: Colors.white,
                    style: BorderStyle.solid
                )),
                onPressed: () {
                  // TODO: Seek to the beginning of the programme
                  Scaffold.of(context).showSnackBar(SnackBar(content: Text('Not implemented yet!')));
                },
              ),
            ),
            Expanded(
              child: MaterialButton(
                child: Icon(Icons.replay_10, size: buttonSize / 2, color: Colors.white),
                height: buttonSize,
                shape: CircleBorder(side: BorderSide(
                    width: 2,
                    color: Colors.white,
                    style: BorderStyle.solid
                )),
                onPressed: () {
                  player.seek(Duration(seconds: data.position.inSeconds - 10));
                },
              ),
            ),
            Container(
              width: buttonSize * 1.9,
              child: Builder(builder: (context) {
                var size = buttonSize * 1.4;

                if (processingState == AudioProcessingState.loading ||
                    processingState == AudioProcessingState.buffering) {
                  return Container(
                    margin: EdgeInsets.symmetric(horizontal: 12),
                    width: size,
                    height: size,
                    child: Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                } else if (playing != true) {
                  return MaterialButton(
                    child: Icon(Icons.play_arrow, size: 36, color: Colors.white),
                    height: size,
                    shape: CircleBorder(side: BorderSide(
                        width: 2,
                        color: Colors.white,
                        style: BorderStyle.solid
                    )),
                    onPressed: player.play,
                  );
                } else if (processingState != AudioProcessingState.completed) {
                  return MaterialButton(
                    child: Icon(Icons.pause, size: size / 2, color: Colors.white),
                    height: size,
                    shape: CircleBorder(side: BorderSide(
                        width: 2,
                        color: Colors.white,
                        style: BorderStyle.solid
                    )),
                    onPressed: player.pause,
                  );
                } else {
                  return MaterialButton(
                    child: Icon(Icons.replay, size: 24, color: Colors.white),
                    height: size,
                    shape: CircleBorder(side: BorderSide(
                        width: 2,
                        color: Colors.white,
                        style: BorderStyle.solid
                    )),
                    onPressed: () => player.seek(Duration.zero),
                  );
                }
              }),
            ),
            Expanded(
              child: MaterialButton(
                child: Icon(Icons.forward_10, size: buttonSize / 2, color: Colors.white),
                height: buttonSize,
                shape: CircleBorder(side: BorderSide(
                    width: 2,
                    color: Colors.white,
                    style: BorderStyle.solid
                )),
                onPressed: () {
                  player.seek(Duration(seconds: data.position.inSeconds + 10));
                },
              ),
            ),
            Expanded(
              child: StreamBuilder<MediaItem?>(
                stream: player.mediaItem,
                builder: (context, snapshot) {
                  Function() onPressed;

                  var data = snapshot.data;
                  if (data == null) {
                    onPressed = () => null;
                  } else {
                    onPressed = () {
                      player.seek(Duration(seconds: data.duration!.inSeconds - 6));
                    };
                  }

                  return MaterialButton(
                    child: Transform(
                      alignment: Alignment.center,
                      transform: Matrix4.rotationY(pi),
                      child: Icon(Icons.replay, size: buttonSize / 2, color: Colors.white),
                    ),
                    height: buttonSize,
                    shape: CircleBorder(side: BorderSide(
                        width: 2,
                        color: Colors.white,
                        style: BorderStyle.solid
                    )),
                    onPressed: onPressed,
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
