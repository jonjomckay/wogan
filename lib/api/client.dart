import 'dart:developer';

import 'package:rest_client/rest_client.dart' as rc;

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

  Future<String> getProgrammePlaybackUri(String id, int quality) async {
    log('Getting the playback URI for the programme $id with the quality $quality');

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
      return playlistUri.toString()
          .replaceFirst('mobile_wifi_main_sd_abr_v2_uk_hls_master.m3u8',
          '$pathId-audio_eng_1=$quality.m3u8');
    } else {
      return playlistUri.toString()
          .replaceFirst('mobile_wifi_main_sd_abr_v2_uk_hls_master.m3u8',
          '$pathId-audio_eng=$quality.m3u8');
    }
  }

  Future<dynamic> getStationLatestBroadcast(String station, { String onAir = "now" }) async {
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
    var client = rc.Client();

    var request = rc.Request(
      url: 'https://rms.api.bbc.co.uk/v2/networks/playable',
    );

    var response = await client.execute(
      request: request,
    );

    return response.body;
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