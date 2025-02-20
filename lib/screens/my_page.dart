import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lgpokemon/models/card.dart'
    as model; // alias to avoid conflicts with Flutter's Card widget
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/Components/card_item.dart';

class MyPage extends StatefulWidget {
  const MyPage({super.key});

  @override
  State<MyPage> createState() => _MyPageState();
}

class _MyPageState extends State<MyPage> {
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

  Future<void> _handleAddCard(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) {
      return;
    }
    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);

    // Show popup dialog with the selected image and input fields.
    final titleController = TextEditingController();
    final gradeController = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Card"),
          content: SingleChildScrollView(
            child: Column(
              children: [
                // Preview the selected image.
                Image.memory(
                  Uint8List.fromList(bytes),
                  width: 100,
                  height: 150,
                  fit: BoxFit.cover,
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: gradeController,
                  decoration: const InputDecoration(
                    labelText: "Grade",
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                final grade = gradeController.text.trim();
                if (title.isEmpty || grade.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("All fields are required.")),
                  );
                  return;
                }
                // Build new card map, storing the image as its Base64 string.
                final newCard = {
                  'title': title,
                  'grade': grade,
                  'imagePath': base64Image,
                };
                await DatabaseHelper.instance.insertCard(newCard);
                Navigator.of(context).pop();
                _refreshCards();
              },
              child: const Text("Add"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showDeleteDialog(model.Card card) async {
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
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                card.grade,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              // Delete button
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteCard(card.id!);
                  Navigator.of(context).pop();
                  _refreshCards();
                },
                child: const Text(
                  "Delete",
                  style: TextStyle(color: Colors.white),
                ),
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
        title: const Text('My Cards'),
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
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.66,
            ),
            itemCount: cards.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _showDeleteDialog(cards[index]),
                child: CardItem(card: cards[index]),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _handleAddCard(context),
        child: const Icon(Icons.camera_alt),
      ),
    );
  }
}
