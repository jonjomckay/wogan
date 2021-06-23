import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_controls.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/_player.dart';
import 'package:wogan/player/_quality.dart';
import 'package:wogan/player/_titles.dart';
import 'package:wogan/player/_track.dart';
import 'package:wogan/ui/image.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<MediaItem?>(
        stream: getAudioHandler().mediaItem,
        builder: (context, snapshot) {
          var mediaItem = snapshot.data;
          if (mediaItem == null) {
            return Center(child: CircularProgressIndicator());
          }

          var metadata = ProgrammeMetadata.fromMap(mediaItem.extras!['metadata'] as Map<String, Object>);

          return OrientationLayoutBuilder(
            portrait: (context) => PlayerScreenPortrait(metadata: metadata),
            landscape: (context) => PlayerScreenLandscape(metadata: metadata),
          );
        },
      ),
    );
  }
}

class PlayerScreenLandscape extends StatelessWidget {
  final ProgrammeMetadata metadata;

  const PlayerScreenLandscape({Key? key, required this.metadata}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Row(
            children: [
              Container(
                margin: EdgeInsets.only(right: 16),
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedImage(
                        uri: metadata.imageUri.replaceAll('{recipe}', '624x624'),
                        width: MediaQuery.of(context).size.width * 0.2,
                        height: MediaQuery.of(context).size.width * 0.2,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.all(4),
                      child: CachedImage(
                          uri: metadata.stationLogo.replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                          height: 32,
                          width: 32
                      ),
                    )
                  ],
                ),
              ),
              Expanded(child: PlayerMetadataTitles(
                metadata: metadata,
                alignment: Alignment.centerLeft,
                textAlign: TextAlign.left,
              )),
            ],
          ),
          PlayerPlayer(metadata: metadata),
          Container(
            margin: EdgeInsets.all(12),
            alignment: Alignment.center,
            child: PlayerControls(),
          )
        ],
      ),
    );
  }
}


class PlayerScreenPortrait extends StatelessWidget {
  final ProgrammeMetadata metadata;

  const PlayerScreenPortrait({Key? key, required this.metadata}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: PlayerMetadata(programme: metadata),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 8),
            child: PlayerPlayer(metadata: metadata),
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: 16),
            child: PlayerControls(),
          ),
          Expanded(
            child: Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: PlayerTrack(metadata: metadata),
            ),
          ),
        ],
      ),
    );
  }
}
