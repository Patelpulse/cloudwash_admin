import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_admin/core/config/app_config.dart';
import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http_parser/http_parser.dart';

class GeneralSettingsScreen extends StatefulWidget {
  const GeneralSettingsScreen({super.key});

  @override
  State<GeneralSettingsScreen> createState() => _GeneralSettingsScreenState();
}

class _GeneralSettingsScreenState extends State<GeneralSettingsScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // Controllers
  final _siteNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _twitterController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  String? _logoUrl;
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoName;

  @override
  void initState() {
    super.initState();
    _fetchSettings();
  }

  Future<void> _fetchSettings() async {
    setState(() => _isLoading = true);
    try {
      final baseUrl = AppConfig.apiUrl;
      final response = await http.get(Uri.parse('$baseUrl/settings'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _siteNameController.text = data['siteName'] ?? '';
        _emailController.text = data['contactEmail'] ?? '';
        _phoneController.text = data['contactPhone'] ?? '';
        _addressController.text = data['address'] ?? '';
        _logoUrl = data['logoUrl'];
        
        if (data['socialLinks'] != null) {
          _facebookController.text = data['socialLinks']['facebook'] ?? '';
          _instagramController.text = data['socialLinks']['instagram'] ?? '';
          _twitterController.text = data['socialLinks']['twitter'] ?? '';
        }
      }
    } catch (e) {
      debugPrint('Error fetching settings: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedLogoBytes = bytes;
        _selectedLogoName = image.name;
      });
    }
  }

  Future<void> _saveSettings() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      final baseUrl = AppConfig.apiUrl;
      
      // Get token for auth
      final prefs = await SharedPreferences.getInstance();
      final adminDataStr = prefs.getString('admin_data');
      String? token;
      if (adminDataStr != null) {
        final adminData = json.decode(adminDataStr);
        token = adminData['token'];
      }

      final uri = Uri.parse('$baseUrl/settings');
      final request = http.MultipartRequest('PUT', uri);
      
      // Headers
      request.headers['Authorization'] = 'Bearer ${token ?? ''}';
      
      // Fields
      request.fields['siteName'] = _siteNameController.text;
      request.fields['contactEmail'] = _emailController.text;
      request.fields['contactPhone'] = _phoneController.text;
      request.fields['address'] = _addressController.text;
      request.fields['socialLinks'] = json.encode({
        'facebook': _facebookController.text,
        'instagram': _instagramController.text,
        'twitter': _twitterController.text,
      });

      // Logo File
      if (_selectedLogoBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'logo',
          _selectedLogoBytes!,
          filename: _selectedLogoName ?? 'logo.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Settings updated successfully!')),
          );
          _fetchSettings(); // Refresh to get new logo URL
          setState(() {
            _selectedLogoBytes = null;
            _selectedLogoName = null;
          });
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update: ${response.statusCode}')),
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Branding & General Settings',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left side: Logo and Basic Info
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildLogoCard(),
                      const SizedBox(height: 24),
                      _buildContactCard(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                // Right side: Social and More
                Expanded(
                  flex: 1,
                  child: Column(
                    children: [
                      _buildSocialCard(),
                      const SizedBox(height: 40),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _saveSettings,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primaryBlue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: _isSaving
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text('Save All Settings', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogoCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text('Website Logo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Text('This logo will appear on your user website and booking app.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const Divider(height: 32),
          Center(
            child: Column(
              children: [
                Container(
                  height: 120,
                  width: 240,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: _selectedLogoBytes != null
                      ? Image.memory(_selectedLogoBytes!, fit: BoxFit.contain)
                      : (_logoUrl != null && _logoUrl!.isNotEmpty
                          ? Image.network(_logoUrl!, fit: BoxFit.contain)
                          : const Icon(Icons.image_outlined, size: 48, color: Colors.grey)),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _pickLogo,
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Change Logo'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildTextField(
            controller: _siteNameController,
            label: 'Site Name',
            hint: 'e.g. CloudWash',
          ),
        ],
      ),
    );
  }

  Widget _buildContactCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text('Contact Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _buildTextField(controller: _emailController, label: 'Public Email', hint: 'info@cloudwash.com'),
          const SizedBox(height: 16),
          _buildTextField(controller: _phoneController, label: 'Public Phone', hint: '+91 9876543210'),
          const SizedBox(height: 16),
          _buildTextField(controller: _addressController, label: 'Office Address', hint: 'Enter full address...', maxLines: 3),
        ],
      ),
    );
  }

  Widget _buildSocialCard() {
    return Container(
      padding: const EdgeInsets.all(24),
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
          const Text('Social Media Links', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(height: 32),
          _buildTextField(
            controller: _facebookController,
            label: 'Facebook URL',
            hint: 'https://facebook.com/yourpage',
            icon: Icons.facebook,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _instagramController,
            label: 'Instagram URL',
            hint: 'https://instagram.com/yourprofile',
            icon: Icons.camera_alt_outlined,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _twitterController,
            label: 'Twitter URL',
            hint: 'https://twitter.com/yourhandle',
            icon: Icons.alternate_email,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: Colors.grey.shade300)),
            filled: true,
            fillColor: Colors.grey.shade50,
          ),
        ),
      ],
    );
  }
}
