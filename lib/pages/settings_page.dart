import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _openInApp = true;
  final TextEditingController _clientIdController = TextEditingController();
  final TextEditingController _clientSecretController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  _loadSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _openInApp = prefs.getBool('openInApp') ?? true;
      _clientIdController.text = prefs.getString('spotifyClientId') ?? '';
      _clientSecretController.text = prefs.getString('spotifyClientSecret') ?? '';
    });
  }

  _saveSettings() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setBool('openInApp', _openInApp);
    prefs.setString('spotifyClientId', _clientIdController.text);
    prefs.setString('spotifyClientSecret', _clientSecretController.text);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SwitchListTile(
              title: const Text('Open Spotify links in app'),
              value: _openInApp,
              onChanged: (bool value) {
                setState(() {
                  _openInApp = value;
                });
                _saveSettings();
              },
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _clientIdController,
              decoration: const InputDecoration(
                labelText: 'Spotify Client ID',
              ),
              onChanged: (value) => _saveSettings(),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _clientSecretController,
              decoration: const InputDecoration(
                labelText: 'Spotify Client Secret',
              ),
              onChanged: (value) => _saveSettings(),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('How to get your Spotify credentials'),
                      content: const Text(
                        '1. Go to Spotify Developer at https://developer.spotify.com.\n'
                        '2. Log in with your Spotify account.\n'
                        '3. Click on "Create a new App".\n'
                        '4. Fill in the required details and click "Create App".\n'
                        '5. Once the app is created, you will receive a Client ID and Client Secret.\n'
                        '6. Copy the Client ID and Client Secret and enter them in the settings fields.'
                      ),
                      actions: [
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          child: const Text('Close'),
                        ),
                      ],
                    );
                  },
                );
              },
              child: const Text('How to get your Spotify credentials'),
            ),
          ],
        ),
      ),
    );
  }
}