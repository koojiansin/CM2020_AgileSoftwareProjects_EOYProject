import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lgpokemon/models/card.dart' as model;
import 'package:lgpokemon/Components/card_item.dart';
import 'package:lgpokemon/helpers/database_helper.dart';

class SocialPage extends StatefulWidget {
  final String currentUser;
  const SocialPage({super.key, required this.currentUser});

  @override
  State<SocialPage> createState() => _SocialPageState();
}

class _SocialPageState extends State<SocialPage> {
  late Future<List<model.Card>> _cardsFuture;

  @override
  void initState() {
    super.initState();
    _refreshCards();
  }

  void _refreshCards() {
    setState(() {
      _cardsFuture = _fetchFriendCards();
    });
  }

  Future<List<model.Card>> _fetchFriendCards() async {
    final data =
        await DatabaseHelper.instance.getFriendCards(widget.currentUser);
    return data.map((map) => model.Card.fromMap(map)).toList();
  }

  // Helper method to check if a string is base64 encoded.
  bool _isBase64(String str) {
    // If the string appears to be an asset path, don't try decoding.
    if (str.startsWith("lib/") || str.startsWith("assets/")) return false;
    try {
      base64Decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> _showViewDialog(model.Card card) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _isBase64(card.imagePath)
                  ? Image.memory(
                      base64Decode(card.imagePath),
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      card.imagePath,
                      width: 150,
                      height: 200,
                      fit: BoxFit.cover,
                    ),
              const SizedBox(height: 10),
              Text(
                card.title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                card.grade,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text("Close"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // ...existing build code...
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend Cards'),
      ),
      body: FutureBuilder<List<model.Card>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
          final cards = snapshot.data!;
          if (cards.isEmpty)
            return const Center(child: Text("No friend cards available."));
          return GridView.builder(
            padding: const EdgeInsets.all(10),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3, // three cards per row
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.66,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showViewDialog(cards[index]),
                child: CardItem(card: cards[index]),
              );
            },
          );
        },
      ),
    );
  }
}
