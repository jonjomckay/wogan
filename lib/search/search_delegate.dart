import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/home/_subscriptions.dart';
import 'package:wogan/models/station.dart';
import 'package:wogan/models/station_model.dart';
import 'package:wogan/models/subscription.dart';
import 'package:wogan/models/subscription_model.dart';

class SoundsSearchDelegate extends SearchDelegate {
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(icon: Icon(Icons.clear), onPressed: () {
        query = '';
      })
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
        icon: AnimatedIcon(icon: AnimatedIcons.menu_arrow, progress: transitionAnimation),
        onPressed: () {
          close(context, null);
        }
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isEmpty) {
      return Container();
    }

    return ChangeNotifierProvider(
      create: (context) => SubscriptionModel(),
      child: FutureBuilder<dynamic>(
        future: SoundsApi().searchProgrammes(query),
        builder: (context, snapshot) {
          switch (snapshot.connectionState) {
            case ConnectionState.waiting:
              return Center(child: CircularProgressIndicator());
            case ConnectionState.done:
              var error = snapshot.error;
              if (error != null) {
                return Center(child: Text('Something went wrong searching. The error was $error'));
              }

              var data = snapshot.data;
              if (data == null) {
                return Center(child: Text('No results were found!'));
              }

              var results = List.from(data['data']);

              return Consumer<SubscriptionModel>(
                builder: (context, model, child) {
                  return FutureBuilder<List<Station>>(
                    future: StationModel().listStations(),
                    builder: (context, snapshot) {
                      var error = snapshot.error;
                      if (error != null) {
                        log('Oops', error: error, stackTrace: snapshot.stackTrace);
                      }

                      var stations = snapshot.data;
                      if (stations == null) {
                        return Center(child: CircularProgressIndicator());
                      }

                      return FutureBuilder<List<Subscription>>(
                        future: model.listSubscriptions(),
                        builder: (context, snapshot) {
                          var error = snapshot.error;
                          if (error != null) {
                            log('Oops', error: error, stackTrace: snapshot.stackTrace);
                          }

                          var subscriptions = snapshot.data;
                          if (subscriptions == null) {
                            return Center(child: CircularProgressIndicator());
                          }

                          return Container(
                            margin: EdgeInsets.symmetric(vertical: 8),
                            child: ListView.builder(
                              shrinkWrap: true,
                              itemCount: results.length,
                              itemBuilder: (context, index) {
                                var result = results[index];

                                var subscription = subscriptions.firstWhere((e) => e.urn == result['urn'], orElse: () => Subscription(
                                    id: result['id'],
                                    urn: result['urn'],
                                    description: result['synopses']['short'],
                                    imageUrl: result['image_url'],
                                    network: stations.firstWhere((element) => element.id == result['network']['id']),
                                    title: result['titles']['primary'],
                                    subscribedAt: null
                                ));

                                return SubscriptionListTile(subscription: subscription);
                              },
                            ),
                          );
                        },
                      );
                    },
                  );
                },
              );
            default:
              // TODO
              return Container();
          }
        },
      ),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }
}