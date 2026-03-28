import 'package:cloud_admin/features/web_landing/models/about_us_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_admin/core/config/app_config.dart';

class EditAboutUsScreen extends ConsumerStatefulWidget {
  const EditAboutUsScreen({super.key});

  @override
  ConsumerState<EditAboutUsScreen> createState() => _EditAboutUsScreenState();
}

class _EditAboutUsScreenState extends ConsumerState<EditAboutUsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _desc1Controller;
  late TextEditingController _desc2Controller;
  late TextEditingController _visionTitleController;
  late TextEditingController _visionDescController;
  late TextEditingController _missionTitleController;
  late TextEditingController _missionDescController;

  bool _isLoading = false;
  bool _isActive = true;
  String? _imageUrl;
  Uint8List? _selectedImageBytes;
  final String _baseUrl = AppConfig.apiUrl;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _desc1Controller = TextEditingController();
    _desc2Controller = TextEditingController();
    _visionTitleController = TextEditingController();
    _visionDescController = TextEditingController();
    _missionTitleController = TextEditingController();
    _missionDescController = TextEditingController();
    _fetchData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _desc1Controller.dispose();
    _desc2Controller.dispose();
    _visionTitleController.dispose();
    _visionDescController.dispose();
    _missionTitleController.dispose();
    _missionDescController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/web-content/about'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final about = AboutUsModel.fromJson(data);

        _titleController.text = about.title;
        _desc1Controller.text = about.description1;
        _desc2Controller.text = about.description2;
        _visionTitleController.text = about.visionTitle;
        _visionDescController.text = about.visionDescription;
        _missionTitleController.text = about.missionTitle;
        _missionDescController.text = about.missionDescription;

        setState(() {
          _imageUrl = about.imageUrl;
          _isActive = about.isActive;
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
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      var request = http.MultipartRequest(
          'PUT', Uri.parse('$_baseUrl/web-content/about'));

      request.fields['title'] = _titleController.text;
      request.fields['description1'] = _desc1Controller.text;
      request.fields['description2'] = _desc2Controller.text;
      request.fields['visionTitle'] = _visionTitleController.text;
      request.fields['visionDescription'] = _visionDescController.text;
      request.fields['missionTitle'] = _missionTitleController.text;
      request.fields['missionDescription'] = _missionDescController.text;
      request.fields['isActive'] = _isActive.toString();

      if (_selectedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: 'about_us.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved Successfully')));
        _fetchData(); 
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit About Us Page')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Section
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: double.infinity,
                          height: 250,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            border: Border.all(color: Colors.grey.shade400),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _selectedImageBytes != null
                              ? Image.memory(_selectedImageBytes!,
                                  fit: BoxFit.cover)
                              : (_imageUrl != null && _imageUrl!.isNotEmpty)
                                  ? Image.network(_imageUrl!, fit: BoxFit.cover)
                                  : const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_a_photo,
                                            size: 40, color: Colors.grey),
                                        SizedBox(height: 8),
                                        Text('Tap to upload image',
                                            style:
                                                TextStyle(color: Colors.grey)),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    TextFormField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Main Page Title',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _desc1Controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description Paragraph 1',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const SizedBox(height: 16),

                    TextFormField(
                      controller: _desc2Controller,
                      maxLines: 4,
                      decoration: const InputDecoration(
                        labelText: 'Description Paragraph 2',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Required' : null,
                    ),
                    const Divider(height: 48),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _visionTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Vision Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _visionDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Vision Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _missionTitleController,
                            decoration: const InputDecoration(
                              labelText: 'Mission Title',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _missionDescController,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Mission Description',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),

                    SwitchListTile(
                      title: const Text('Is Active?'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[900],
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Save Page Content'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
