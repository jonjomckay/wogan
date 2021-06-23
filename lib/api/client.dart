import 'dart:developer';

import 'package:rest_client/rest_client.dart' as rc;
import 'package:wogan/database.dart';
import 'package:wogan/models/station.dart';
import 'package:wogan/models/station_model.dart';

class SoundsApi {
  Future<dynamic> getProgramme(String id) async {
    log('Loading the programme $id');

    var client = rc.Client();

    var request = rc.Request(
      url: 'https://rms.api.bbc.co.uk/v2/programmes/$id/item'
    );

    var response = await client.execute(request: request);

    return response.body;
  }

  Future<dynamic> getProgrammeEpisodes(String id) async {
    log('Loading episodes for the programme $id');

    var client = rc.Client();

    var uri = Uri.https('rms.api.bbc.co.uk', '/v2/programmes/playable', {
      'container': id,
      'sort': 'sequential',
      'type': 'episode'
    });

    var request = rc.Request(
        url: uri.toString()
    );

    var response = await client.execute(request: request);

    return response.body;
  }

  Future<dynamic> getEpisodeTracks(String id) async {
    log('Loading the tracks for the epiosde $id');

    var client = rc.Client();

    var uri = Uri.https('rms.api.bbc.co.uk', '/v2/versions/$id/segments');

    var request = rc.Request(
        url: uri.toString()
    );

    var response = await client.execute(request: request);

    return response.body;
  }

  Future<Uri> getEpisodePlaybackUri(String id, int quality) async {
    log('Getting the playback URI for the episode $id with the quality $quality');

    var client = rc.Client();

    var uri = Uri.https('open.live.bbc.co.uk', '/mediaselector/6/select/version/2.0/mediaset/apple-ipad-hls/vpid/$id/format/json');

    var request = rc.Request(
      url: uri.toString(),
    );

    var response = await client.execute(request: request);

    var results = List.from(response.body['media']);

    var playlistUri = Uri.parse(results
        .where((element) => element['service'] == 'stream-uk-audio_streaming_concrete_combined')
        .map((e) => e['connection'][0]['href'])
        .first);

    var pathId = playlistUri.pathSegments[5].replaceFirst('.ism', '');

    if (quality <= 96000) {
      return Uri.parse(playlistUri.toString()
          .replaceFirst('mobile_wifi_main_sd_abr_v2_uk_hls_master.m3u8',
          '$pathId-audio_eng_1=$quality.m3u8'));
    } else {
      return Uri.parse(playlistUri.toString()
          .replaceFirst('mobile_wifi_main_sd_abr_v2_uk_hls_master.m3u8',
          '$pathId-audio_eng=$quality.m3u8'));
    }
  }

  Future<dynamic> getStationLatestBroadcast(String station, { String onAir = "now" }) async {
    log('Getting the latest broadcast from the station $station');

    var client = rc.Client();

    var uri = Uri.https('rms.api.bbc.co.uk', '/v2/broadcasts/latest', {
      'service': station,
      'on_air': onAir
    });

    var request = rc.Request(
      url: uri.toString(),
    );

    var response = await client.execute(
      request: request,
    );

    return response.body;
  }

  Future<dynamic> listMusicExperiences() async {
    var client = rc.Client();

    var request = rc.Request(
      url: 'https://rms.api.bbc.co.uk/v2/experience/inline/music',
    );

    var response = await client.execute(
      request: request,
    );

    return response.body;
  }

  Future<dynamic> listStations() async {
    log('Listing all playable stations');

    var client = rc.Client();

    var request = rc.Request(
      url: 'https://rms.api.bbc.co.uk/v2/networks/playable',
    );

    var response = await client.execute(
      request: request,
    );

    var body = response.body;

    var database = StationModel();

    await database.saveStations(List.from(body['data'])
        .map((e) => Station(
      id: e['id'],
      urn: e['urn'],
      coverage: e['coverage'] ?? '',
      logoUrl: e['network']['logo_url'],
      longTitle: '',
      // longTitle: e['network']['long_title'],
      shortTitle: e['network']['short_title']
    ))
        .toList()
    );

    return body;
  }

  Future<dynamic> searchProgrammes(String query) async {
    log('Searching programmes for $query');

    var client = rc.Client();

    var uri = Uri.https('rms.api.bbc.co.uk', '/v2/programmes/search/container', {
      'q': query,
    });

    var request = rc.Request(
      url: uri.toString()
    );

    var response = await client.execute(request: request);

    return response.body;
  }
}