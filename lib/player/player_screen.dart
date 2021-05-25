import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/_player.dart';
import 'package:wogan/player/_quality.dart';

class PlayerScreen extends StatefulWidget {
  final ProgrammeMetadata metadata;

  const PlayerScreen({Key? key, required this.metadata}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(children: [
            Container(
              margin: EdgeInsets.all(16),
              alignment: Alignment.center,
              child: CachedNetworkImage(
                  imageUrl: widget.metadata.stationLogo.replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  filterQuality: FilterQuality.high,
                  height: 64,
                  width: 64
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: Column(
                children: [
                  PlayerMetadata(programme: widget.metadata),
                  PlayerPlayer(metadata: widget.metadata)
                ],
              ),
            )
          ]),
          Column(children: [
            Container(
              margin: EdgeInsets.all(12),
              alignment: Alignment.center,
              child: ControlButtons(getAudioHandler()),
            ),
            Container(
              margin: EdgeInsets.all(12),
              alignment: Alignment.center,
              child: PlayerQuality(),
            )
          ])
        ],
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioHandler player;

  ControlButtons(this.player);

  @override
  Widget build(BuildContext context) {
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
            MaterialButton(
              child: Icon(Icons.replay, size: 24, color: Colors.white),
              height: 48,
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
            MaterialButton(
              child: Icon(Icons.replay_10, size: 24, color: Colors.white),
              height: 48,
              shape: CircleBorder(side: BorderSide(
                  width: 2,
                  color: Colors.white,
                  style: BorderStyle.solid
              )),
              onPressed: () {
                player.seek(Duration(seconds: data.position.inSeconds - 10));
              },
            ),
            Builder(builder: (context) {
              if (processingState == AudioProcessingState.loading ||
                  processingState == AudioProcessingState.buffering) {
                return Container(
                  margin: EdgeInsets.all(8.0),
                  width: 36.0,
                  height: 36.0,
                  child: CircularProgressIndicator(),
                );
              } else if (playing != true) {
                return MaterialButton(
                  child: Icon(Icons.play_arrow, size: 36, color: Colors.white),
                  height: 64,
                  shape: CircleBorder(side: BorderSide(
                      width: 2,
                      color: Colors.white,
                      style: BorderStyle.solid
                  )),
                  onPressed: player.play,
                );
              } else if (processingState != AudioProcessingState.completed) {
                return MaterialButton(
                  child: Icon(Icons.pause, size: 36, color: Colors.white),
                  height: 64,
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
                  height: 48,
                  shape: CircleBorder(side: BorderSide(
                      width: 2,
                      color: Colors.white,
                      style: BorderStyle.solid
                  )),
                  onPressed: () => player.seek(Duration.zero),
                );
              }
            }),
            MaterialButton(
              child: Icon(Icons.forward_10, size: 24, color: Colors.white),
              height: 48,
              shape: CircleBorder(side: BorderSide(
                  width: 2,
                  color: Colors.white,
                  style: BorderStyle.solid
              )),
              onPressed: () {
                player.seek(Duration(seconds: data.position.inSeconds + 10));
              },
            ),
            StreamBuilder<MediaItem?>(
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
                    transform: Matrix4.rotationY(math.pi),
                    child: Icon(Icons.replay, size: 24, color: Colors.white),
                  ),
                  height: 48,
                  shape: CircleBorder(side: BorderSide(
                      width: 2,
                      color: Colors.white,
                      style: BorderStyle.solid
                  )),
                  onPressed: onPressed,
                );
              },
            ),

          ],
        );
      },
    );
  }
}



