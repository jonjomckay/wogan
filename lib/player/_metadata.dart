import 'package:flutter/material.dart';
import 'package:wogan/player/_titles.dart';
import 'package:wogan/ui/image.dart';

class ProgrammeMetadata {
  final String imageUri;
  final String date;
  final String description;
  final Duration duration;
  final DateTime endsAt;
  final bool isLive;
  final DateTime startsAt;
  final String stationId;
  final String stationLogo;
  final String stationName;
  final String title;

  ProgrammeMetadata(
      {required this.imageUri, required this.date, required this.description, required this.duration, required this.endsAt, required this.isLive, required this.startsAt, required this.stationId, required this.stationLogo, required this.stationName, required this.title});

  factory ProgrammeMetadata.fromMap(Map<String, Object> map) {
    return ProgrammeMetadata(
        imageUri: map['imageUri'] as String,
        date: map['date'] as String,
        description: map['description'] as String,
        duration: Duration(milliseconds: map['duration'] as int),
        endsAt: DateTime.parse(map['endsAt'] as String),
        isLive: map['isLive'] as bool,
        startsAt: DateTime.parse(map['startsAt'] as String),
        stationId: map['stationId'] as String,
        stationLogo: map['stationLogo'] as String,
        stationName: map['stationName'] as String,
        title: map['title'] as String
    );
  }

  Map<String, Object> toMap() {
    return {
      'imageUri': imageUri,
      'date': date,
      'description': description,
      'duration': duration.inMilliseconds,
      'endsAt': endsAt.toIso8601String(),
      'isLive': isLive,
      'startsAt': startsAt.toIso8601String(),
      'stationId': stationId,
      'stationLogo': stationLogo,
      'stationName': stationName,
      'title': title
    };
  }
}

class PlayerMetadata extends StatefulWidget {
  final ProgrammeMetadata programme;
  
  const PlayerMetadata({Key? key, required this.programme}) : super(key: key);

  @override
  _PlayerMetadataState createState() => _PlayerMetadataState();
}

class _PlayerMetadataState extends State<PlayerMetadata> {
  @override
  Widget build(BuildContext context) {
    var programmeDate = widget.programme.date;
    var programmeImage = widget.programme.imageUri;
    var programmeSubtitle = widget.programme.description;
    var programmeTitle = widget.programme.title;

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(64),
          child: CachedImage(
            uri: programmeImage.replaceAll('{recipe}', '624x624'),
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            fit: BoxFit.cover,
          ),
        ),
        SizedBox(height: 15),
        PlayerMetadataTitles(
            metadata: widget.programme,
            alignment: Alignment.center,
          textAlign: TextAlign.center,
        )
      ],
    );
  }
}
