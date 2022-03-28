import 'dart:developer';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:responsive_builder/responsive_builder.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/home/_live.dart';
import 'package:wogan/home/_subscriptions.dart';
import 'package:wogan/main.dart';
import 'package:wogan/models/subscription.dart';
import 'package:wogan/models/subscription_model.dart';
import 'package:wogan/player/_metadata.dart';
import 'package:wogan/player/player_screen.dart';
import 'package:wogan/search/search_delegate.dart';
import 'package:wogan/ui/image.dart';

class _ShowDetails extends StatelessWidget {
  final dynamic show;

  const _ShowDetails({Key? key, required this.show}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => SubscriptionModel(),
      builder: (context, child) {
        return StationAwareWidget(builder: (context, stations) {
          return SubscriptionAwareWidget(builder: (context, subscriptions) {
            var subscription = subscriptions.firstWhere((e) => e.urn == show['urn'], orElse: () => Subscription(
                id: show['id'],
                urn: show['urn'],
                description: show['synopses']['short'],
                imageUrl: show['image_url'],
                network: stations.firstWhere((element) => element.id == show['network']['id']),
                title: show['titles']['primary'],
                subscribedAt: null
            ));

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: EdgeInsets.only(top: 8),
                  child: CachedImage(
                    uri: show['image_url'].replaceAll('{recipe}', '640x360'),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: EdgeInsets.only(top: 16),
                      child: Text(show['titles']['primary'],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              fontFamily: 'serif',
                              fontSize: 22,
                              fontWeight: FontWeight.bold
                          )
                      ),
                    ),
                    Container(
                      margin: EdgeInsets.only(top: 8, bottom: 8),
                      child: Text(show['synopses']['short'],
                          textAlign: TextAlign.left,
                          style: TextStyle(
                              color: Theme.of(context).hintColor,
                              fontWeight: FontWeight.w300
                          )
                      ),
                    ),
                    Container(
                      child: SubscribeButton(
                        subscription: subscription,
                      ),
                    )
                  ],
                ),
              ],
            );
          });
        });
      },
    );
  }
}

class _ShowEpisodes extends StatefulWidget {
  final ScrollController controller;
  final String id;

  const _ShowEpisodes({Key? key, required this.controller, required this.id}) : super(key: key);

  @override
  __ShowEpisodesState createState() => __ShowEpisodesState();
}

class __ShowEpisodesState extends State<_ShowEpisodes> {
  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();

    _future = SoundsApi().getProgrammeEpisodes(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<dynamic>(
      future: _future,
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
              controller: widget.controller,
              shrinkWrap: true,
              itemCount: results.length,
              itemBuilder: (context, index) {
                var episode = results[index];

                return InkWell(
                  child: Container(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          margin: EdgeInsets.only(right: 12),
                          child: CachedImage(uri: episode['image_url'].replaceAll('{recipe}', '192x192'), width: 96, height: 96),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${episode['titles']['secondary']}', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600
                              )),
                              Container(
                                  margin: EdgeInsets.only(top: 4),
                                  child: Text('${episode['synopses']['short']}', maxLines: 2, overflow: TextOverflow.ellipsis, style: TextStyle(
                                    height: 1.5
                                  ))
                              ),
                              Container(
                                margin: EdgeInsets.only(top: 8),
                                child: Text('${episode['release']['label']} • ${episode['duration']['label']}', style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  fontSize: 12
                                )),
                              ),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                  onTap: () async {
                    var metadata = ProgrammeMetadata(
                        imageUri: episode['image_url'],
                        date: episode['release']['label'],
                        description: episode['titles']['secondary'],
                        duration: Duration(seconds: episode['duration']['value']),
                        endsAt: DateTime.now(), // TODO
                        id: episode['id'],
                        isLive: false,
                        startsAt: DateTime.now(), // TODO
                        stationId: episode['network']['id'],
                        stationLogo: episode['network']['logo_url'],
                        stationName: episode['network']['short_title'],
                        title: episode['titles']['primary']
                    );

                    var uri = Uri(scheme: 'programme', host: episode['id']);

                    await playFromUri(uri, {
                      'metadata': metadata
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

  late Future<dynamic> _future;

  @override
  void initState() {
    super.initState();

    _future = SoundsApi().getProgramme(widget.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: FutureBuilder<dynamic>(
          future: _future,
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
                  margin: EdgeInsets.symmetric(horizontal: 16),
                  child: OrientationLayoutBuilder(
                    portrait: (context) => _ShowScreenPortrait(show: data, id: widget.id, scrollController: _scrollController),
                    landscape: (context) => _ShowScreenLandscape(show: data, id: widget.id, scrollController: _scrollController),
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

class _ShowScreenPortrait extends StatelessWidget {
  final dynamic show;
  final String id;
  final ScrollController scrollController;

  const _ShowScreenPortrait({Key? key, required this.show, required this.id, required this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _ShowDetails(show: show),
        _ShowEpisodes(id: id, controller: scrollController)
      ],
    );
  }
}

class _ShowScreenLandscape extends StatelessWidget {
  final dynamic show;
  final String id;
  final ScrollController scrollController;

  const _ShowScreenLandscape({Key? key, required this.show, required this.id, required this.scrollController}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Flexible(
          flex: 1,
          child: _ShowDetails(show: show),
        ),
        Flexible(
          flex: 2,
          child: Container(
            margin: EdgeInsets.only(left: 16),
            child: _ShowEpisodes(id: id, controller: scrollController)
          ),
        )
      ],
    );
  }
}
