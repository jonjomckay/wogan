import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:wogan/constants.dart';

class PlayerQuality extends StatelessWidget {
  const PlayerQuality({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.auto_awesome),
      onPressed: () {
        _showQualityDialog(
          context: context,
          title: 'Select quality',
        );
      },
    );
  }
}

_showQualityDialog({
  required BuildContext context,
  required String title,
}) async {
  var prefs = PrefService.of(context);

  var value = prefs.get(OPTION_STREAM_QUALITY);

  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: Text(title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              child: Column(children: [
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
              ]),
            )
          ],
        ),
      );
    },
  );
}
