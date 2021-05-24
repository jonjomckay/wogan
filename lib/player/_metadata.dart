import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ProgrammeMetadata {
  final String imageUri;
  final String date;
  final String description;
  final Duration duration;
  final DateTime endsAt;
  final DateTime startsAt;
  final String stationId;
  final String stationName;
  final String title;

  ProgrammeMetadata(
      {required this.imageUri, required this.date, required this.description, required this.duration, required this.endsAt, required this.startsAt, required this.stationId, required this.stationName, required this.title});
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
        CachedNetworkImage(
          imageUrl: programmeImage.replaceAll('{recipe}', '624x624'),
          filterQuality: FilterQuality.high,
          width: MediaQuery.of(context).size.width * 0.9,
          height: MediaQuery.of(context).size.width * 0.9,
          placeholder: (context, url) => Container(
            margin: EdgeInsets.all(32),
            alignment: Alignment.center,
            width: MediaQuery.of(context).size.width * 0.9,
            height: MediaQuery.of(context).size.width * 0.9,
            child: Center(child: CircularProgressIndicator()),
          ),
          errorWidget: (context, url, error) => Icon(Icons.error),
          imageBuilder: (context, imageProvider) => Container(
            decoration: BoxDecoration(
              shape: BoxShape.rectangle,
              image: DecorationImage(
                  image: imageProvider,
                  fit: BoxFit.contain
              ),
            ),
          ),
        ),
        SizedBox(height: 15),
        Container(
          margin: EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text(programmeDate,
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: Theme.of(context).hintColor,
                  fontWeight: FontWeight.bold
              )),
        ),
        Container(
          margin: EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text(programmeTitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 26,
                  fontWeight: FontWeight.bold
              )),
        ),
        Container(
          margin: EdgeInsets.all(4),
          alignment: Alignment.center,
          child: Text(programmeSubtitle,
              textAlign: TextAlign.center,
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
