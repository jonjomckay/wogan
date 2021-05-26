import 'package:flutter/material.dart';
import 'package:pref/pref.dart';
import 'package:wogan/constants.dart';

class PlayerQuality extends StatelessWidget {
  const PlayerQuality({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: PrefService.of(context).stream(OPTION_STREAM_QUALITY),
      builder: (context, snapshot) {
        var data = snapshot.data;
        if (data == null) {
          return Center(child: CircularProgressIndicator());
        }

        return OutlinedButton(
          style: OutlinedButton.styleFrom(
            backgroundColor: Theme.of(context).accentColor
          ),
          child: Text("${STREAM_QUALITIES[data]} Quality",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold
            )
          ),
          onPressed: () {
            _showQualityDialog(
              context: context,
              title: 'Select quality',
              value: data,
            );
          },
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
