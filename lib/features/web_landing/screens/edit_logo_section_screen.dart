import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_admin/core/config/app_config.dart';
import 'package:cloud_admin/features/web_landing/models/hero_section_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  double _logoHeight = 140;
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
      final apiData = await _fetchLogoFromApi();
      final firestoreData = await _fetchLogoFromFirestore();

      final resolvedLogo = (firestoreData?['logoUrl'] ?? '').toString().trim().isNotEmpty
          ? firestoreData
          : apiData;

      if (!mounted) return;
      setState(() {
        _logoUrl = (resolvedLogo?['logoUrl'] ?? '').toString().trim();
        final rawHeight = resolvedLogo?['logoHeight'];
        final parsedHeight = rawHeight is num
            ? rawHeight.toDouble()
            : double.tryParse('${rawHeight ?? ''}');
        _logoHeight = (parsedHeight ?? _logoHeight).clamp(60, 240);
      });
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
    setState(() => _isLoading = true);
    try {
      final previousLogo = (_logoUrl ?? '').trim();
      String? selectedLogoDataUrl;

      http.Response? response;
      if (_selectedLogoBytes != null) {
        selectedLogoDataUrl = _buildDataUrl(
          _selectedLogoBytes!,
          _selectedLogoMimeType,
        );

        response = await _saveLogoAsFile();
        if (response.statusCode != 200) {
          response = await _saveLogoAsDataUrl();
        }
      } else if (previousLogo.isNotEmpty) {
        response = await _saveHeightOnlyToApi(previousLogo);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please choose a logo to upload first')),
        );
        return;
      }

      final apiLogoFromResponse = (response?.statusCode == 200)
          ? _extractLogoFromResponse(response!.body)
          : null;
      final apiSucceeded = (response?.statusCode == 200);

      final firestoreUpdated = await _saveLogoToFirestore(
          selectedLogoDataUrl ?? previousLogo);

      if (apiSucceeded || firestoreUpdated) {
        if (!mounted) return;
        setState(() {
          _selectedLogoBytes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firestoreUpdated
                  ? 'Logo updated. Website navbar/footer will use this logo.'
                  : 'Logo updated via API.',
            ),
          ),
        );
        await _fetchLogo();
      } else {
        throw Exception('Logo update was not persisted on backend/firestore');
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

  Future<http.Response> _saveLogoAsFile() async {
    final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));
    final mimeParts = (_selectedLogoMimeType ?? 'image/png').split('/');
    final mediaType = mimeParts.length == 2
        ? MediaType(mimeParts[0], mimeParts[1])
        : MediaType('image', 'png');
    request.fields['logoHeight'] = _logoHeight.toStringAsFixed(0);
    request.files.add(
      http.MultipartFile.fromBytes(
        'logo',
        _selectedLogoBytes!,
        filename: 'website_logo.png',
        contentType: mediaType,
      ),
    );

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> _saveLogoAsDataUrl() async {
    final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));
    request.fields['logoUrl'] = _buildDataUrl(
      _selectedLogoBytes!,
      _selectedLogoMimeType,
    );
    request.fields['logoHeight'] = _logoHeight.toStringAsFixed(0);

    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<http.Response> _saveHeightOnlyToApi(String logoUrl) async {
    final request = http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));
    request.fields['logoUrl'] = logoUrl;
    request.fields['logoHeight'] = _logoHeight.toStringAsFixed(0);
    final streamedResponse = await request.send();
    return http.Response.fromStream(streamedResponse);
  }

  Future<void> _removeLogo() async {
    setState(() => _isLoading = true);
    try {
      var apiUpdated = false;
      try {
        final request =
            http.MultipartRequest('PUT', Uri.parse('$_baseUrl/hero'));
        request.fields['logoUrl'] = '';
        request.fields['logoHeight'] = '140';

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        apiUpdated = response.statusCode == 200;
      } catch (_) {}

      final firestoreUpdated = await _saveLogoToFirestore('');

      if (apiUpdated || firestoreUpdated) {
        if (!mounted) return;
        setState(() {
          _selectedLogoBytes = null;
          _logoUrl = '';
          _logoHeight = 140;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Logo removed')),
        );
      } else {
        throw Exception('Failed to remove logo from backend and firestore');
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
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text(
                            'Logo max height',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          Text('${_logoHeight.round()} px',
                              style: const TextStyle(color: Colors.grey)),
                        ],
                      ),
                      Slider(
                        min: 60,
                        max: 240,
                        divisions: 18,
                        value: _logoHeight,
                        label: '${_logoHeight.round()} px',
                        onChanged: _isLoading
                            ? null
                            : (v) => setState(() => _logoHeight = v),
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

  Future<Map<String, dynamic>?> _fetchLogoFromApi() async {
    try {
      final response = await http.get(Uri.parse('$_baseUrl/hero'));
      if (response.statusCode != 200) return null;
      final hero = HeroSectionModel.fromJson(jsonDecode(response.body));
      final logo = hero.logoUrl.trim();
      final height = hero.logoHeight ?? 140;
      return {
        'logoUrl': logo.isEmpty ? null : logo,
        'logoHeight': height,
      };
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _fetchLogoFromFirestore() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('web_landing')
          .doc('hero')
          .get();
      final data = doc.data();
      if (data == null) return null;
      final logo = (data['logoUrl'] ?? '').toString().trim();
      final heightRaw = data['logoHeight'] ?? data['logo_height'];
      double? parsedHeight;
      if (heightRaw is num) parsedHeight = heightRaw.toDouble();
      parsedHeight ??= double.tryParse('$heightRaw');
      return {
        'logoUrl': logo.isEmpty ? null : logo,
        'logoHeight': parsedHeight,
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> _saveLogoToFirestore(String logoUrl) async {
    try {
      await FirebaseFirestore.instance
          .collection('web_landing')
          .doc('hero')
          .set(
        {
          'logoUrl': logoUrl,
          'logoHeight': _logoHeight,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  String _buildDataUrl(Uint8List bytes, String? mimeType) {
    final resolvedMimeType = mimeType ?? 'image/png';
    return 'data:$resolvedMimeType;base64,${base64Encode(bytes)}';
  }

  String? _extractLogoFromResponse(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final logo = parsed['logoUrl'];
        if (logo is String) {
          final height = parsed['logoHeight'];
          if (height is num) {
            _logoHeight = height.toDouble().clamp(60, 240);
          }
          return logo;
        }
      }
    } catch (_) {}
    return null;
  }
}
