import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lgpokemon/helpers/database_helper.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart' as path_provider;

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();

  // Static method to show add news dialog from outside the class
  // Now takes a refresh callback parameter
  static void showAddNewsDialog(BuildContext context) {
    // Get the state of the AdminScreen to access its refresh method
    final _AdminScreenState? adminState =
        context.findAncestorStateOfType<_AdminScreenState>();

    showDialog(
      context: context,
      builder: (context) => AddNewsDialog(
        // Pass the refresh callback to the dialog
        onNewsAdded: adminState?._refreshNews,
      ),
    );
  }
}

class _AdminScreenState extends State<AdminScreen> {
  late Future<List<Map<String, dynamic>>> _newsFuture;

  // GlobalKey to access this state from static methods
  final GlobalKey<_AdminScreenState> stateKey = GlobalKey<_AdminScreenState>();

  @override
  void initState() {
    super.initState();
    _refreshNews();
  }

  void _refreshNews() {
    setState(() {
      _newsFuture = DatabaseHelper.instance.getNews();
    });
    debugPrint("News list refreshed");
  }

  Future<void> _deleteNews(int id) async {
    try {
      await DatabaseHelper.instance.deleteNews(id);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("News deleted successfully")),
      );
      _refreshNews();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to delete news: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Admin Panel"),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Manage News",
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Add a button to manually add news within the screen
                ElevatedButton.icon(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AddNewsDialog(
                        onNewsAdded: _refreshNews,
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text("Add News"),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Map<String, dynamic>>>(
              future: _newsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text("Error: ${snapshot.error}"),
                  );
                }

                final newsList = snapshot.data ?? [];
                if (newsList.isEmpty) {
                  return const Center(
                    child: Text("No news available"),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: newsList.length,
                  itemBuilder: (context, index) {
                    final news = newsList[index];
                    final id = news['id'] as int;
                    final title = news['title'] as String;
                    final date = news['date'] as String;
                    final imgPath = news['imgPath'] as String;

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          vertical: 8, horizontal: 4),
                      child: ListTile(
                        leading: SizedBox(
                          width: 60,
                          height: 60,
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: _buildNewsImage(imgPath),
                          ),
                        ),
                        title: Text(title),
                        subtitle: Text(date),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteNews(id),
                        ),
                        onTap: () {
                          // Show full news details in a dialog
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text(title),
                              content: SingleChildScrollView(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text("Date: $date"),
                                    const SizedBox(height: 8),
                                    Text("Content: ${news['description']}"),
                                    const SizedBox(height: 16),
                                    if (imgPath.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: double.infinity,
                                          height: 200,
                                          child: _buildNewsImage(imgPath),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(context).pop(),
                                  child: const Text("Close"),
                                ),
                              ],
                            ),
                          );
                        },
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

  // Helper method to properly handle different image sources
  Widget _buildNewsImage(String imgPath) {
    try {
      // First try loading as an asset
      if (imgPath.startsWith('lib/') || imgPath.startsWith('assets/')) {
        return Image.asset(
          imgPath,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            // If asset loading fails, try file loading
            return _tryLoadFile(imgPath);
          },
        );
      } else {
        // Try loading as a file
        return _tryLoadFile(imgPath);
      }
    } catch (e) {
      debugPrint("Error loading image: $e");
      return const Icon(Icons.broken_image, size: 50);
    }
  }

  Widget _tryLoadFile(String imgPath) {
    try {
      final file = File(imgPath);
      if (file.existsSync()) {
        return Image.file(
          file,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(Icons.broken_image, size: 50);
          },
        );
      }
      return const Icon(Icons.broken_image, size: 50);
    } catch (e) {
      return const Icon(Icons.broken_image, size: 50);
    }
  }
}

class AddNewsDialog extends StatefulWidget {
  final VoidCallback? onNewsAdded;

  const AddNewsDialog({Key? key, this.onNewsAdded}) : super(key: key);

  @override
  _AddNewsDialogState createState() => _AddNewsDialogState();
}

class _AddNewsDialogState extends State<AddNewsDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dateController = TextEditingController();
  String? _imagePath;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    // Set today's date as default
    final now = DateTime.now();
    _dateController.text = "${now.toLocal()}".split(' ')[0];
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
      );

      if (image != null) {
        // Save image to app directory
        final directory =
            await path_provider.getApplicationDocumentsDirectory();
        final fileName =
            'news_${DateTime.now().millisecondsSinceEpoch}${path.extension(image.path)}';
        final savedImage =
            await File(image.path).copy('${directory.path}/$fileName');

        setState(() {
          _imagePath = savedImage.path;
        });
      }
    } catch (e) {
      debugPrint("Error picking image: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to pick image: $e")),
      );
    }
  }

  Future<void> _submitNews() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_imagePath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select an image")),
      );
      return;
    }

    try {
      final news = {
        'title': _titleController.text,
        'description': _descriptionController.text,
        'date': _dateController.text,
        'imgPath': _imagePath!,
      };

      await DatabaseHelper.instance.insertNews(news);

      // Close the dialog first
      if (mounted) {
        Navigator.pop(context);
      }

      // Then refresh the news list and show confirmation
      if (widget.onNewsAdded != null) {
        widget.onNewsAdded!();
        debugPrint("News added, refreshing list");
      } else {
        debugPrint("News added, but no refresh callback provided");
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("News added successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to add news: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text("Add News"),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a title";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a description";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _dateController,
                decoration: const InputDecoration(
                  labelText: "Date (YYYY-MM-DD)",
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return "Please enter a date";
                  }
                  // Simple date validation
                  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
                    return "Please enter a valid date format (YYYY-MM-DD)";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 120,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: _imagePath == null
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 40),
                              Text("Select Image"),
                            ],
                          ),
                        )
                      : Image.file(
                          File(_imagePath!),
                          fit: BoxFit.cover,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel"),
        ),
        ElevatedButton(
          onPressed: _submitNews,
          child: const Text("Add"),
        ),
      ],
    );
  }
}
