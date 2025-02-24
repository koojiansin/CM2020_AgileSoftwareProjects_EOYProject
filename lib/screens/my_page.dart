import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lgpokemon/models/card.dart' as model;
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:lgpokemon/Components/card_item.dart';

class MyPage extends StatefulWidget {
  final String currentUser;
  const MyPage({super.key, required this.currentUser});

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
      _cardsFuture = model.Card.fetchUserCards(widget.currentUser);
    });
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

  Future<void> _handleAddCard(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile == null) return;

    final bytes = await pickedFile.readAsBytes();
    final base64Image = base64Encode(bytes);
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
                final newCard = {
                  'title': title,
                  'grade': grade,
                  'imagePath': base64Image,
                  'username': widget.currentUser,
                };
                await DatabaseHelper.instance.insertUserCard(newCard);
                _refreshCards();
                Navigator.of(context).pop(true);
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
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () async {
                  await DatabaseHelper.instance.deleteUserCard(card.id!);
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
    // ...existing build code...
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Cards'),
      ),
      body: FutureBuilder<List<model.Card>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (!snapshot.hasData)
            return const Center(child: CircularProgressIndicator());
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
