import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/models/card.dart' as model;

class NewSocialCard extends StatelessWidget {
  final int cardId;
  const NewSocialCard({super.key, required this.cardId});

  /// A simple check to decide if [s] is a Base64 encoded image.
  bool isBase64(String s) => s.length > 100;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: DatabaseHelper.instance.getCardById(cardId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            width: 150,
            height: 220,
            child: Center(child: CircularProgressIndicator()),
          );
        } else if (!snapshot.hasData || snapshot.data == null) {
          return const SizedBox(
              width: 150,
              height: 220,
              child: Center(child: Text("Card not found")));
        } else {
          final data = snapshot.data!;
          final card = model.Card.fromMap(data);
          final imageWidget = isBase64(card.imagePath)
              ? Image.memory(
                  base64Decode(card.imagePath),
                  width: 110,
                  height: 150,
                  fit: BoxFit.cover,
                )
              : Image.asset(
                  card.imagePath,
                  width: 110,
                  height: 150,
                  fit: BoxFit.cover,
                );
          return Container(
            margin: const EdgeInsets.only(left: 25),
            width: 150,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageWidget,
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
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
              ],
            ),
          );
        }
      },
    );
  }
}
