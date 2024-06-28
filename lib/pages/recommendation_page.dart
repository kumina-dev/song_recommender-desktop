import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class RecommendationPage extends StatefulWidget {
  const RecommendationPage({
    super.key,
    required this.songName,
    required this.artistName,
    required this.imageUrl,
    required this.previewUrl,
    required this.spotifyUri,
  });

  final String songName;
  final String artistName;
  final String imageUrl;
  final String previewUrl;
  final String spotifyUri;

  @override
  State<RecommendationPage> createState() => _RecommendationPageState();
}

class _RecommendationPageState extends State<RecommendationPage> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  double _volume = 0.5;
  bool _openInApp = true;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        if (state == PlayerState.playing) {
          setState(() {
            _isPlaying = true;
          });
        } else {
          setState(() {
            _isPlaying = false;
          });
        }
      }
    });
    _loadSettings();
    _loadVolume();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _openInApp = prefs.getBool('openInApp') ?? true;
    });
  }

  Future<void> _loadVolume() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _volume = prefs.getDouble('volume') ?? 0.5;
    });
    _audioPlayer.setVolume(_volume);
  }

  Future<void> _saveVolume(double volume) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('volume', volume);
  }

  void _openSpotifyLink() async {
    if (_openInApp) {
      final uri = Uri.parse(widget.spotifyUri);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        throw 'Could not launch $uri';
      }
    } else {
      final trackId = widget.spotifyUri.split(':').last;
      final webUrl = Uri.parse('https://open.spotify.com/track/$trackId');
      if (await canLaunchUrl(webUrl)) {
        await launchUrl(webUrl);
      } else {
        throw 'Could not launch $webUrl';
      }
    }
  }

  void _playPreview() async {
    if (mounted) {
      if (_isPlaying) {
        await _audioPlayer.stop();
      } else {
        await _audioPlayer.play(UrlSource(widget.previewUrl), volume: _volume);
      }
    }
  }

  void _setVolume(double volume) {
    setState(() {
      _volume = volume;
    });
    _audioPlayer.setVolume(volume);
    _saveVolume(volume);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recommendation Details'),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 250,
              child: Image.network(
                widget.imageUrl,
                fit: BoxFit.cover,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text(
                    widget.songName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    widget.artistName,
                    style: const TextStyle(fontSize: 18),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      ElevatedButton(
                        onPressed: _openSpotifyLink,
                        child: const Text('Open in Spotify'),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _playPreview,
                        child: _isPlaying
                            ? const Text('Stop Preview')
                            : const Text('Play Preview'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (widget.previewUrl.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Volume'),
                        Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: _setVolume,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}