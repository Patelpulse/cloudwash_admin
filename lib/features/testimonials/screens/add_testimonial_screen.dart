import 'dart:io';
import 'dart:convert';

import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_testimonial_service.dart';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class AddTestimonialScreen extends StatefulWidget {
  final Map<String, dynamic>? testimonialToEdit;
  const AddTestimonialScreen({super.key, this.testimonialToEdit});

  @override
  State<AddTestimonialScreen> createState() => _AddTestimonialScreenState();
}

class _AddTestimonialScreenState extends State<AddTestimonialScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseTestimonialService = FirebaseTestimonialService();

  // Controllers
  final _nameController = TextEditingController();
  final _designationController = TextEditingController();
  final _messageController = TextEditingController();

  // State
  bool _isActive = true;
  double _rating = 5.0;
  bool _isLoading = false;

  // Image
  XFile? _selectedImage;
  Uint8List? _webImageBytes;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    if (widget.testimonialToEdit != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final testimonial = widget.testimonialToEdit!;
    _nameController.text = testimonial['name'] ?? '';
    _designationController.text = testimonial['designation'] ?? '';
    _messageController.text = testimonial['message'] ?? '';
    _isActive = testimonial['isActive'] == true;
    _rating = (testimonial['rating'] ?? 5.0).toDouble();
    _existingImageUrl = testimonial['imageUrl'];
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
      if (widget.testimonialToEdit != null &&
          widget.testimonialToEdit!['firebaseId'] != null) {
        // Update existing in Firebase
        await _firebaseTestimonialService.updateTestimonial(
          testimonialId: widget.testimonialToEdit!['firebaseId'],
          name: _nameController.text,
          message: _messageController.text,
          imageUrl: imageUrl,
          rating: _rating,
          isActive: _isActive,
          designation: _designationController.text,
        );
      } else {
        // Create new in Firebase
        await _firebaseTestimonialService.createTestimonial(
          name: _nameController.text,
          message: _messageController.text,
          imageUrl: imageUrl ?? '',
          rating: _rating,
          isActive: _isActive,
          designation: _designationController.text,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.testimonialToEdit != null
                ? 'Testimonial updated successfully!'
                : 'Testimonial created successfully!'),
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
      final isEditing = widget.testimonialToEdit != null &&
          widget.testimonialToEdit!['_id'] != null;
      final url = isEditing
          ? '$baseUrl/testimonials/${widget.testimonialToEdit!['_id']}'
          : '$baseUrl/testimonials';

      var uri = Uri.parse(url);
      var request = http.MultipartRequest(isEditing ? 'PUT' : 'POST', uri);

      request.fields['name'] = _nameController.text;
      request.fields['designation'] = _designationController.text;
      request.fields['message'] = _messageController.text;
      request.fields['rating'] = _rating.toString();
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
            '_id': widget.testimonialToEdit?['_id'],
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
    _designationController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.testimonialToEdit != null;

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
                  isEditing ? 'Edit Testimonial' : 'Add New Testimonial',
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
                  Text(isEditing ? 'Edit Details' : 'Testimonial Details',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),

                  // Form Fields
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _nameController,
                          label: 'Customer Name',
                          hint: 'e.g. John Doe',
                        ),
                      ),
                      const SizedBox(width: 24),
                      Expanded(
                        child: _buildTextField(
                          controller: _designationController,
                          label: 'Designation',
                          hint: 'e.g. Customer / CEO',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  _buildTextField(
                    controller: _messageController,
                    label: 'Testimonial Message',
                    hint: 'Write the customer review...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Rating Slider
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Rating',
                          style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: List.generate(5, (index) {
                                    return Icon(
                                      index < _rating.floor()
                                          ? Icons.star
                                          : Icons.star_border,
                                      color: const Color(0xFFFBBF24),
                                      size: 28,
                                    );
                                  }),
                                ),
                                Text(
                                  '${_rating.toStringAsFixed(1)} / 5.0',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Slider(
                              value: _rating,
                              min: 0,
                              max: 5,
                              divisions: 10,
                              activeColor: const Color(0xFFFBBF24),
                              onChanged: (value) {
                                setState(() => _rating = value);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
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

                  const Text('Customer Photo (Optional)',
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
                                      Text('Click to upload photo',
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
                          backgroundColor: const Color(0xFFEC4899),
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
                                ? 'Update Testimonial'
                                : 'Create Testimonial'),
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
