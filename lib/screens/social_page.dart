import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lgpokemon/models/card.dart'
    as model; // alias to avoid conflicts with Flutter's Card widget
import 'package:lgpokemon/helpers/database_helper.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

  @override
  State<SocialPage> createState() => _MyPageState();
}

class _MyPageState extends State<SocialPage> {
  late Future<List<model.Card>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = model.Card.fetchAllCards();
    });
  }

  Widget buildCard(model.Card card) {
    // If the card.imagePath is a Base64 string, use MemoryImage. Otherwise, assume it's an asset path.
    final imageWidget = isBase64(card.imagePath)
        ? Image.memory(base64Decode(card.imagePath),
            width: 110, height: 150, fit: BoxFit.cover)
        : Image.asset(card.imagePath,
            width: 110, height: 150, fit: BoxFit.cover);

    return Card(
      child: SizedBox(
        width: 100,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            imageWidget,
            Text(
              card.title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              card.grade,
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  bool isBase64(String s) {
    // Simple check: if string contains "data:" it's not base64, otherwise assume it is, or use length check.
    return s.length > 100; // adjust as needed
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Social Cards'),
      ),
      body: FutureBuilder<List<model.Card>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snapshot.data!;
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // 3 columns per row
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.66, // approximates a card of 100x150
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return buildCard(cards[index]);
            },
          );
        },
      ),
    );
  }
}
