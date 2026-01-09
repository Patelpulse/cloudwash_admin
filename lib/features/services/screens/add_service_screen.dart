import 'dart:convert';
import 'dart:io';

import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_service_service.dart';
import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:cloud_admin/core/services/firebase_subcategory_service.dart';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AddServiceScreen extends StatefulWidget {
  final Map<String, dynamic>? serviceToEdit;
  const AddServiceScreen({super.key, this.serviceToEdit});

  @override
  State<AddServiceScreen> createState() => _AddServiceScreenState();
}

class _AddServiceScreenState extends State<AddServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseServiceService = FirebaseServiceService();
  final _firebaseCategoryService = FirebaseCategoryService();
  final _firebaseSubCategoryService = FirebaseSubCategoryService();

  // Controllers
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _durationController = TextEditingController();
  final _descriptionController = TextEditingController();

  // State
  String? _selectedCategoryId;
  String? _selectedSubCategoryId;
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _subCategories = [];
  List<Map<String, dynamic>> _filteredSubCategories = [];
  bool _isLoading = false;
  bool _isActive = true;

  // Image
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
    _fetchSubCategories();
    if (widget.serviceToEdit != null) {
      _initializeEditMode();
    }
  }

  void _fetchCategories() {
    _firebaseCategoryService.getCategories().listen((categories) {
      if (mounted) {
        setState(() {
          _categories = categories;
          if (widget.serviceToEdit == null &&
              _selectedCategoryId == null &&
              _categories.isNotEmpty) {
            _selectedCategoryId = _categories[0]['id'];
            _updateFilteredSubCategories();
          }
        });
      }
    });
  }

  void _fetchSubCategories() {
    _firebaseSubCategoryService.getSubCategories().listen((subCategories) {
      if (mounted) {
        setState(() {
          _subCategories = subCategories;
          _updateFilteredSubCategories();
        });
      }
    });
  }

  void _updateFilteredSubCategories() {
    setState(() {
      _filteredSubCategories = _subCategories
          .where((sub) => sub['categoryId'] == _selectedCategoryId)
          .toList();

      if (_filteredSubCategories.isNotEmpty) {
        // Only reset if current selection is not in filtered list
        if (!_filteredSubCategories
            .any((s) => s['id'] == _selectedSubCategoryId)) {
          _selectedSubCategoryId = _filteredSubCategories[0]['id'];
        }
      } else {
        _selectedSubCategoryId = null;
      }
    });
  }

  void _initializeEditMode() {
    final s = widget.serviceToEdit!;
    _nameController.text = s['name'] ?? '';
    _priceController.text = s['price']?.toString() ?? '';
    _durationController.text = s['duration']?.toString() ?? '';
    _descriptionController.text = s['description'] ?? '';
    _isActive = s['isActive'] == true;
    _existingImageUrl = s['imageUrl'];

    _selectedCategoryId = s['categoryId'];
    _selectedSubCategoryId = s['subCategoryId'];
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        setState(() {
          _selectedImage = image;
          _webImageBytes = bytes;
        });
      } else {
        setState(() {
          _selectedImage = image;
          _webImageBytes = null;
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      String? imageUrl = _existingImageUrl;

      // Try to upload image to backend/Cloudinary if selected
      if (_selectedImage != null) {
        try {
          final backendResult = await _saveToBackend();
          if (backendResult != null && backendResult['imageUrl'] != null) {
            imageUrl = backendResult['imageUrl'];
          }
        } catch (e) {
          debugPrint('Backend upload failed: $e');
          // Continue without image - save to Firebase anyway
        }
      }

      // Save to Firebase Firestore
      if (widget.serviceToEdit != null &&
          widget.serviceToEdit!['firebaseId'] != null) {
        // Update existing in Firebase
        await _firebaseServiceService.updateService(
          serviceId: widget.serviceToEdit!['firebaseId'],
          name: _nameController.text,
          subCategoryId: _selectedSubCategoryId ?? '',
          categoryId: _selectedCategoryId!,
          price: double.tryParse(_priceController.text) ?? 0,
          description: _descriptionController.text,
          imageUrl: imageUrl,
          isActive: _isActive,
          unit: 'piece',
        );
      } else {
        // Create new in Firebase
        await _firebaseServiceService.createService(
          name: _nameController.text,
          subCategoryId: _selectedSubCategoryId ?? '',
          categoryId: _selectedCategoryId!,
          price: double.tryParse(_priceController.text) ?? 0,
          description: _descriptionController.text,
          imageUrl: imageUrl ?? '',
          isActive: _isActive,
          unit: 'piece',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.serviceToEdit != null
                ? 'Service updated successfully!'
                : 'Service created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<Map<String, dynamic>?> _saveToBackend() async {
    try {
      final baseUrl = AppConfig.apiUrl;
      final isEditing =
          widget.serviceToEdit != null && widget.serviceToEdit!['_id'] != null;
      final url = isEditing
          ? '$baseUrl/services/${widget.serviceToEdit!['_id']}'
          : '$baseUrl/services';

      var uri = Uri.parse(url);
      var request = http.MultipartRequest(isEditing ? 'PUT' : 'POST', uri);

      request.fields['name'] = _nameController.text;
      request.fields['category'] = _selectedCategoryId!;
      if (_selectedSubCategoryId != null) {
        request.fields['subCategory'] = _selectedSubCategoryId!;
      }
      request.fields['price'] = _priceController.text;
      request.fields['duration'] = _durationController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['isActive'] = _isActive.toString();

      if (_selectedImage != null) {
        String mimeType = 'image/jpeg';
        if (_selectedImage!.path.endsWith('.png')) mimeType = 'image/png';

        if (kIsWeb && _webImageBytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'image',
            _webImageBytes!,
            filename: _selectedImage!.name,
            contentType: MediaType.parse(mimeType),
          ));
        } else {
          request.files.add(await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
            contentType: MediaType.parse(mimeType),
          ));
        }
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        try {
          final jsonResponse = json.decode(responseBody);
          return {
            'imageUrl': jsonResponse['imageUrl'],
            '_id': jsonResponse['_id'],
          };
        } catch (e) {
          return {
            'imageUrl': _existingImageUrl,
            '_id': widget.serviceToEdit?['_id'],
          };
        }
      }
      return null;
    } catch (e) {
      debugPrint('Backend save error: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _durationController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.serviceToEdit != null;

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
                  isEditing ? 'Edit Service' : 'Add New Service',
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
                  Text(isEditing ? 'Edit Details' : 'Service Details',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),

                  // Form Fields
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                        controller: _nameController,
                        label: 'Service Name',
                        hint: 'e.g. Sofa Cleaning',
                      )),
                      const SizedBox(width: 24),
                      Expanded(
                          child: _buildTextField(
                        controller: _priceController,
                        label: 'Price (₹)',
                        hint: 'e.g. 499',
                        isNumeric: true,
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Category',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87)),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _categories.any((cat) =>
                                          cat['id'] == _selectedCategoryId)
                                      ? _selectedCategoryId
                                      : null,
                                  hint: const Text('Select Category'),
                                  isExpanded: true,
                                  items: _categories.map((cat) {
                                    return DropdownMenuItem<String>(
                                      value: cat['id'],
                                      child: Text(cat['name']),
                                    );
                                  }).toList(),
                                  onChanged: (v) {
                                    setState(() {
                                      _selectedCategoryId = v;
                                      _updateFilteredSubCategories();
                                    });
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Sub Category',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black87)),
                            const SizedBox(height: 8),
                            Container(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: _filteredSubCategories.any((sub) =>
                                          sub['id'] == _selectedSubCategoryId)
                                      ? _selectedSubCategoryId
                                      : null,
                                  hint: const Text('Select Sub Category'),
                                  isExpanded: true,
                                  items: _filteredSubCategories.map((sub) {
                                    return DropdownMenuItem<String>(
                                      value: sub['id'],
                                      child: Text(sub['name']),
                                    );
                                  }).toList(),
                                  onChanged: (v) => setState(
                                      () => _selectedSubCategoryId = v),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                        controller: _durationController,
                        label: 'Duration (mins)',
                        hint: 'e.g. 60',
                        isNumeric: true,
                      )),
                      const SizedBox(width: 24),
                      const Spacer(),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Detailed description of the service...',
                    maxLines: 4,
                  ),
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
                          activeTrackColor: AppTheme.successGreen),
                      Text(_isActive ? ' Active' : ' Inactive'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Service Image',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        border: Border.all(
                            color: Colors.grey.shade300,
                            style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: _selectedImage != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: kIsWeb
                                  ? (_webImageBytes != null
                                      ? Image.memory(_webImageBytes!,
                                          fit: BoxFit.cover)
                                      : const Center(
                                          child: CircularProgressIndicator()))
                                  : Image.file(File(_selectedImage!.path),
                                      fit: BoxFit.cover),
                            )
                          : (_existingImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _existingImageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        const Center(
                                            child: Icon(Icons.broken_image)),
                                  ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.cloud_upload_outlined,
                                          size: 40,
                                          color: AppTheme.primaryBlue),
                                      const SizedBox(height: 8),
                                      Text('Click to upload main image',
                                          style: TextStyle(
                                              color: Colors.grey.shade600)),
                                    ],
                                  ),
                                )),
                    ),
                  ),

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
                          backgroundColor: AppTheme.primaryBlue,
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
                            : Text(isEditing
                                ? 'Update Service'
                                : 'Create Service'),
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

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool isNumeric = false,
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
          keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
          validator: (value) {
            if (value == null || value.isEmpty) return 'Required';
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
