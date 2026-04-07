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
  static const String _phoneKey = 'phone';
  static const String _tabletKey = 'tablet';
  static const String _websiteKey = 'website';
  static const List<String> _deviceOrder = [
    _phoneKey,
    _tabletKey,
    _websiteKey,
  ];

  bool _isLoading = false;
  String? _logoUrl;
  Map<String, String> _logoByDevice = {
    _phoneKey: '',
    _tabletKey: '',
    _websiteKey: '',
  };
  String _selectedDeviceType = _websiteKey;
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
      final apiLogos = _normalizeLogoByDevice(apiData?['logoByDevice']);
      final firestoreLogos = _normalizeLogoByDevice(
        firestoreData?['logoByDevice'],
      );
      final mergedLogos = <String, String>{...apiLogos, ...firestoreLogos};

      final apiWebsiteLogo = (apiData?['logoUrl'] ?? '').toString().trim();
      if (apiWebsiteLogo.isNotEmpty &&
          (mergedLogos[_websiteKey] ?? '').isEmpty) {
        mergedLogos[_websiteKey] = apiWebsiteLogo;
      }
      final firestoreWebsiteLogo =
          (firestoreData?['logoUrl'] ?? '').toString().trim();
      if (firestoreWebsiteLogo.isNotEmpty) {
        mergedLogos[_websiteKey] = firestoreWebsiteLogo;
      }

      if (!mounted) return;
      setState(() {
        _logoByDevice = _withAllDeviceKeys(mergedLogos);
        _logoUrl = (_logoByDevice[_selectedDeviceType] ?? '').trim();
        final rawHeight =
            firestoreData?['logoHeight'] ?? apiData?['logoHeight'];
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
      final previousLogo =
          (_logoByDevice[_selectedDeviceType] ?? '').toString().trim();
      String? selectedLogoDataUrl;
      bool apiSucceeded = false;
      if (_selectedLogoBytes != null) {
        selectedLogoDataUrl = _buildDataUrl(
          _selectedLogoBytes!,
          _selectedLogoMimeType,
        );

        final responseAsFile = await _saveLogoAsFile();
        if (responseAsFile.statusCode == 200) {
          apiSucceeded = true;
          final logoFromApi = _extractLogoFromResponse(responseAsFile.body);
          if ((logoFromApi ?? '').trim().isNotEmpty) {
            selectedLogoDataUrl = logoFromApi;
          }
        } else {
          final responseAsDataUrl = await _saveLogoAsDataUrl();
          apiSucceeded = responseAsDataUrl.statusCode == 200;
          if (apiSucceeded) {
            final logoFromApi =
                _extractLogoFromResponse(responseAsDataUrl.body);
            if ((logoFromApi ?? '').trim().isNotEmpty) {
              selectedLogoDataUrl = logoFromApi;
            }
          }
        }
      } else if (previousLogo.isNotEmpty) {
        final response = await _saveHeightOnlyToApi(previousLogo);
        apiSucceeded = response.statusCode == 200;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Please choose a ${_deviceLabel(_selectedDeviceType).toLowerCase()} logo to upload first',
            ),
          ),
        );
        return;
      }

      final firestoreUpdated = await _saveLogoToFirestore(
        deviceType: _selectedDeviceType,
        logoUrl: selectedLogoDataUrl ?? previousLogo,
      );

      if (apiSucceeded || firestoreUpdated) {
        if (!mounted) return;
        setState(() {
          _selectedLogoBytes = null;
          _selectedLogoMimeType = null;
          _logoUrl = (_logoByDevice[_selectedDeviceType] ?? '').trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              firestoreUpdated
                  ? '${_deviceLabel(_selectedDeviceType)} logo updated.'
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
    request.fields['logoDeviceType'] = _selectedDeviceType;
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
    request.fields['logoDeviceType'] = _selectedDeviceType;
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
    request.fields['logoDeviceType'] = _selectedDeviceType;
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
        request.fields['logoDeviceType'] = _selectedDeviceType;
        request.fields['logoUrl'] = '';
        request.fields['logoHeight'] = _logoHeight.toStringAsFixed(0);

        final streamedResponse = await request.send();
        final response = await http.Response.fromStream(streamedResponse);
        apiUpdated = response.statusCode == 200;
      } catch (_) {}

      final firestoreUpdated = await _saveLogoToFirestore(
        deviceType: _selectedDeviceType,
        logoUrl: '',
      );

      if (apiUpdated || firestoreUpdated) {
        if (!mounted) return;
        setState(() {
          _selectedLogoBytes = null;
          _selectedLogoMimeType = null;
          _logoUrl = (_logoByDevice[_selectedDeviceType] ?? '').trim();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_deviceLabel(_selectedDeviceType)} logo removed'),
          ),
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
                        'Upload logo by device type',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Selected ${_deviceLabel(_selectedDeviceType)} logo will appear dynamically on user app/web for that device type.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      DropdownButtonFormField<String>(
                        value: _selectedDeviceType,
                        decoration: InputDecoration(
                          labelText: 'Device Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: _deviceOrder
                            .map(
                              (device) => DropdownMenuItem(
                                value: device,
                                child: Text(_deviceLabel(device)),
                              ),
                            )
                            .toList(),
                        onChanged: _isLoading
                            ? null
                            : (value) {
                                if (value != null) {
                                  _onDeviceTypeChanged(value);
                                }
                              },
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
                            label: Text(
                              'Choose ${_deviceLabel(_selectedDeviceType)} Logo',
                            ),
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
                            label: Text(
                              'Remove ${_deviceLabel(_selectedDeviceType)} Logo',
                            ),
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
      final byDevice = _withAllDeviceKeys(hero.logoByDevice);
      if (logo.isNotEmpty && (byDevice[_websiteKey] ?? '').isEmpty) {
        byDevice[_websiteKey] = logo;
      }
      return {
        'logoUrl': logo.isEmpty ? null : logo,
        'logoByDevice': byDevice,
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
      final byDevice = _normalizeLogoByDevice(data['logoByDevice']);
      if (logo.isNotEmpty && (byDevice[_websiteKey] ?? '').isEmpty) {
        byDevice[_websiteKey] = logo;
      }
      final heightRaw = data['logoHeight'] ?? data['logo_height'];
      double? parsedHeight;
      if (heightRaw is num) parsedHeight = heightRaw.toDouble();
      parsedHeight ??= double.tryParse('$heightRaw');
      return {
        'logoUrl': logo.isEmpty ? null : logo,
        'logoByDevice': byDevice,
        'logoHeight': parsedHeight,
      };
    } catch (_) {
      return null;
    }
  }

  Future<bool> _saveLogoToFirestore({
    required String deviceType,
    required String logoUrl,
  }) async {
    try {
      final nextLogos = Map<String, String>.from(_logoByDevice);
      nextLogos[deviceType] = logoUrl.trim();
      final websiteLogo = (nextLogos[_websiteKey] ?? '').trim();
      await FirebaseFirestore.instance
          .collection('web_landing')
          .doc('hero')
          .set(
        {
          'logoByDevice': _withAllDeviceKeys(nextLogos),
          'logoUrl': websiteLogo,
          'logoHeight': _logoHeight,
          'updatedAt': DateTime.now().toUtc().toIso8601String(),
        },
        SetOptions(merge: true),
      );
      _logoByDevice = _withAllDeviceKeys(nextLogos);
      return true;
    } catch (_) {
      return false;
    }
  }

  void _onDeviceTypeChanged(String deviceType) {
    setState(() {
      _selectedDeviceType = deviceType;
      _selectedLogoBytes = null;
      _selectedLogoMimeType = null;
      _logoUrl = (_logoByDevice[deviceType] ?? '').trim();
    });
  }

  String _deviceLabel(String key) {
    switch (key) {
      case _phoneKey:
        return 'Phone';
      case _tabletKey:
        return 'Tablet';
      case _websiteKey:
        return 'Website';
      default:
        return key;
    }
  }

  Map<String, String> _normalizeLogoByDevice(dynamic value) {
    if (value is! Map) return _withAllDeviceKeys({});
    final normalized = <String, String>{};
    for (final entry in value.entries) {
      final rawKey = entry.key.toString().trim().toLowerCase();
      final rawValue = entry.value?.toString().trim() ?? '';
      if (rawValue.isEmpty) continue;
      final key = switch (rawKey) {
        'phone' || 'mobile' => _phoneKey,
        'tablet' || 'tab' => _tabletKey,
        'website' || 'web' || 'desktop' => _websiteKey,
        _ => '',
      };
      if (key.isNotEmpty) {
        normalized[key] = rawValue;
      }
    }
    return _withAllDeviceKeys(normalized);
  }

  Map<String, String> _withAllDeviceKeys(Map<String, String> source) {
    return {
      _phoneKey: (source[_phoneKey] ?? '').trim(),
      _tabletKey: (source[_tabletKey] ?? '').trim(),
      _websiteKey: (source[_websiteKey] ?? '').trim(),
    };
  }

  String _buildDataUrl(Uint8List bytes, String? mimeType) {
    final resolvedMimeType = mimeType ?? 'image/png';
    return 'data:$resolvedMimeType;base64,${base64Encode(bytes)}';
  }

  String? _extractLogoFromResponse(String body) {
    try {
      final parsed = jsonDecode(body);
      if (parsed is Map<String, dynamic>) {
        final logos = _normalizeLogoByDevice(parsed['logoByDevice']);
        final selectedLogo = (logos[_selectedDeviceType] ?? '').trim();
        final height = parsed['logoHeight'];
        if (height is num) {
          _logoHeight = height.toDouble().clamp(60, 240);
        }
        if (selectedLogo.isNotEmpty) return selectedLogo;

        final logo = parsed['logoUrl'];
        if (logo is String) return logo;
      }
    } catch (_) {}
    return null;
  }
}
