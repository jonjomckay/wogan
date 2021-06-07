import 'package:flutter/material.dart';
import 'package:wogan/player/_metadata.dart';

class PlayerMetadataTitles extends StatelessWidget {
  final ProgrammeMetadata metadata;
  final Alignment alignment;
  final TextAlign textAlign;

  const PlayerMetadataTitles({Key? key, required this.metadata, required this.alignment, required this.textAlign}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(4),
          alignment: alignment,
          child: Text(metadata.date,
              textAlign: textAlign,
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold
              )),
        ),
        Container(
          margin: EdgeInsets.all(4),
          alignment: alignment,
          child: Text(metadata.title,
              textAlign: textAlign,
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 26,
                  fontWeight: FontWeight.bold
              )),
        ),
        Container(
          margin: EdgeInsets.all(4),
          alignment: alignment,
          child: Text(metadata.description,
              textAlign: textAlign,
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.w300
              )
          ),
        ),
      ],
    );
  }
}
