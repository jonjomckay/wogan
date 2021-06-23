import 'dart:math';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:wogan/api/client.dart';
import 'package:wogan/main.dart';
import 'package:wogan/player/_metadata.dart';

class PlayerMetadataTitles extends StatefulWidget {
  final ProgrammeMetadata metadata;
  final Alignment alignment;
  final TextAlign textAlign;

  const PlayerMetadataTitles({Key? key, required this.metadata, required this.alignment, required this.textAlign}) : super(key: key);

  @override
  _PlayerMetadataTitlesState createState() => _PlayerMetadataTitlesState();
}

class _PlayerMetadataTitlesState extends State<PlayerMetadataTitles> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(4),
          alignment: widget.alignment,
          child: Text(widget.metadata.date,
              textAlign: widget.textAlign,
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold
              )),
        ),
        Container(
          margin: EdgeInsets.all(4),
          alignment: widget.alignment,
          child: Text(widget.metadata.title,
              textAlign: widget.textAlign,
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 26,
                  fontWeight: FontWeight.bold
              )),
        ),
        Container(
          margin: EdgeInsets.all(4),
          alignment: widget.alignment,
          child: Text(widget.metadata.description,
              textAlign: widget.textAlign,
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
