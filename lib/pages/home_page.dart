import 'package:flutter/material.dart';
import 'package:song_recommender/pages/recommendation_page.dart';
import 'package:song_recommender/pages/settings_page.dart';
import 'package:song_recommender/services/spotify_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _artistController = TextEditingController();
  final SpotifyService _spotifyService = SpotifyService();
  List<dynamic> _recommendations = [];
  late TabController _tabController;
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  void _searchRecommendations() async {
    final query = _searchController.text.trim();
    final artist = _artistController.text.trim();

    if (query.isEmpty) {
      setState(() {
        _errorMessage = 'Input cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      List<dynamic> results = await _fetchRecommendations(query, artist);
      setState(() {
        _recommendations = results;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString() == 'Exception: Spotify credentials are not set'
          ? 'Please set your Spotify credentials in the settings page'
          : 'An error occurred while fetching recommendations';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<List<dynamic>> _fetchRecommendations(String query, String artist) async {
    if (_tabController.index == 0) {
      return await _spotifyService.getRecommendationsBySongName(query, artist);
    } else if (_tabController.index == 1) {
      return await _spotifyService.getRecommendationsBySongUrl(query);
    } else {
      throw Exception('Invalid input');
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Help - Song Recommender'),
          content: const SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('This tool helps you find song recommendations based on either a song name and artist, or a Spotify song URL.'),
                SizedBox(height: 10),
                Text('To use:'),
                Text('- Enter a song name and artist, or a Spotify song URL.'),
                Text('- Switch tabs to select either "Song Name & Artist" or "Song URL".'),
                Text('- Press the "Get Recommendations" button to get song recommendations.'),
                SizedBox(height: 10),
                Text('Note:'),
                Text('- Make sure your input is correct and matches a valid Spotify song.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Close'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            )
          ],
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Song Recommender'),
            const SizedBox(width: 10),
            IconButton(
              icon: const Icon(Icons.help),
              onPressed: _showHelpDialog,
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Song Name & Artist'),
            Tab(text: 'Song URL'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildNameArtistInput(),
          _buildUrlInput(),
        ],
      ),
    );
  }

  Widget _buildNameArtistInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter song name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _artistController,
            decoration: InputDecoration(
              hintText: 'Enter artist name...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              prefixIcon: const Icon(Icons.person),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _artistController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _searchRecommendations,
            child: const Text('Get Recommendations'),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : _buildRecommendationsList(),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUrlInput() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Enter song URL...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              prefixIcon: const Icon(Icons.link),
              suffixIcon: IconButton(
                icon: const Icon(Icons.clear),
                onPressed: () {
                  _searchController.clear();
                },
              ),
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _searchRecommendations,
            child: const Text('Get Recommendations'),
          ),
          const SizedBox(height: 20),
          _isLoading
              ? const CircularProgressIndicator()
              : _buildRecommendationsList(),
          if (_errorMessage.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRecommendationsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _recommendations.length,
        itemBuilder: (context, index) {
          final song = _recommendations[index];
          return ListTile(
            title: Text(song['name']),
            subtitle: Text(song['artists'][0]['name']),
            leading: Image.network(song['album']['images'][0]['url']),
            onTap: () {
              if (song['preview_url'] != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => RecommendationPage(
                      songName: song['name'],
                      artistName: song['artists'][0]['name'],
                      imageUrl: song['album']['images'][0]['url'],
                      previewUrl: song['preview_url'],
                      spotifyUri: song['uri'],
                    ),
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('No preview available'),
                  ),
                );
              }
            },
          );
        },
      ),
    );
  }
}
