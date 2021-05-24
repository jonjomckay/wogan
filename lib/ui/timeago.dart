import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

class TimeAgo extends StatefulWidget {
  final DateTime date;

  const TimeAgo({Key? key, required this.date}) : super(key: key);

  @override
  _TimeAgoState createState() => _TimeAgoState();
}

class _TimeAgoState extends State<TimeAgo> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _timer?.cancel();
    _timer = Timer.periodic(Duration(seconds: 20), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var value = timeago.format(widget.date, allowFromNow: true);

    return Text('$value left');
  }
}
