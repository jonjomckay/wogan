import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:wogan/live_screen.dart';
import 'package:wogan/ui/timeago.dart';

import 'api/client.dart';

class HomeLiveScreen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _HomeLiveScreenState();
}

class _HomeLiveScreenState extends State<HomeLiveScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: SoundsApi().listStations(),
      builder: (context, snapshot) {
        var data = snapshot.data;
        if (data == null) {
          return Center(child: CircularProgressIndicator());
        }

        // TODO: Check what happens when no internet... display snackbar?

        var _stations = data['data'];

        return AnimationLimiter(
          key: UniqueKey(),
          child: ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: _stations.length,
              itemBuilder: (BuildContext context, int index) {
                var station = _stations[index];

                // TODO: Maybe replace this with a refresh every minute? If a programme ends, it's still displayed
                var timeLeft = station['duration']['value'] - station['progress']['value'];
                var endsAt = DateTime.now().add(Duration(seconds: timeLeft));

                return AnimationConfiguration.staggeredList(
                  position: index,
                  duration: const Duration(milliseconds: 250),
                  child: SlideAnimation(
                    horizontalOffset: 50,
                    child: FadeInAnimation(
                      child: ListTile(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => LiveScreen(station: station))),
                        title: Text(station['network']['short_title']),
                        subtitle: Text(station['titles']['primary']),
                        trailing: TimeAgo(date: endsAt),
                        leading: CachedNetworkImage(
                            imageUrl: station['network']['logo_url'].replaceAll('{type}', 'colour').replaceAll('{size}', '450').replaceAll('{format}', 'png'),
                            placeholder: (context, url) => Container(),
                            errorWidget: (context, url, error) => Icon(Icons.error),
                            filterQuality: FilterQuality.high,
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
      },
    );
  }
}