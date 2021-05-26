import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/player_screen.dart';

class _ShowDetails extends StatelessWidget {
  final dynamic show;

  const _ShowDetails({Key? key, required this.show}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          CachedNetworkImage(
            imageUrl: show['image_url'].replaceAll('{recipe}', '640x360'),
            placeholder: (context, url) => Container(),
            errorWidget: (context, url, error) => Icon(Icons.error),
            filterQuality: FilterQuality.high,
            // width: 128
          ),
          Container(
            margin: EdgeInsets.only(top: 16),
            child: Text(show['titles']['primary'],
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'serif',
                    fontSize: 26,
                    fontWeight: FontWeight.bold
                )
            ),
          ),
          Container(
            margin: EdgeInsets.only(top: 16, bottom: 16),
            child: Text(show['synopses']['short'],
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Theme.of(context).hintColor,
                    fontWeight: FontWeight.w300
                )
            ),
          ),
        ],
      ),
    );
  }
}

class _ShowEpisodes extends StatelessWidget {
  final ScrollController controller;
  final String id;

  const _ShowEpisodes({Key? key, required this.controller, required this.id}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: SoundsApi().getProgrammeEpisodes(id),
      builder: (context, snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.waiting:
            return Center(child: CircularProgressIndicator());
          case ConnectionState.done:
            var error = snapshot.error;
            if (error != null) {
              return Center(child: Text('Something went wrong loading the programme. The error was $error'));
            }

            var data = snapshot.data;
            if (data == null) {
              return Center(child: Text('The programme could not be found!'));
            }

            var results = List.from(data['data']);

            return ListView.builder(
              controller: controller,
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                var episode = results[index];

                return ListTile(
                  title: Text('${episode['titles']['secondary']}'),
                  subtitle: Text('${episode['synopses']['short']}'),
                  onTap: () async {
                    var metadata = ProgrammeMetadata(
                        imageUri: episode['image_url'],
                        date: episode['release']['label'],
                        description: episode['titles']['secondary'],
                        duration: Duration(seconds: episode['duration']['value']),
                        endsAt: DateTime.now(), // TODO
                        startsAt: DateTime.now(), // TODO
                        stationId: episode['network']['id'],
                        stationLogo: episode['network']['logo_url'],
                        stationName: episode['network']['short_title'],
                        title: episode['titles']['primary']
                    );

                    var uri = Uri(scheme: 'programme', host: episode['id']);

                    getAudioHandler().playFromUri(uri, {
                      'metadata': metadata,
                    });

                    Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen()));
                  },
                );
              },
            );
          default:
          // TODO
            return Container();
        }
      },
    );
  }
}


class ShowScreen extends StatefulWidget {
  final String id;

  const ShowScreen({Key? key, required this.id}) : super(key: key);

  @override
  _ShowScreenState createState() => _ShowScreenState();
}

class _ShowScreenState extends State<ShowScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: FutureBuilder<dynamic>(
          future: SoundsApi().getProgramme(widget.id),
          builder: (context, snapshot) {
            switch (snapshot.connectionState) {
              case ConnectionState.waiting:
                return Center(child: CircularProgressIndicator());
              case ConnectionState.done:
                var error = snapshot.error;
                if (error != null) {
                  return Center(child: Text('Something went wrong loading the programme. The error was $error'));
                }

                var data = snapshot.data;
                if (data == null) {
                  return Center(child: Text('The programme could not be found!'));
                }

                return Container(
                  child: Column(
                    children: [
                      _ShowDetails(show: data),
                      _ShowEpisodes(id: widget.id, controller: _scrollController)
                    ],
                  ),
                );
              default:
              // TODO
                return Container();
            }
          },
        ),
      ),
    );
  }
}
