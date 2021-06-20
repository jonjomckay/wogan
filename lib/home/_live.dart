import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/player_screen.dart';
import 'package:wogan/ui/image.dart';
import 'package:wogan/ui/timeago.dart';

class HomeLiveScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeLiveScreenState();
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

    getAudioHandler().playFromUri(uri, {
      'metadata': metadata,
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
