import 'package:rest_client/rest_client.dart' as rc;

class SoundsApi {
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
}