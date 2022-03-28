import 'package:flutter/material.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/ui/image.dart';

class PlayerTrack extends StatefulWidget {
  final ProgrammeMetadata metadata;

  const PlayerTrack({Key? key, required this.metadata}) : super(key: key);

  @override
  _PlayerTrackState createState() => _PlayerTrackState();
}

class _PlayerTrackState extends State<PlayerTrack> {
  late Future<List<dynamic>> _future;

  @override
  void initState() {
    super.initState();

    fetchTracks();
  }

  Future fetchTracks() async {
    setState(() {
      _future = Future(() async {
        var response = await SoundsApi().getEpisodeTracks(widget.metadata.id);
        if (response == null || response['data'].length == 0) {
          return [];
        }

        return List.from(response['data']);
      });
    });
  }

  @override
  void didUpdateWidget(PlayerTrack oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.metadata.id != widget.metadata.id) {
      fetchTracks();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: _future,
      builder: (context, snapshot) {
        var tracks = snapshot.data;
        if (tracks == null || tracks.isEmpty) {
          return Container();
        }

        return StreamBuilder<Duration?>(
          stream: getAudioPlayer().positionStream,
          builder: (context, snapshot) {
            var currentPosition = (snapshot.data ?? Duration.zero).inSeconds;

            var track = tracks.firstWhere((element) => currentPosition >= element['offset']['start'] && currentPosition <= element['offset']['end'], orElse: () => null);
            if (track == null) {
              return Text('');
            }

            var imageUri = track['image_url'];

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: EdgeInsets.only(bottom: 16),
                  child: Text('Now Playing', style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 18,
                    fontWeight: FontWeight.bold
                  ))
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: 12),
                      child: imageUri == null
                        ? Container(height: 48, width: 48, color: Colors.grey, child: Icon(Icons.headphones))
                        : CachedImage(uri: track['image_url']),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                            margin: EdgeInsets.only(bottom: 8),
                            child: Text(track['titles']['secondary'], style: TextStyle(
                              fontWeight: FontWeight.bold
                            ))
                        ),
                        Text(track['titles']['primary']),
                      ],
                    )
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }
}
