import 'package:flutter/material.dart';
import 'package:song_recommender/pages/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Song Recommender',
      theme: ThemeData.dark(),
      home: const HomePage(),
    );
  }
}
