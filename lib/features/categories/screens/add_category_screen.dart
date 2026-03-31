import 'dart:io';
import 'dart:convert';
import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_category_service.dart';
import 'package:cloud_admin/core/utils/image_data_utils.dart';
import 'package:flutter/foundation.dart'; // For kIsWeb
import 'package:flutter/material.dart';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AddCategoryScreen extends StatefulWidget {
  final Map<String, dynamic>? categoryToEdit;

  const AddCategoryScreen({super.key, this.categoryToEdit});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _displayOrderController = TextEditingController();
  bool _isActive = true;
  XFile? _selectedImage;
  String? _existingImageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.categoryToEdit != null) {
      final cat = widget.categoryToEdit!;
      _nameController.text = cat['name'] ?? '';
      _priceController.text = cat['price']?.toString() ?? '';
      _descriptionController.text = cat['description'] ?? '';
      _isActive = cat['isActive'] == true;
      _existingImageUrl = cat['imageUrl'];
      if (cat['displayOrder'] != null) {
        _displayOrderController.text = cat['displayOrder'].toString();
      }
    }
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = image;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    // Validation: Image is required for new categories
    if (widget.categoryToEdit == null && _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final firebaseService = FirebaseCategoryService();
      final existingMongoId = _currentMongoId;
      final parsedDisplayOrder =
          int.tryParse(_displayOrderController.text.trim());

      String? imageUrl = _existingImageUrl;
      String? mongoId = existingMongoId;
      final failureReasons = <String>[];

      // Sync to backend only when we have a backend ID (for edit) or this is a new category.
      // Some legacy Firebase docs don't have mongoId/_id, and calling /categories/null fails.
      final canSyncBackend =
          widget.categoryToEdit == null || existingMongoId != null;

      if (canSyncBackend) {
        final backendResult = await _saveToBackend();
        final backendImageUrl = backendResult?['imageUrl']?.toString();
        final backendMongoId = backendResult?['_id']?.toString();
        final backendError = backendResult?['error']?.toString();

        if (backendImageUrl != null && backendImageUrl.isNotEmpty) {
          imageUrl = backendImageUrl;
        }

        if (backendMongoId != null &&
            backendMongoId.isNotEmpty &&
            backendMongoId != 'null') {
          mongoId = backendMongoId;
        }

        if (backendError != null && backendError.isNotEmpty) {
          failureReasons.add('Backend: $backendError');
        }
      } else {
        debugPrint(
          'Skipping backend sync for category update: mongoId is missing.',
        );
      }

      // Fallback 1: direct Cloudinary upload (works even when backend sync fails).
      if (_selectedImage != null && (imageUrl == null || imageUrl.isEmpty)) {
        imageUrl = await _uploadImageToCloudinary();
        if (imageUrl == null || imageUrl.isEmpty) {
          failureReasons.add('Cloudinary (admin upload) failed');
        }
      }

      // Fallback 2: legacy Firebase Storage upload.
      if (_selectedImage != null && (imageUrl == null || imageUrl.isEmpty)) {
        imageUrl = await _uploadImageToFirebaseStorage(firebaseService);
        if (imageUrl == null || imageUrl.isEmpty) {
          failureReasons.add('Firebase Storage upload failed');
        }
      }

      // Fallback 3: inline data URL (keeps category creation working when all
      // external image hosts are unavailable).
      if (_selectedImage != null && (imageUrl == null || imageUrl.isEmpty)) {
        imageUrl = await _buildInlineDataImageUrl();
        if (imageUrl == null || imageUrl.isEmpty) {
          failureReasons.add(
              'Inline image fallback failed (use image smaller than 750 KB)');
        }
      }

      if (widget.categoryToEdit == null &&
          (imageUrl == null || imageUrl.isEmpty)) {
        throw Exception(
          'Image upload failed. ${failureReasons.join(' | ')}',
        );
      }

      if (widget.categoryToEdit != null &&
          widget.categoryToEdit!['firebaseId'] != null) {
        // Update existing in Firebase
        await firebaseService.updateCategory(
          categoryId: widget.categoryToEdit!['firebaseId'],
          name: _nameController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          description: _descriptionController.text,
          imageUrl: imageUrl,
          isActive: _isActive,
          mongoId: mongoId,
          displayOrder: parsedDisplayOrder,
        );
      } else {
        // Create new in Firebase
        await firebaseService.createCategory(
          name: _nameController.text,
          price: double.tryParse(_priceController.text) ?? 0,
          description: _descriptionController.text,
          imageUrl: imageUrl ?? '',
          isActive: _isActive,
          mongoId: mongoId,
          displayOrder: parsedDisplayOrder,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.categoryToEdit != null
                ? 'Category updated successfully!'
                : 'Category created successfully!'),
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

  String? get _currentMongoId {
    final rawId =
        widget.categoryToEdit?['_id'] ?? widget.categoryToEdit?['mongoId'];
    if (rawId == null) return null;
    final value = rawId.toString().trim();
    if (value.isEmpty || value.toLowerCase() == 'null') return null;
    return value;
  }

  String _resolveMimeType(XFile file) {
    final pickedMimeType = file.mimeType;
    if (pickedMimeType != null && pickedMimeType.startsWith('image/')) {
      return pickedMimeType;
    }

    final lowerPath = file.path.toLowerCase();
    if (lowerPath.endsWith('.png')) return 'image/png';
    if (lowerPath.endsWith('.webp')) return 'image/webp';
    if (lowerPath.endsWith('.gif')) return 'image/gif';
    if (lowerPath.endsWith('.bmp')) return 'image/bmp';
    if (lowerPath.endsWith('.svg')) return 'image/svg+xml';
    return 'image/jpeg';
  }

  String _resolveFileExtension(XFile file) {
    final mimeType = _resolveMimeType(file);
    if (mimeType == 'image/png') return 'png';
    if (mimeType == 'image/webp') return 'webp';
    if (mimeType == 'image/gif') return 'gif';
    if (mimeType == 'image/bmp') return 'bmp';
    if (mimeType == 'image/svg+xml') return 'svg';
    return 'jpg';
  }

  Future<String?> _uploadImageToFirebaseStorage(
    FirebaseCategoryService firebaseService,
  ) async {
    if (_selectedImage == null) return null;
    try {
      final bytes = await _selectedImage!.readAsBytes();
      final mimeType = _resolveMimeType(_selectedImage!);
      final fileName =
          'category_${DateTime.now().millisecondsSinceEpoch}.${_resolveFileExtension(_selectedImage!)}';
      return await firebaseService.uploadCategoryImage(
        bytes,
        fileName,
        contentType: mimeType,
      );
    } catch (e) {
      debugPrint('Firebase image upload fallback failed: $e');
      return null;
    }
  }

  Future<String?> _buildInlineDataImageUrl() async {
    if (_selectedImage == null) return null;
    try {
      final bytes = await _selectedImage!.readAsBytes();
      const maxInlineBytes = 750 * 1024;
      if (bytes.length > maxInlineBytes) {
        debugPrint(
          'Inline data URL fallback skipped: image is larger than 750 KB.',
        );
        return null;
      }
      final mimeType = _resolveMimeType(_selectedImage!);
      return 'data:$mimeType;base64,${base64Encode(bytes)}';
    } catch (e) {
      debugPrint('Inline data URL fallback failed: $e');
      return null;
    }
  }

  Future<String?> _uploadImageToCloudinary() async {
    if (_selectedImage == null) return null;

    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']?.trim();
    final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET']?.trim();

    if (cloudName == null ||
        cloudName.isEmpty ||
        uploadPreset == null ||
        uploadPreset.isEmpty) {
      debugPrint(
        'Cloudinary upload skipped: CLOUDINARY_CLOUD_NAME or CLOUDINARY_UPLOAD_PRESET missing.',
      );
      return null;
    }

    try {
      final uri =
          Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');
      final request = http.MultipartRequest('POST', uri)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'cloud_wash_categories';

      final mimeType = _resolveMimeType(_selectedImage!);

      if (kIsWeb) {
        final bytes = await _selectedImage!.readAsBytes();
        request.files.add(
          http.MultipartFile.fromBytes(
            'file',
            bytes,
            filename: _selectedImage!.name,
            contentType: MediaType.parse(mimeType),
          ),
        );
      } else {
        request.files.add(
          await http.MultipartFile.fromPath(
            'file',
            _selectedImage!.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final parsed = json.decode(responseBody) as Map<String, dynamic>;
        final secureUrl = parsed['secure_url']?.toString();
        if (secureUrl != null && secureUrl.isNotEmpty) return secureUrl;
      } else {
        debugPrint(
          'Cloudinary upload failed with status ${response.statusCode}: $responseBody',
        );
      }
    } catch (e) {
      debugPrint('Cloudinary upload fallback failed: $e');
    }

    return null;
  }

  // Save to backend and return response data
  Future<Map<String, dynamic>?> _saveToBackend() async {
    try {
      final baseUrl = AppConfig.apiUrl;
      final mongoId = _currentMongoId;
      final isEditing = widget.categoryToEdit != null && mongoId != null;

      if (widget.categoryToEdit != null && !isEditing) {
        // Legacy Firebase docs may not have backend mongo ID.
        // Skip backend PUT instead of sending /categories/null.
        return null;
      }

      final url =
          isEditing ? '$baseUrl/categories/$mongoId' : '$baseUrl/categories';

      var uri = Uri.parse(url);
      var request = http.MultipartRequest(isEditing ? 'PUT' : 'POST', uri);

      request.fields['name'] = _nameController.text;
      request.fields['price'] = _priceController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['isActive'] = _isActive.toString();
      if (_displayOrderController.text.trim().isNotEmpty) {
        request.fields['displayOrder'] = _displayOrderController.text.trim();
      }

      // Add image file if selected
      if (_selectedImage != null) {
        final mimeType = _resolveMimeType(_selectedImage!);

        if (kIsWeb) {
          var bytes = await _selectedImage!.readAsBytes();
          var multipartFile = http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: _selectedImage!.name,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);
        } else {
          var multipartFile = await http.MultipartFile.fromPath(
            'image',
            _selectedImage!.path,
            contentType: MediaType.parse(mimeType),
          );
          request.files.add(multipartFile);
        }
      }

      var response = await request.send();

      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseBody = await response.stream.bytesToString();
        // Parse JSON response to get imageUrl and _id
        try {
          final jsonResponse =
              json.decode(responseBody) as Map<String, dynamic>;
          return {
            'imageUrl': jsonResponse['imageUrl'],
            '_id': jsonResponse['_id'],
          };
        } catch (e) {
          debugPrint('Category backend response parse error: $e');
          return {
            'imageUrl': _existingImageUrl,
            '_id': mongoId,
          };
        }
      } else {
        final errorBody = await response.stream.bytesToString();
        String parsedError = errorBody;
        try {
          final parsed = json.decode(errorBody) as Map<String, dynamic>;
          final message = parsed['message']?.toString().trim();
          final detail = parsed['error']?.toString().trim();
          parsedError = [message, detail]
              .where((part) => part != null && part.isNotEmpty)
              .cast<String>()
              .join(' - ');
          if (parsedError.isEmpty) {
            parsedError = errorBody;
          }
        } catch (_) {}

        debugPrint(
          'Category backend save failed with status ${response.statusCode}: $parsedError',
        );
        return {
          'error':
              'status ${response.statusCode}${parsedError.isNotEmpty ? ': $parsedError' : ''}',
        };
      }
    } catch (e) {
      debugPrint('Category backend save error: $e');
      return {
        'error': e.toString(),
      };
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    _displayOrderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final embeddedExistingImageBytes = decodeDataImage(_existingImageUrl);
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
                  widget.categoryToEdit != null
                      ? 'Edit Main Category'
                      : 'Add Main Category',
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
                  Text(
                      widget.categoryToEdit != null
                          ? 'Edit Details'
                          : 'Category Details',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),

                  // Form Fields
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                        controller: _nameController,
                        label: 'Category Name',
                        hint: 'e.g. Smart Home',
                      )),
                      const SizedBox(width: 24),
                      Expanded(
                          child: _buildTextField(
                        controller: _priceController,
                        label: 'Starting Price (₹)',
                        hint: 'e.g. 999',
                        isNumeric: true,
                      )),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _displayOrderController,
                    label: 'Display Order (smaller = higher)',
                    hint: 'e.g. 10',
                    isNumeric: true,
                    requiredField: false,
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Description',
                    hint: 'Short description of the category...',
                    maxLines: 3,
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
                        activeThumbColor: AppTheme.successGreen,
                      ),
                      Text(_isActive ? ' Active' : ' Inactive'),
                    ],
                  ),
                  const SizedBox(height: 24),

                  const Text('Category Icon/Image',
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
                                  ? Image.network(
                                      _selectedImage!.path,
                                      fit: BoxFit.cover,
                                    )
                                  : Image.file(
                                      File(_selectedImage!.path),
                                      fit: BoxFit.cover,
                                    ),
                            )
                          : (_existingImageUrl != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: embeddedExistingImageBytes != null
                                      ? Image.memory(
                                          embeddedExistingImageBytes,
                                          fit: BoxFit.cover,
                                        )
                                      : Image.network(
                                          _existingImageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (
                                            context,
                                            error,
                                            stackTrace,
                                          ) =>
                                              const Center(
                                            child: Icon(Icons.broken_image),
                                          ),
                                        ),
                                )
                              : Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.cloud_upload_outlined,
                                          size: 40,
                                          color: AppTheme.primaryBlue),
                                      const SizedBox(height: 8),
                                      Text('Click to upload category icon',
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
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2),
                              )
                            : Text(widget.categoryToEdit != null
                                ? 'Update Category'
                                : 'Create Category'),
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
    bool requiredField = true,
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
            if (!requiredField) return null;
            if (value == null || value.isEmpty) return 'Please enter $label';
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
