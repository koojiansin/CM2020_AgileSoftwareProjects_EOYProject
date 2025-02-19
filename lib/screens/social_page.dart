import 'package:flutter/material.dart';
import 'package:lgpokemon/models/card.dart'
    as model; // alias to avoid conflicts with Flutter's Card widget

class SocialPage extends StatelessWidget {
  const SocialPage({super.key});

  Widget buildCard(model.Card card) {
    return Card(
      child: SizedBox(
        width: 100,
        height: 150,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(card.imagePath,
                width: 110, height: 150, fit: BoxFit.cover),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Socials Cards'),
      ),
      body: FutureBuilder<List<model.Card>>(
        future: model.Card.fetchAllCards(),
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
