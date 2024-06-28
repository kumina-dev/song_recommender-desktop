import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SpotifyService {
  String _clientId = '';
  String _clientSecret = '';
  String? _accessToken;

  final Dio dio = Dio();

  SpotifyService() {
    _loadCredentials();
  }

  Future<void> _loadCredentials() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _clientId = prefs.getString('spotifyClientId') ?? '';
    _clientSecret = prefs.getString('spotifyClientSecret') ?? '';
  }

  Future<void> _authenticate() async {
    const String authUrl = 'https://accounts.spotify.com/api/token';
    final String credentials = '$_clientId:$_clientSecret';
    final String encodedCredentials = base64Encode(utf8.encode(credentials));

    if (_clientId.isEmpty || _clientSecret.isEmpty) {
      throw Exception('Missing Spotify credentials');
    }

    final response = await dio.post(
      authUrl,
      options: Options(
        headers: {
          'Authorization': 'Basic $encodedCredentials',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
      data: {
        'grant_type': 'client_credentials',
      },
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      _accessToken = data['access_token'];
    } else {
      throw Exception('Failed to authenticate with Spotify');
    }
  }

  Future<List<dynamic>> getRecommendationsBySongName(String songName, String artist) async {
    if (_accessToken == null) {
      await _authenticate();
    }

    const String searchUrl = 'https://api.spotify.com/v1/search';
    final response = await dio.get(
      searchUrl,
      queryParameters: {
        'q': 'track:$songName artist:$artist',
        'type': 'track',
        'limit': 1,
      },
      options: Options(
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      if (data['tracks']['items'].isNotEmpty) {
        final trackId = data['tracks']['items'][0]['id'];
        return getRecommendationsByTrackId(trackId);
      } else {
        throw Exception('No tracks found');
      }
    } else {
      throw Exception('Failed to search for song');
    }
  }

  Future<List<dynamic>> getRecommendationsBySongUrl(String songUrl) async {
    if (_accessToken == null) {
      await _authenticate();
    }

    try {
      final trackId = songUrl.split('/').last.split('?').first;
      return getRecommendationsByTrackId(trackId);
    } catch (e) {
      throw Exception('Invalid song URL');
    }
  }

  Future<List<dynamic>> getRecommendationsByTrackId(String trackId) async {
    if (_accessToken == null) {
      await _authenticate();
    }

    final String recommendationsUrl = 'https://api.spotify.com/v1/recommendations?seed_tracks=$trackId';
    final response = await dio.get(
      recommendationsUrl,
      options: Options(
        headers: {
          'Authorization': 'Bearer $_accessToken',
        },
        validateStatus: (status) {
          return status != null && status >= 200 && status < 300;
        },
      ),
    );

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = response.data;
      return data['tracks'];
    } else {
      throw Exception('Failed to get recommendations');
    }
  }
}
