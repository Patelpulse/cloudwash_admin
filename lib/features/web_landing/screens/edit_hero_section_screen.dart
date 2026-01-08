import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_admin/features/web_landing/models/hero_section_model.dart';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class EditHeroSectionScreen extends ConsumerStatefulWidget {
  const EditHeroSectionScreen({super.key});

  @override
  ConsumerState<EditHeroSectionScreen> createState() =>
      _EditHeroSectionScreenState();
}

class _EditHeroSectionScreenState extends ConsumerState<EditHeroSectionScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _taglineController;
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _buttonTextController;
  late TextEditingController _youtubeUrlController;

  bool _isLoading = false;
  bool _isActive = true;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;

  // Use http for simple requests as seen elsewhere, or Dio. I'll use http for file upload consistency with backend
  // Assuming BASE_URL is available via flutter_dotenv or AppConfig
  // For now I'll hardcode or deduce. "http://localhost:5001/api"
  final String _baseUrl = AppConfig.apiUrl;

  @override
  void initState() {
    super.initState();
    _taglineController = TextEditingController();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
    _buttonTextController = TextEditingController();
    _youtubeUrlController = TextEditingController();
    _fetchHeroSection();
  }

  @override
  void dispose() {
    _taglineController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _buttonTextController.dispose();
    _youtubeUrlController.dispose();
    super.dispose();
  }

  Future<void> _fetchHeroSection() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hero'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final hero = HeroSectionModel.fromJson(data);

        _taglineController.text = hero.tagline;
        _titleController.text = hero.mainTitle;
        _descriptionController.text = hero.description;
        _buttonTextController.text = hero.buttonText;
        _youtubeUrlController.text = hero.youtubeUrl ?? '';
        setState(() {
          _imageUrl = hero.imageUrl;
          _isActive = hero.isActive;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));

      request.fields['tagline'] = _taglineController.text;
      request.fields['mainTitle'] = _titleController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['buttonText'] = _buttonTextController.text;
      request.fields['youtubeUrl'] = _youtubeUrlController.text;
      request.fields['isActive'] = _isActive.toString();

      if (_selectedImageBytes != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'image',
            _selectedImageBytes!,
            filename: 'hero_image.png',
            contentType: MediaType('image', 'png'),
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Hero section updated!')));
        _fetchHeroSection(); // Refresh
      } else {
        throw Exception('Failed to update: ${response.statusCode}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _taglineController.text.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Hero Section'),
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _save,
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image Section
              Center(
                child: Column(
                  children: [
                    Container(
                      height: 200,
                      width: 400,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: _selectedImageBytes != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.memory(_selectedImageBytes!,
                                  fit: BoxFit.cover),
                            )
                          : (_imageUrl != null && _imageUrl!.isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(_imageUrl!,
                                      fit: BoxFit.cover),
                                )
                              : const Icon(Icons.image,
                                  size: 50, color: Colors.grey)),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _pickImage,
                      icon: const Icon(Icons.upload),
                      label: const Text('Change Hero Image'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Fields
              TextFormField(
                controller: _taglineController,
                decoration: const InputDecoration(
                  labelText: 'Tagline',
                  hintText: 'e.g. ✨ We Are Clino',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Main Title',
                  hintText: 'e.g. Feel Your Way For Freshness',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _buttonTextController,
                decoration: const InputDecoration(
                  labelText: 'Button Text',
                  hintText: 'e.g. Our Services',
                  border: OutlineInputBorder(),
                ),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _youtubeUrlController,
                decoration: const InputDecoration(
                  labelText: 'YouTube Video URL',
                  hintText: 'e.g. https://www.youtube.com/watch?v=...',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.video_library),
                ),
              ),
              const SizedBox(height: 16),

              // Active Switch
              SwitchListTile(
                title: const Text('Is Active?'),
                value: _isActive,
                onChanged: (val) => setState(() => _isActive = val),
              ),

              const SizedBox(height: 32),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _save,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[900],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Update Hero Section',
                          style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
