import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:just_audio/just_audio.dart';
import 'package:wogan/api/client.dart';

import 'player.dart';

const QUALITY_MAP = {
  48000: 'Lowest',
  96000: 'Low',
  128000: 'Normal',
  320000: 'High'
};

class LiveScreen extends StatefulWidget {
  final dynamic station;

  const LiveScreen({Key key, this.station}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _LiveScreenState();
}

class _LiveScreenState extends State<LiveScreen> {
  int _quality = 128000;
  AudioPlayer _player;
  ConcatenatingAudioSource _playlist = ConcatenatingAudioSource(children: []);

  @override
  void initState() {
    super.initState();

    _player = AudioPlayer();
    _init();
  }


  @override
  void dispose() {
    super.dispose();

    _player.dispose();
  }

  _init() async {
    // final session = await AudioSession.instance;
    // await session.configure(AudioSessionConfiguration.speech());

    await _playlist.add(HlsAudioSource(
      Uri.parse('http://as-hls-uk-live.akamaized.net/pool_904/live/uk/${widget.station['id']}/${widget.station['id']}.isml/${widget.station['id']}-audio%3d$_quality.m3u8')
    ));

    try {
      await _player.setAudioSource(_playlist);
      await _player.play();
    } catch (e) {
      // TODO: Catch load errors: 404, invalid url ...
      print("An error occurred $e");
    }
  }

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
              child: FutureBuilder(
                future: SoundsApi().getStationLatestBroadcast(widget.station['id']),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Center(child: CircularProgressIndicator());
                  }

                  // TODO: This might return nothing? Or an empty list
                  var broadcast = snapshot.data['data'][0];

                  var start = DateTime.parse(broadcast['start']);
                  var ends = DateTime.parse(broadcast['end']);
                  var dateFormat = DateFormat.Hm();

                  // _player.

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CachedNetworkImage(
                        imageUrl: broadcast['programme']['images'][0]['url'].replaceAll('{recipe}', '624x624'),
                        filterQuality: FilterQuality.high,
                        placeholder: (context, url) => Container(
                          margin: EdgeInsets.all(32),
                          alignment: Alignment.center,
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.width * 0.9,
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        errorWidget: (context, url, error) => Icon(Icons.error),
                        imageBuilder: (context, imageProvider) => Container(
                          width: MediaQuery.of(context).size.width * 0.9,
                          height: MediaQuery.of(context).size.width * 0.9,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            image: DecorationImage(
                                image: imageProvider, fit: BoxFit.contain),
                          ),
                        ),
                      ),
                      SizedBox(height: 15),
                      Container(
                        margin: EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Text('${dateFormat.format(start)} - ${dateFormat.format(ends)}',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.bold
                            )),
                      ),
                      Container(
                        margin: EdgeInsets.all(4),
                        alignment: Alignment.center,
                        child: Text(broadcast['programme']['titles']['primary'],
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
                        child: Text(broadcast['programme']['titles']['secondary'] ?? '',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                color: Theme.of(context).hintColor,
                                fontWeight: FontWeight.w300
                            )
                        ),
                      ),
                      StreamBuilder<Duration>(
                        stream: _player.durationStream,
                        builder: (context, snapshot) {
                          var playerDuration = snapshot.data ?? Duration.zero;

                          return StreamBuilder<Duration>(
                            stream: _player.positionStream,
                            builder: (context, snapshot) {
                              var playerPosition = snapshot.data ?? Duration.zero;

                              // Determine the "live" position in the current broadcast programme
                              var livePosition = ((DateTime.now().millisecondsSinceEpoch - start.millisecondsSinceEpoch) / 1000).round();

                              // Get the duration of the current broadcast, not the stream
                              var duration = Duration(seconds: broadcast['duration']);

                              // Calculate the player's position relative to the current broadcast
                              var position = duration - (playerDuration - Duration(seconds: livePosition - (duration.inSeconds - playerPosition.inSeconds)));

                              return SeekBar(
                                duration: duration,
                                position: position >= Duration.zero ? position : Duration.zero,
                                bufferedPosition: Duration(seconds: livePosition),
                                onChangeEnd: (newPosition) {
                                  var seekPosition = duration.inSeconds - livePosition + newPosition.inSeconds;

                                  _player.seek(Duration(seconds: seekPosition));
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
              child: ControlButtons(_player),
            ),
            Container(
              margin: EdgeInsets.all(12),
              alignment: Alignment.center,
              child: StreamBuilder<double>(
                stream: _player.speedStream,
                builder: (context, snapshot) => OutlineButton(
                  child: Text("${QUALITY_MAP[_quality]}",
                      style: TextStyle(fontWeight: FontWeight.bold)),
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
              ),
            )
          ])
        ],
      ),
    );
  }
}

class ControlButtons extends StatelessWidget {
  final AudioPlayer player;

  ControlButtons(this.player);

  @override
  Widget build(BuildContext context) {
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
            player.seek(Duration(seconds: player.position.inSeconds - 10));
          },
        ),
        StreamBuilder<PlayerState>(
          stream: player.playerStateStream,
          builder: (context, snapshot) {
            final playerState = snapshot.data;
            final processingState = playerState?.processingState;
            final playing = playerState?.playing;
            if (processingState == ProcessingState.loading ||
                processingState == ProcessingState.buffering) {
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
            } else if (processingState != ProcessingState.completed) {
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
                onPressed: () => player.seek(Duration.zero,
                    index: player.effectiveIndices.first),
              );
            }
          },
        ),
        MaterialButton(
          child: Icon(Icons.forward_10, size: 24, color: Colors.white),
          height: 48,
          shape: CircleBorder(side: BorderSide(
              width: 2,
              color: Colors.white,
              style: BorderStyle.solid
          )),
          onPressed: () {
            player.seek(Duration(seconds: player.position.inSeconds + 10));
          },
        ),
        MaterialButton(
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.rotationY(pi),
            child: Icon(Icons.replay, size: 24, color: Colors.white),
          ),
          height: 48,
          shape: CircleBorder(side: BorderSide(
              width: 2,
              color: Colors.white,
              style: BorderStyle.solid
          )),
          onPressed: () {
            player.seek(Duration(seconds: player.duration.inSeconds - 6));
          },
        )
      ],
    );
  }
}

_showQualityDialog({
  BuildContext context,
  String title,
  int value,
  ValueChanged<int> onChanged,
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

