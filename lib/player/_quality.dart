import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:wogan/constants.dart';

class PlayerQuality extends StatefulWidget {
  const PlayerQuality({Key? key}) : super(key: key);

  @override
  _PlayerQualityState createState() => _PlayerQualityState();
}

class _PlayerQualityState extends State<PlayerQuality> {
  @override
  void initState() {
    super.initState();

    PrefService.of(context, listen: false).addKeyListener(OPTION_STREAM_QUALITY, () {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    var _quality = PrefService.of(context).get(OPTION_STREAM_QUALITY);

    return OutlinedButton(
      child: Text("${STREAM_QUALITIES[_quality]}", style: TextStyle(fontWeight: FontWeight.bold)),
      onPressed: () {
        _showQualityDialog(
          context: context,
          title: 'Select quality',
          value: _quality,
        );
      },
    );
  }
}

_showQualityDialog({
  required BuildContext context,
  required String title,
  required int value,
}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            child: Column(
                children: [
                  ...STREAM_QUALITIES.entries.map((e) => ListTile(
                    title: Text(e.value),
                    subtitle: Text('${(e.key / 1000).round()} kbit/s'),
                    leading: Radio(
                      value: e.key,
                      groupValue: value,
                      onChanged: (value) async {
                        await PrefService.of(context)
                            .set(OPTION_STREAM_QUALITY, e.key);

                        Navigator.pop(context);
                      },
                    ),
                  ))
                ]
            ),
          )
        ],
      ),
    ),
  );
}
