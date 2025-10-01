import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class AddItemPage extends StatefulWidget {
  const AddItemPage({super.key});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();
  final List<File> _images = [];

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source) async {
    final XFile? pickedFile = await _picker.pickImage(source: source);
    if (pickedFile != null) {
      setState(() {
        _images.add(File(pickedFile.path));
      });
    }
  }

  void _showImageSourceActionSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text("Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text("Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _submitItem() {
    if (_titleController.text.isEmpty || _descController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    // Example: handle save logic
    print("Title: ${_titleController.text}");
    print("Description: ${_descController.text}");
    print("Images: ${_images.map((e) => e.path).toList()}");

    Navigator.pop(context); // Go back after saving
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Add Item to Lend"),
        backgroundColor: Color(0xFF93B9E1)
        ,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: "Item Title",
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: "Description",
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),

            // Show selected images
            _images.isNotEmpty
                ? Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _images
                  .map((file) => ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(
                  file,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                ),
              ))
                  .toList(),
            )
                : const Text("No images added yet"),
            const SizedBox(height: 16),

            // Single "Add Image" button
            Center(
              child: ElevatedButton.icon(
                onPressed: _showImageSourceActionSheet,
                icon: const Icon(Icons.add_a_photo),
                label: const Text("Add Image"),

              ),
            ),

            const SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: _submitItem,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF93B9E1),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                ),
                child: const Text("Submit Item"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
