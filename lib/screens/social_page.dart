import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lgpokemon/models/card.dart'
    as model; // alias to avoid conflicts with Flutter's Card widget
import 'package:lgpokemon/Components/card_item.dart';

class SocialPage extends StatefulWidget {
  const SocialPage({super.key});

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
      _cardsFuture = model.Card.fetchAllCards();
    });
  }

  Future<void> _showViewDialog(model.Card card) async {
    return showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Display card image
              (card.imagePath.length > 100)
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
              // Card details
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
