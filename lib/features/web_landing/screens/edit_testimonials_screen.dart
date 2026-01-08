import 'package:cloud_admin/features/web_landing/models/testimonial_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_admin/core/config/app_config.dart';

class EditTestimonialsScreen extends ConsumerStatefulWidget {
  const EditTestimonialsScreen({super.key});

  @override
  ConsumerState<EditTestimonialsScreen> createState() =>
      _EditTestimonialsScreenState();
}

class _EditTestimonialsScreenState
    extends ConsumerState<EditTestimonialsScreen> {
  final String _baseUrl = AppConfig.apiUrl;
  List<TestimonialModel> _testimonials = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchTestimonials();
  }

  Future<void> _fetchTestimonials() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/testimonials'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _testimonials =
              data.map((e) => TestimonialModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteTestimonial(String id) async {
    if (!await _showDeleteConfirmation()) return;

    try {
      final response =
          await http.delete(Uri.parse('$_baseUrl/testimonials/$id'));
      if (response.statusCode == 200) {
        _fetchTestimonials();
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<bool> _showDeleteConfirmation() async {
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Delete Testimonial?'),
            content:
                const Text('Are you sure you want to delete this testimonial?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  void _showAddEditDialog([TestimonialModel? testimonial]) {
    showDialog(
      context: context,
      builder: (context) => _TestimonialDialog(
        baseUrl: _baseUrl,
        existingTestimonial: testimonial,
        onSave: _fetchTestimonials,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Testimonials')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _testimonials.length,
              itemBuilder: (context, index) {
                final item = _testimonials[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: item.imageUrl.isNotEmpty
                          ? NetworkImage(item.imageUrl)
                          : null,
                      child: item.imageUrl.isEmpty
                          ? Text(item.name[0].toUpperCase())
                          : null,
                    ),
                    title: Text(item.name),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.role),
                        Text('Rating: ${item.rating} ⭐'),
                        Text(item.message,
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _showAddEditDialog(item)),
                        IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _deleteTestimonial(item.id)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _TestimonialDialog extends StatefulWidget {
  final String baseUrl;
  final TestimonialModel? existingTestimonial;
  final VoidCallback onSave;

  const _TestimonialDialog({
    required this.baseUrl,
    this.existingTestimonial,
    required this.onSave,
  });

  @override
  State<_TestimonialDialog> createState() => _TestimonialDialogState();
}

class _TestimonialDialogState extends State<_TestimonialDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _roleController;
  late TextEditingController _messageController;
  late TextEditingController _ratingController;
  Uint8List? _selectedImageBytes;
  bool _isActive = true;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController =
        TextEditingController(text: widget.existingTestimonial?.name ?? '');
    _roleController =
        TextEditingController(text: widget.existingTestimonial?.role ?? '');
    _messageController =
        TextEditingController(text: widget.existingTestimonial?.message ?? '');
    _ratingController = TextEditingController(
        text: (widget.existingTestimonial?.rating ?? 5).toString());
    _isActive = widget.existingTestimonial?.isActive ?? true;
    _imageUrl = widget.existingTestimonial?.imageUrl;
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
      final isEdit = widget.existingTestimonial != null;
      var request = http.MultipartRequest(
        isEdit ? 'PUT' : 'POST',
        Uri.parse(isEdit
            ? '${widget.baseUrl}/testimonials/${widget.existingTestimonial!.id}'
            : '${widget.baseUrl}/testimonials'),
      );

      request.fields['name'] = _nameController.text;
      request.fields['role'] = _roleController.text;
      request.fields['message'] = _messageController.text;
      request.fields['rating'] = _ratingController.text;
      request.fields['isActive'] = _isActive.toString();

      if (_selectedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: 'testimonial.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSave();
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingTestimonial == null
          ? 'Add Testimonial'
          : 'Edit Testimonial'),
      content: SizedBox(
        width: 500,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey.shade200,
                    backgroundImage: _selectedImageBytes != null
                        ? MemoryImage(_selectedImageBytes!)
                        : (_imageUrl != null && _imageUrl!.isNotEmpty)
                            ? NetworkImage(_imageUrl!) as ImageProvider
                            : null,
                    child: (_selectedImageBytes == null &&
                            (_imageUrl == null || _imageUrl!.isEmpty))
                        ? const Icon(Icons.add_a_photo, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _roleController,
                  decoration: const InputDecoration(labelText: 'Role'),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _messageController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _ratingController,
                  decoration: const InputDecoration(labelText: 'Rating (1-5)'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator())
                : const Text('Save')),
      ],
    );
  }
}
