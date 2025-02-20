import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/models/card.dart' as model;

class NewSocialCard extends StatelessWidget {
  final int cardId;
  final bool isUserCard; // if true, fetch from usercards table

  const NewSocialCard(
      {super.key, required this.cardId, this.isUserCard = false});

  bool isBase64(String s) => s.length > 100;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: isUserCard
          ? DatabaseHelper.instance.getUserCardById(cardId)
          : DatabaseHelper.instance.getSocialCardById(cardId),
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
              borderRadius: BorderRadius.circular(12),
              color: Colors.grey[200],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                imageWidget,
                const SizedBox(height: 4),
                Text(
                  card.title,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 2),
                Text(
                  card.grade,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
