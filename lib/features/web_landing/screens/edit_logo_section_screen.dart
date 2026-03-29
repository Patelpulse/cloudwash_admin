import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_admin/core/config/app_config.dart';
import 'package:cloud_admin/features/web_landing/models/hero_section_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';

class EditLogoSectionScreen extends ConsumerStatefulWidget {
  const EditLogoSectionScreen({super.key});

  @override
  ConsumerState<EditLogoSectionScreen> createState() =>
      _EditLogoSectionScreenState();
}

class _EditLogoSectionScreenState extends ConsumerState<EditLogoSectionScreen> {
  bool _isLoading = false;
  String? _logoUrl;
  Uint8List? _selectedLogoBytes;
  String? _selectedLogoMimeType;
  final String _baseUrl = AppConfig.apiUrl;

  @override
  void initState() {
    super.initState();
    _fetchLogo();
  }

  Future<void> _fetchLogo() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hero'));
      if (response.statusCode == 200) {
        final hero = HeroSectionModel.fromJson(jsonDecode(response.body));
        setState(() {
          _logoUrl = hero.logoUrl;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load logo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;
    final bytes = await pickedFile.readAsBytes();
    setState(() {
      _selectedLogoBytes = bytes;
      _selectedLogoMimeType = pickedFile.mimeType;
    });
  }

  Future<void> _saveLogo() async {
    if (_selectedLogoBytes == null && (_logoUrl ?? '').trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a logo first')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));
      request.fields['logoUrl'] = _logoUrl ?? '';

      if (_selectedLogoBytes != null) {
        final mimeParts = (_selectedLogoMimeType ?? 'image/png').split('/');
        final mediaType = mimeParts.length == 2
            ? MediaType(mimeParts[0], mimeParts[1])
            : MediaType('image', 'png');
        request.files.add(
          http.MultipartFile.fromBytes(
            'logo',
            _selectedLogoBytes!,
            filename: 'website_logo.png',
            contentType: mediaType,
          ),
        );
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Logo updated. Website navbar/footer will use this logo.',
            ),
          ),
        );
        _selectedLogoBytes = null;
        await _fetchLogo();
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save logo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _isLoading = true);
    try {
      final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));
      request.fields['logoUrl'] = '';

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200) {
        if (!mounted) return;
        setState(() {
          _selectedLogoBytes = null;
          _logoUrl = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo removed')),
        );
      } else {
        throw Exception('Failed with status ${response.statusCode}');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to remove logo: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasRemoteLogo = (_logoUrl ?? '').trim().isNotEmpty;
    final embeddedRemoteLogoBytes = _decodeDataImage((_logoUrl ?? '').trim());
    return Scaffold(
      appBar: AppBar(
        title: const Text('Website Logo'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _saveLogo,
            icon: const Icon(Icons.save),
            tooltip: 'Save Logo',
          ),
        ],
      ),
      body: _isLoading && _logoUrl == null && _selectedLogoBytes == null
          ? const Center(child: CircularProgressIndicator())
          : Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 720),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Upload website logo',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This logo will appear dynamically on user website navbar and footer.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 28),
                      Container(
                        width: double.infinity,
                        height: 260,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: _selectedLogoBytes != null
                            ? Image.memory(_selectedLogoBytes!,
                                fit: BoxFit.contain)
                            : hasRemoteLogo
                                ? (embeddedRemoteLogoBytes != null
                                    ? Image.memory(
                                        embeddedRemoteLogoBytes,
                                        fit: BoxFit.contain,
                                      )
                                    : Image.network(_logoUrl!,
                                        fit: BoxFit.contain))
                                : const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.image_outlined,
                                        size: 54,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 12),
                                      Text(
                                        'No logo uploaded yet',
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          ElevatedButton.icon(
                            onPressed: _isLoading ? null : _pickLogo,
                            icon: const Icon(Icons.upload_file),
                            label: const Text('Choose Logo'),
                          ),
                          const SizedBox(width: 12),
                          OutlinedButton.icon(
                            onPressed: _isLoading ? null : _saveLogo,
                            icon: const Icon(Icons.save),
                            label: const Text('Save'),
                          ),
                          const SizedBox(width: 12),
                          TextButton.icon(
                            onPressed: _isLoading ? null : _removeLogo,
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Remove Logo'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  Uint8List? _decodeDataImage(String imageUrl) {
    if (!imageUrl.startsWith('data:image')) return null;
    final commaIndex = imageUrl.indexOf(',');
    if (commaIndex == -1 || commaIndex >= imageUrl.length - 1) return null;
    try {
      return base64Decode(imageUrl.substring(commaIndex + 1));
    } catch (_) {
      return null;
    }
  }
}
