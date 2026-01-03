import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class AddAddonScreen extends StatefulWidget {
  final Map<String, dynamic>? addonToEdit;
  const AddAddonScreen({super.key, this.addonToEdit});

  @override
  State<AddAddonScreen> createState() => _AddAddonScreenState();
}

class _AddAddonScreenState extends State<AddAddonScreen> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();

  // Controllers
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isActive = true;
  List<String> _categories = ['Uncategorized'];
  final TextEditingController _newCategoryController = TextEditingController();
  File? _selectedImage;
  Uint8List? _webImageBytes;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.addonToEdit != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final addon = widget.addonToEdit!;
    _nameController.text = addon['name'] ?? '';
    _descriptionController.text = addon['description'] ?? '';
    _priceController.text = addon['price']?.toString() ?? '';
    _durationController.text = addon['duration'] ?? '';

    // Handle categories - can be array or single string
    if (addon['category'] != null) {
      if (addon['category'] is List) {
        _categories = List<String>.from(addon['category']);
      } else {
        _categories = [addon['category'].toString()];
      }
    }

    _isActive = addon['isActive'] == true;
    _existingImageUrl = addon['imageUrl'];
  }

  void _addCategory() {
    if (_newCategoryController.text.trim().isNotEmpty) {
      setState(() {
        _categories.add(_newCategoryController.text.trim());
        _newCategoryController.clear();
      });
    }
  }

  void _removeCategory(int index) {
    setState(() {
      if (_categories.length > 1) {
        _categories.removeAt(index);
      }
    });
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          final bytes = await pickedFile.readAsBytes();
          setState(() {
            _webImageBytes = bytes;
            _selectedImage = null;
          });
        } else {
          setState(() {
            _selectedImage = File(pickedFile.path);
            _webImageBytes = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
      final isEditing = widget.addonToEdit != null;
      final url = isEditing
          ? '$baseUrl/addons/${widget.addonToEdit!['_id']}'
          : '$baseUrl/addons';

      var request = http.MultipartRequest(
        isEditing ? 'PUT' : 'POST',
        Uri.parse(url),
      );

      request.fields['name'] = _nameController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['price'] = _priceController.text;
      request.fields['duration'] = _durationController.text;
      request.fields['category'] = jsonEncode(_categories);
      request.fields['isActive'] = _isActive.toString();

      // Add image if selected
      if (kIsWeb && _webImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _webImageBytes!,
          filename: 'addon_image.jpg',
        ));
      } else if (!kIsWeb && _selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          _selectedImage!.path,
        ));
      } else if (!isEditing) {
        // Image is required for new addon
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please select an image')),
          );
        }
        setState(() => _isLoading = false);
        return;
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(isEditing ? 'Addon updated!' : 'Addon created!')),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Failed: ${response.statusCode} - ${responseBody}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.addonToEdit != null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => context.pop(),
                  icon: const Icon(Icons.arrow_back),
                ),
                const SizedBox(width: 8),
                Text(
                  isEditing ? 'Edit Add-on' : 'Create New Add-on',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isEditing ? 'Edit Details' : 'Add-on Details',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),

                  // Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'Add-on Name',
                    hint: 'e.g. Smart Curtain Setup - 1200',
                  ),
                  const SizedBox(height: 24),

                  // Description
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Brief description of the add-on',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _priceController,
                          label: 'Price (₹)',
                          hint: 'e.g. 1200',
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _durationController,
                          label: 'Duration',
                          hint: 'e.g. 30 min',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Categories
                  _buildCategoriesSection(),
                  const SizedBox(height: 24),

                  // Status Toggle
                  Row(
                    children: [
                      const Text('Status:',
                          style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      Switch(
                          value: _isActive,
                          onChanged: (v) => setState(() => _isActive = v),
                          activeColor: AppTheme.successGreen),
                      Text(_isActive ? ' Active' : ' Inactive'),
                    ],
                  ),

                  const SizedBox(height: 32),
                  const Divider(),
                  const SizedBox(height: 16),

                  // Image Upload
                  const Text('Add-on Image',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: _buildImagePreview(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text('Click to upload image',
                      style:
                          TextStyle(fontSize: 12, color: Colors.grey.shade600)),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 16),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFEA8C00),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2))
                            : Text(
                                isEditing ? 'Update Add-on' : 'Create Add-on'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (_webImageBytes != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(_webImageBytes!, fit: BoxFit.cover),
      );
    } else if (_selectedImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.file(_selectedImage!, fit: BoxFit.cover),
      );
    } else if (_existingImageUrl != null && _existingImageUrl!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 8),
          Text('Upload Add-on Image',
              style: TextStyle(color: Colors.grey.shade600)),
        ],
      );
    }
  }

  Widget _buildCategoriesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Categories',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            Text(
              '${_categories.length} added',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Display existing categories as chips
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _categories.asMap().entries.map((entry) {
            final index = entry.key;
            final category = entry.value;
            return Chip(
              label: Text(category),
              deleteIcon: const Icon(Icons.close, size: 18),
              onDeleted:
                  _categories.length > 1 ? () => _removeCategory(index) : null,
              backgroundColor: const Color(0xFFEA8C00).withOpacity(0.1),
              labelStyle: const TextStyle(color: Color(0xFFEA8C00)),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Add new category input
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _newCategoryController,
                decoration: InputDecoration(
                  hintText: 'Add a category...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                onSubmitted: (_) => _addCategory(),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton.icon(
              onPressed: _addCategory,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFEA8C00),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    bool required = true,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: (value) {
            if (required && (value == null || value.isEmpty)) {
              return 'Required';
            }
            return null;
          },
          decoration: InputDecoration(
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
