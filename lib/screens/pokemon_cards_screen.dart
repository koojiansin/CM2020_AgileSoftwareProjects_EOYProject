import 'package:flutter/material.dart';
import 'package:lgpokemon/helpers//pokemon_tcg_service.dart';

class PokemonCardsScreen extends StatefulWidget {
  const PokemonCardsScreen({super.key});

  @override
  _PokemonCardsScreenState createState() => _PokemonCardsScreenState();
}

class _PokemonCardsScreenState extends State<PokemonCardsScreen> {
  final PokemonTCGService _pokemonService = PokemonTCGService();
  late Future<List<dynamic>> _pokemonCardsFuture;
  late Future<List<dynamic>> _pokemonSetsFuture;
  String _selectedSetId = "swsh1"; // Default set

  @override
  void initState() {
    super.initState();
    _pokemonSetsFuture = _pokemonService.fetchSets();
    _fetchCards(); // Fetch initial set
  }

  void _fetchCards() {
    setState(() {
      _pokemonService.clearCache(); // Clear cache before fetching new set
      _pokemonCardsFuture = _pokemonService.fetchCardsBySet(_selectedSetId);
    });
  }

  void _showCardPopup(BuildContext context, Map<String, dynamic> card) {
    final String name = card["name"];
    final String imageUrl = card["images"]["large"] ?? card["images"]["small"];

    // Build a rich text description
    List<TextSpan> descriptionSpans = [];

    // Check for card text descriptions
    if (card["text"] != null && card["text"].isNotEmpty) {
      descriptionSpans.add(TextSpan(
        text: card["text"].join("\n") + "\n\n",
        style: const TextStyle(fontSize: 14),
      ));
    }

    // Check for abilities
    if (card["abilities"] != null) {
      for (var ability in card["abilities"]) {
        descriptionSpans.add(
          TextSpan(
            text: "Ability: ${ability["name"]}\n",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
        descriptionSpans.add(TextSpan(
          text: "${ability["text"]}\n\n",
          style: const TextStyle(fontSize: 14),
        ));
      }
    }

    // Check for attacks
    if (card["attacks"] != null) {
      for (var attack in card["attacks"]) {
        descriptionSpans.add(
          TextSpan(
            text: "Attack: ${attack["name"]}\n",
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        );
        descriptionSpans.add(TextSpan(
          text: "${attack["text"] ?? "No description"}\nDamage: ${attack["damage"]}\n\n",
          style: const TextStyle(fontSize: 14),
        ));
      }
    }

    // Check for rules (for Trainer and Energy cards)
    if (card["rules"] != null) {
      descriptionSpans.add(
        TextSpan(
          text: "Rules:\n",
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
      );
      descriptionSpans.add(TextSpan(
        text: "${card["rules"].join("\n")}\n\n",
        style: const TextStyle(fontSize: 14),
      ));
    }

    // If no description is found, show fallback text
    if (descriptionSpans.isEmpty) {
      descriptionSpans.add(TextSpan(
        text: "No description available.",
        style: const TextStyle(fontSize: 14),
      ));
    }

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(name, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Image.network(imageUrl, height: 350, fit: BoxFit.cover),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  child: RichText(
                    textAlign: TextAlign.center,
                    text: TextSpan(
                      style: const TextStyle(color: Colors.black), // Default text color
                      children: descriptionSpans,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Close"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Pokémon Cards")),
      body: Column(
        children: [
          // Dropdown for selecting set
          Padding(
            padding: const EdgeInsets.all(10.0),
            child: FutureBuilder<List<dynamic>>(
              future: _pokemonSetsFuture,
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final sets = snapshot.data!;
                return DropdownButton<String>(
                  value: _selectedSetId,
                  isExpanded: true,
                  items: sets.map<DropdownMenuItem<String>>((set) {
                    return DropdownMenuItem<String>(
                      value: set["id"],
                      child: Text(set["name"]),
                    );
                  }).toList(),
                  onChanged: (String? newSetId) {
                    if (newSetId != null && newSetId != _selectedSetId) {
                      setState(() {
                        _selectedSetId = newSetId;
                      });
                      _fetchCards(); // Fetch new set data
                    }
                  },
                );
              },
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: _pokemonCardsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text("Error: ${snapshot.error}"));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return const Center(child: Text("No Pokémon cards found"));
                }

                final cards = snapshot.data!;
                return GridView.builder(
                  padding: const EdgeInsets.all(10),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.8,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemCount: cards.length,
                  itemBuilder: (context, index) {
                    final card = cards[index];
                    final imageUrl = card["images"]["small"];
                    final name = card["name"];

                    return GestureDetector(
                      onTap: () => _showCardPopup(context, card),
                      child: Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 5,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.network(imageUrl, height: 200, fit: BoxFit.cover),
                            const SizedBox(height: 8),
                            Text(
                              name,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
