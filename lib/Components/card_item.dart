import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:lgpokemon/models/card.dart' as model;

class CardItem extends StatelessWidget {
  final model.Card card;
  final double width;
  final double height;

  const CardItem({
    Key? key,
    required this.card,
    this.width = 100,
    this.height = 150,
  }) : super(key: key);

  bool _isBase64(String s) => s.length > 100;

  @override
  Widget build(BuildContext context) {
    final imageWidget = _isBase64(card.imagePath)
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

    return Card(
      child: SizedBox(
        width: width,
        height: height,
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
      ),
    );
  }
}
