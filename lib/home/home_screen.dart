import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:wogan/constants.dart';
import 'package:wogan/home/_live.dart';
import 'package:wogan/home/_music.dart';
import 'package:wogan/home/_speech.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/player_screen.dart';
import 'package:wogan/search/search_delegate.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  List<Widget> _children = [
    HomeLiveScreen(),
    HomeMusicScreen(),
    HomeSpeechScreen()
  ];


  @override
  void initState() {
    super.initState();

    PrefService.of(context, listen: false)
        .addKeyListener(OPTION_STREAM_QUALITY, this.onChangeQuality);
  }

  void onChangeQuality() {
    getAudioHandler().customAction('changeQuality', null);
  }

  @override
  void dispose() {
    PrefService.of(context, listen: false)
        .removeKeyListener(OPTION_STREAM_QUALITY, this.onChangeQuality);

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var bottomSheetHeight = 64.0;

    return StreamBuilder<MediaItem?>(
      stream: getAudioHandler().mediaItem,
      builder: (context, snapshot) {
        Widget player = Container(height: 0);
        EdgeInsets padding = EdgeInsets.zero;

        var data = snapshot.data;
        if (data != null) {
          padding = EdgeInsets.only(bottom: bottomSheetHeight);
          player = Container(
            color: Theme.of(context).cardColor,
            height: bottomSheetHeight,
            padding: EdgeInsets.symmetric(horizontal: 16),
            width: MediaQuery.of(context).size.width,
            child: GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => PlayerScreen())),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          child: Text(data.title),
                        ),
                        Container(
                          margin: EdgeInsets.symmetric(vertical: 2),
                          child: Text(data.album, style: TextStyle(
                              color: Theme.of(context).hintColor
                          )),
                        ),
                      ],
                    ),
                  ),
                  StreamBuilder<PlaybackState>(
                    stream: getAudioHandler().playbackState,
                    builder: (context, snapshot) {
                      var state = snapshot.data;
                      if (state == null) {
                        return Container();
                      }

                      if (state.playing) {
                        return IconButton(
                          icon: Icon(Icons.pause_circle_outline, size: 44),
                          onPressed: () async => await getAudioHandler().pause(),
                        );
                      }

                      return IconButton(
                        icon: Icon(Icons.play_circle_outline, size: 44),
                        onPressed: () async => await getAudioHandler().play(),
                      );
                    },
                  )
                ],
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: Text('Wogan'),
            actions: [
              IconButton(
                icon: Icon(Icons.search),
                onPressed: () {
                  showSearch(context: context, delegate: SoundsSearchDelegate());
                },
              ),
            ],
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (value) {
              setState(() {
                _currentIndex = value;
              });
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.radio), label: 'Live'),
              BottomNavigationBarItem(icon: Icon(Icons.library_music), label: 'Music'),
              BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Speech'),
            ],
          ),
          bottomSheet: player,
          body: Container(
            padding: padding,
            child: _children[_currentIndex],
          ),
        );
      },
    );
  }
}
