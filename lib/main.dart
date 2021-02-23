import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'home_live_screen.dart';

void main() {
  timeago.setLocaleMessages('en', BbcSoundsMessages());

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.deepOrange,
        // This makes the visual density adapt to the platform that you run
        // the app on. For desktop platforms, the controls will be smaller and
        // closer together (more dense) than on mobile platforms.
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.deepOrange,

        // TODO: These are only required due to https://github.com/flutter/flutter/issues/19089
        accentColor: Colors.deepOrange[500],
        toggleableActiveColor: Colors.deepOrange[500],
        textSelectionColor: Colors.deepOrange[200],
      ),
      themeMode: ThemeMode.system,
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentIndex = 0;
  List<Widget> _children = [
    HomeLiveScreen(),
    Text('not yet'),
    Text('not yet'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Wogan'),
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
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
        ],
      ),
      body: _children[_currentIndex],
    );
  }
}

class BbcSoundsMessages implements timeago.LookupMessages {
  @override
  String prefixAgo() => '';

  @override
  String prefixFromNow() => '';

  @override
  String suffixAgo() => '';

  @override
  String suffixFromNow() => '';

  @override
  String lessThanOneMinute(int seconds) => 'less than 1 min';

  @override
  String aboutAMinute(int minutes) => '1 min';

  @override
  String minutes(int mins) => '$mins mins';

  @override
  String aboutAnHour(int mins) => minutes(mins);

  @override
  String hours(int hours) => '$hours hours';

  @override
  String aDay(int hours) => '~1 d';

  @override
  String days(int days) => '$days d';

  @override
  String aboutAMonth(int days) => '~1 mo';

  @override
  String months(int months) => '$months mo';

  @override
  String aboutAYear(int year) => '~1 yr';

  @override
  String years(int years) => '$years yr';

  @override
  String wordSeparator() => ' ';
}
