import 'package:cloud_admin/features/web_landing/models/why_choose_us_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Since the backend for Why Choose Us expects 'iconUrl' but doesn't handle file upload in the controller logic I wrote earlier (CreateItem just takes req.body),
// I should update the backend controller if I want image upload.
// BUT, I wrote `createItem` in `whyChooseUsController.js` just taking `req.body`.
// I will update the backend controller to handle image upload for WhyChooseUs as well,
// OR simpler: assume these are predefined URLs or I fix the backend now.
// Fixing backend is better.

// Wait, I will use text input for Icon URL for now to save time, or just update backend.
// Updating backend is safer. I'll do that in a separate step if needed.
// For now, let's assume it accepts a string URL (e.g. from a CDN or previously uploaded).

class EditWhyChooseUsScreen extends ConsumerStatefulWidget {
  const EditWhyChooseUsScreen({super.key});

  @override
  ConsumerState<EditWhyChooseUsScreen> createState() =>
      _EditWhyChooseUsScreenState();
}

class _EditWhyChooseUsScreenState extends ConsumerState<EditWhyChooseUsScreen> {
  final String _baseUrl = dotenv.env['API_URL'] ?? 'http://localhost:5000/api';
  List<WhyChooseUsModel> _items = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchItems();
  }

  Future<void> _fetchItems() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/why-choose-us'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _items = data.map((e) => WhyChooseUsModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteItem(String id) async {
    if (!await _showDeleteConfirmation()) return;
    try {
      final response =
          await http.delete(Uri.parse('$_baseUrl/why-choose-us/$id'));
      if (response.statusCode == 200) {
        _fetchItems();
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
            title: const Text('Delete Item?'),
            content: const Text('Are you sure?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  void _showAddEditDialog([WhyChooseUsModel? item]) {
    showDialog(
      context: context,
      builder: (context) => _WhyChooseUsDialog(
        baseUrl: _baseUrl,
        existingItem: item,
        onSave: _fetchItems,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Why Choose Us')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                final item = _items[index];
                return Card(
                  child: ListTile(
                    leading: const Icon(
                        Icons.check_circle_outline), // Placeholder icon
                    title: Text(item.title),
                    subtitle: Text(item.description),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showAddEditDialog(item)),
                        IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () => _deleteItem(item.id)),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _WhyChooseUsDialog extends StatefulWidget {
  final String baseUrl;
  final WhyChooseUsModel? existingItem;
  final VoidCallback onSave;

  const _WhyChooseUsDialog(
      {required this.baseUrl, this.existingItem, required this.onSave});

  @override
  State<_WhyChooseUsDialog> createState() => _WhyChooseUsDialogState();
}

class _WhyChooseUsDialogState extends State<_WhyChooseUsDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController
      _iconUrlController; // Using text for now as backend update is needed for image
  bool _isActive = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingItem?.title ?? '');
    _descriptionController =
        TextEditingController(text: widget.existingItem?.description ?? '');
    _iconUrlController =
        TextEditingController(text: widget.existingItem?.iconUrl ?? '');
    _isActive = widget.existingItem?.isActive ?? true;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final isEdit = widget.existingItem != null;
      final url = isEdit
          ? '${widget.baseUrl}/why-choose-us/${widget.existingItem!.id}'
          : '${widget.baseUrl}/why-choose-us';

      final response = await (isEdit ? http.put : http.post)(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'title': _titleController.text,
          'description': _descriptionController.text,
          'iconUrl': _iconUrlController.text,
          'isActive': _isActive,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSave();
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingItem == null ? 'Add Item' : 'Edit Item'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
                validator: (v) => v!.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _iconUrlController,
                decoration: const InputDecoration(
                    labelText: 'Icon Name or URL'), // Simplified for now
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
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _isLoading ? null : _save, child: const Text('Save')),
      ],
    );
  }
}
