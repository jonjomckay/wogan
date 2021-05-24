import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/show/show_screen.dart';

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

    return FutureBuilder<dynamic>(
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

            return Container(
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: results.length,
                itemBuilder: (context, index) {
                  var result = results[index];

                  return GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ShowScreen(id: result['id']))),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 16, left: 8, right: 8),
                      child: Row(
                        children: [
                          Container(
                            margin: EdgeInsets.only(right: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: CachedNetworkImage(
                                  imageUrl: result['image_url'].replaceAll('{recipe}', '400x400'),
                                  placeholder: (context, url) => Container(),
                                  errorWidget: (context, url, error) => Icon(Icons.error),
                                  filterQuality: FilterQuality.high,
                                  width: 128
                              ),
                            ),
                          ),
                          Expanded(child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                margin: EdgeInsets.only(bottom: 4),
                                child: Text(result['titles']['primary'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600
                                  ),
                                ),
                              ),
                              Container(
                                margin: EdgeInsets.only(bottom: 4),
                                child: Text(result['synopses']['short'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Container(
                                child: Text(result['network']['short_title'],
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context).hintColor,
                                  ),
                                ),
                              )
                            ],
                          )),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          default:
            // TODO
            return Container();
        }
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return Container();
  }

}