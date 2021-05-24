import 'dart:developer';
import 'dart:math' as math;

import 'package:audio_service/audio_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/main.dart';

import 'player.dart';

const QUALITY_MAP = {
  48000: 'Lowest',
  96000: 'Low',
  128000: 'Normal',
  320000: 'High'
};

class LiveScreen extends StatefulWidget {
  final dynamic station;

  const LiveScreen({Key? key, this.station}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  int _quality = 128000;
  AudioHandler? _player;

  @override
  void initState() {
    super.initState();

    _player = getAudioHandler();
    _init();
  }

  _init() async {
    try {
      await _player?.playFromUri(Uri.parse('http://as-hls-uk-live.akamaized.net/pool_904/live/uk/${widget.station['id']}/${widget.station['id']}.isml/${widget.station['id']}-audio%3d$_quality.m3u8'), {
        'title': widget.station['titles']['primary'],
        'artist': widget.station['network']['short_title'],
        'album': widget.station['network']['short_title'],
        'duration': Duration(seconds: widget.station['duration']['value']),
        'artUri': Uri.parse(widget.station['image_url'].replaceAll('{recipe}', '320x320'))
      });
      await _player?.play();
    } catch (e) {
      // TODO: Catch load errors: 404, invalid url ...
      print("An error occurred $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    var player = this._player;
    if (player == null) {
      return Center(child: CircularProgressIndicator());
    }

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
                  imageUrl: widget.station['network']['logo_url'].replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                  placeholder: (context, url) => CircularProgressIndicator(),
                  errorWidget: (context, url, error) => Icon(Icons.error),
                  filterQuality: FilterQuality.high,
                  height: 64,
                  width: 64
              ),
            ),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: FutureBuilder<dynamic>(
                future: SoundsApi().getStationLatestBroadcast(widget.station['id']),
                builder: (context, snapshot) {
                  var dateFormat = DateFormat.Hm();

                  var programmeImage = widget.station['image_url'];
                  var programmeDate = widget.station['titles']['secondary'];
                  var programmeTitle = widget.station['titles']['primary'];
                  var programmeSubtitle = '';
                  var programmeDuration = 0;
                  DateTime? start;
                  DateTime? ends;

                  if (snapshot.hasData) {
                    var broadcast = snapshot.data['data'][0];

                    start = DateTime.parse(broadcast['start']);
                    ends = DateTime.parse(broadcast['end']);
                    programmeImage = broadcast['programme']['images'][0]['url'];
                    programmeDate = '${dateFormat.format(start)} - ${dateFormat.format(ends)}';
                    programmeTitle = broadcast['programme']['titles']['primary'];
                    programmeSubtitle = broadcast['programme']['titles']['secondary'];
                    programmeDuration = broadcast['duration'];
                  }

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: programmeImage.replaceAll('{recipe}', '624x624'),
                        filterQuality: FilterQuality.high,
                        width: MediaQuery.of(context).size.width * 0.9,
                        height: MediaQuery.of(context).size.width * 0.9,
                        placeholder: (context, url) => Container(
                          margin: EdgeInsets.all(32),
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.width * 0.9,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        imageBuilder: (context, imageProvider) => Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                                image: imageProvider,
                                fit: BoxFit.contain
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        margin: EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Text(programmeDate,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.bold
                            )),
                      ),
                      Container(
                        margin: EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Text(programmeTitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'serif',
                                fontSize: 26,
                                fontWeight: FontWeight.bold
                            )),
                      ),
                      Container(
                        margin: EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Text(programmeSubtitle,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w300
                            )
                        ),
                      ),
                      StreamBuilder<MediaItem?>(
                        stream: player.mediaItem,
                        builder: (context, snapshot) {
                          var data = snapshot.data;
                          if (data == null) {
                            return Container();
                          }

                          var playerDuration = data.duration ?? Duration.zero;

                          return StreamBuilder<PlaybackState>(
                            stream: player.playbackState,
                            builder: (context, snapshot) {
                              var data = snapshot.data;
                              if (data == null || start == null || ends == null) {
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
                              var startOfProgramme = start.toLocal();
                              var currentPosition = startOfStream.add(playerPosition);
                              var endOfStream = now.subtract(Duration(seconds: 30)).toLocal();
                              var endOfProgramme = ends.toLocal();


                              // log('ss: $startOfStream');
                              // log('sp: $startOfProgramme');
                              // log('cp: $currentPosition');
                              // log('es: $endOfStream');
                              // log('ep: $endOfProgramme');

                              // log('');
                              // log('$playerDuration');
                              // log('$playerPosition');

                              // Determine the "live" position in the current broadcast programme
                              var livePosition = ((DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch) / 1000).round();

                              // Get the duration of the current broadcast, not the stream
                              var duration = Duration(seconds: programmeDuration);

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

                                  await player.seek(newPosition);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ],
                  );
                },
              ),
            )
          ]),
          Column(children: [
            Container(
              margin: EdgeInsets.all(12),
              alignment: Alignment.center,
              child: ControlButtons(player),
            ),
            Container(
              margin: EdgeInsets.all(12),
              alignment: Alignment.center,
              child: OutlinedButton(
                child: Text("${QUALITY_MAP[_quality]}", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () {
                  _showQualityDialog(
                    context: context,
                    title: 'Select quality',
                    value: _quality,
                    onChanged: (value) => setState(() {
                      _quality = value;

                      _init();
                    }),
                  );
                },
              ),
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

_showQualityDialog({
  required BuildContext context,
  required String title,
  required int value,
  required ValueChanged<int> onChanged,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: Column(
                children: [
                  ...QUALITY_MAP.entries.map((e) => ListTile(
                    title: Text(e.value),
                    subtitle: Text('${(e.key / 1000).round()} kbit/s'),
                    leading: Radio(
                        value: e.key,
                        groupValue: value,
                        onChanged: (value) {
                          onChanged(e.key);

                          Navigator.pop(context);
                        },
                    ),
                  ))
                ]
            ),
          )
        ],
      ),
    ),
  );
}

