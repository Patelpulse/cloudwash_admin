import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class EditFooterScreen extends StatefulWidget {
  const EditFooterScreen({super.key});

  @override
  State<EditFooterScreen> createState() => _EditFooterScreenState();
}

class _EditFooterScreenState extends State<EditFooterScreen> {
  final _descriptionController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  final _copyrightController = TextEditingController();
  final _facebookController = TextEditingController();
  final _instagramController = TextEditingController();
  final _mailController = TextEditingController();

  final List<Map<String, String>> _exploreLinks = [];
  final List<Map<String, String>> _serviceLinks = [];
  final List<Map<String, String>> _policyLinks = [];
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFooter();
  }

  Future<void> _loadFooter() async {
    setState(() => _isLoading = true);
    try {
      final doc = await FirebaseFirestore.instance
          .collection('web_landing')
          .doc('footer')
          .get();
      final data = doc.data() ?? {};

      _descriptionController.text = data['description'] ?? '';
      _phoneController.text = data['phone'] ?? '';
      _emailController.text = data['email'] ?? '';
      _addressController.text = data['address'] ?? '';
      _copyrightController.text = data['copyright'] ??
          '© ${DateTime.now().year} Cloud Wash. Crafted with precision.';
      final social = (data['socialLinks'] as Map<String, dynamic>?) ?? {};
      _facebookController.text = social['facebook']?.toString() ?? '';
      _instagramController.text = social['instagram']?.toString() ?? '';
      _mailController.text =
          social['email']?.toString() ?? social['mail']?.toString() ?? '';

      final explore = (data['exploreLinks'] as List?) ?? [];
      final services = (data['serviceLinks'] as List?) ?? [];
      final policies = (data['policyLinks'] as List?) ??
          [
            {'label': 'Privacy Policy', 'route': '/privacy'},
            {'label': 'Terms of Service', 'route': '/terms'},
            {'label': 'Child Protection', 'route': '/child-protection'},
            {'label': 'Sitemap', 'route': '/'},
          ];
      _exploreLinks
        ..clear()
        ..addAll(explore.map((e) => {
              'label': e['label']?.toString() ?? '',
              'route': e['route']?.toString() ?? '/',
            }));
      _serviceLinks
        ..clear()
        ..addAll(services.map((e) => {
              'label': e['label']?.toString() ?? '',
              'route': e['route']?.toString() ?? '/',
            }));
      _policyLinks
        ..clear()
        ..addAll(policies.map((e) => {
              'label': e['label']?.toString() ?? '',
              'route': e['route']?.toString() ?? '/',
            }));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    try {
      await FirebaseFirestore.instance
          .collection('web_landing')
          .doc('footer')
          .set({
        'description': _descriptionController.text,
        'phone': _phoneController.text,
        'email': _emailController.text,
        'address': _addressController.text,
        'copyright': _copyrightController.text,
        'socialLinks': {
          'facebook': _facebookController.text.trim(),
          'instagram': _instagramController.text.trim(),
          'email': _mailController.text.trim(),
          'mail': _mailController.text.trim(),
        },
        'exploreLinks': _exploreLinks,
        'serviceLinks': _serviceLinks,
        'policyLinks': _policyLinks,
        'updatedAt': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Footer saved')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _copyrightController.dispose();
    _facebookController.dispose();
    _instagramController.dispose();
    _mailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Footer'),
        actions: [
          TextButton.icon(
            onPressed: _isSaving ? null : _save,
            icon: const Icon(Icons.save, color: Colors.white),
            label: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    controller: _descriptionController,
                    label: 'Brand blurb',
                    hint:
                        'Redefining premium garment care with technology and craftsmanship...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                          child: _buildTextField(
                        controller: _phoneController,
                        label: 'Phone',
                        hint: '+91 98765 43210',
                      )),
                      const SizedBox(width: 16),
                      Expanded(
                          child: _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'hello@cloudwash.com',
                      )),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _addressController,
                    label: 'Address',
                    hint: 'Suite 402, Laundry Lane, Bangalore, KA 560001',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _copyrightController,
                    label: 'Copyright line',
                    hint: '© 2026 Cloud Wash. Crafted with precision.',
                  ),
                  const SizedBox(height: 16),
                  const Text('Social Links',
                      style:
                          TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _facebookController,
                          label: 'Facebook URL',
                          hint: 'https://facebook.com/cloudwash',
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildTextField(
                          controller: _instagramController,
                          label: 'Instagram URL',
                          hint: 'https://instagram.com/cloudwash',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _mailController,
                    label: 'Support Email (for icon link)',
                    hint: 'hello@cloudwash.com',
                  ),
                  const SizedBox(height: 24),
                  _LinksEditor(
                    title: 'Explore Links',
                    items: _exploreLinks,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  _LinksEditor(
                    title: 'Services Links',
                    items: _serviceLinks,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),
                  _LinksEditor(
                    title: 'Bottom Policy Links',
                    items: _policyLinks,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _save,
                      icon: const Icon(Icons.save),
                      label: _isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Save footer'),
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
                fontWeight: FontWeight.w600,
                color: Colors.black87)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
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

class _LinksEditor extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final VoidCallback onChanged;

  const _LinksEditor(
      {required this.title, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                TextButton.icon(
                  onPressed: () {
                    items.add({'label': 'New link', 'route': '/'});
                    onChanged();
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No links added yet',
                  style: TextStyle(color: Colors.grey)),
            for (int i = 0; i < items.length; i++) ...[
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      initialValue: items[i]['label'],
                      decoration: const InputDecoration(labelText: 'Label'),
                      onChanged: (v) => items[i]['label'] = v,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      initialValue: items[i]['route'],
                      decoration: const InputDecoration(labelText: 'Route/URL'),
                      onChanged: (v) => items[i]['route'] = v,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () {
                      items.removeAt(i);
                      onChanged();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ]
          ],
        ),
      ),
    );
  }
}
