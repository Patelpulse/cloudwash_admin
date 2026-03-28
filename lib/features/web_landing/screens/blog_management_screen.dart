import 'package:cloud_admin/features/web_landing/models/blog_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_admin/core/config/app_config.dart';

class BlogManagementScreen extends ConsumerStatefulWidget {
  const BlogManagementScreen({super.key});

  @override
  ConsumerState<BlogManagementScreen> createState() =>
      _BlogManagementScreenState();
}

class _BlogManagementScreenState extends ConsumerState<BlogManagementScreen> {
  final String _baseUrl = AppConfig.apiUrl;
  List<BlogModel> _blogs = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fetchBlogs();
  }

  Future<void> _fetchBlogs() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/blogs'));
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        setState(() {
          _blogs = data.map((e) => BlogModel.fromJson(e)).toList();
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteBlog(String id) async {
    if (!await _showDeleteConfirmation()) return;

    try {
      final response = await http.delete(Uri.parse('$_baseUrl/blogs/$id'));
      if (response.statusCode == 200) {
        _fetchBlogs();
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
            title: const Text('Delete Blog?'),
            content: const Text('Are you sure you want to delete this blog post?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Cancel')),
              TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
  }

  void _showAddEditDialog([BlogModel? blog]) {
    showDialog(
      context: context,
      builder: (context) => _BlogDialog(
        baseUrl: _baseUrl,
        existingBlog: blog,
        onSave: _fetchBlogs,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Blogs')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _blogs.isEmpty
              ? const Center(child: Text('No blogs found. Add your first post!'))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _blogs.length,
                  itemBuilder: (context, index) {
                    final item = _blogs[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            image: item.image.isNotEmpty
                                ? DecorationImage(
                                    image: NetworkImage(item.image),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                            color: Colors.grey.shade200,
                          ),
                          child: item.image.isEmpty
                                ? const Icon(Icons.image, color: Colors.grey)
                                : null,
                        ),
                        title: Text(item.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('By: ${item.author}', style: const TextStyle(fontSize: 12)),
                            const SizedBox(height: 4),
                            Text(item.description,
                                maxLines: 2, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => _showAddEditDialog(item)),
                            IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _deleteBlog(item.id)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _BlogDialog extends StatefulWidget {
  final String baseUrl;
  final BlogModel? existingBlog;
  final VoidCallback onSave;

  const _BlogDialog({
    required this.baseUrl,
    this.existingBlog,
    required this.onSave,
  });

  @override
  State<_BlogDialog> createState() => _BlogDialogState();
}

class _BlogDialogState extends State<_BlogDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _authorController;
  late TextEditingController _descriptionController;
  Uint8List? _selectedImageBytes;
  bool _isActive = true;
  String? _imageUrl;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController =
        TextEditingController(text: widget.existingBlog?.title ?? '');
    _authorController =
        TextEditingController(text: widget.existingBlog?.author ?? 'Admin');
    _descriptionController =
        TextEditingController(text: widget.existingBlog?.description ?? '');
    _isActive = widget.existingBlog?.isActive ?? true;
    _imageUrl = widget.existingBlog?.image;
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() {
        _selectedImageBytes = bytes;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final isEdit = widget.existingBlog != null;
      var request = http.MultipartRequest(
        isEdit ? 'PUT' : 'POST',
        Uri.parse(isEdit
            ? '${widget.baseUrl}/blogs/${widget.existingBlog!.id}'
            : '${widget.baseUrl}/blogs'),
      );

      request.fields['title'] = _titleController.text;
      request.fields['author'] = _authorController.text;
      request.fields['description'] = _descriptionController.text;
      request.fields['isActive'] = _isActive.toString();

      if (_selectedImageBytes != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          _selectedImageBytes!,
          filename: 'blog_post.png',
          contentType: MediaType('image', 'png'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        widget.onSave();
        if (mounted) Navigator.pop(context);
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.existingBlog == null ? 'Create Blog Post' : 'Edit Blog Post'),
      content: SizedBox(
        width: 600,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 180,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                      image: _selectedImageBytes != null
                          ? DecorationImage(image: MemoryImage(_selectedImageBytes!), fit: BoxFit.cover)
                          : (_imageUrl != null && _imageUrl!.isNotEmpty)
                              ? DecorationImage(image: NetworkImage(_imageUrl!), fit: BoxFit.cover)
                              : null,
                    ),
                    child: (_selectedImageBytes == null && (_imageUrl == null || _imageUrl!.isEmpty))
                        ? const Icon(Icons.add_a_photo, size: 40, color: Colors.grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Blog Title', border: OutlineInputBorder()),
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _authorController,
                  decoration: const InputDecoration(labelText: 'Author Name', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Content / Description', border: OutlineInputBorder()),
                  maxLines: 8,
                  validator: (v) => v!.isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                SwitchListTile(
                  title: const Text('Is Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        ElevatedButton(
            onPressed: _isLoading ? null : _save,
            child: _isLoading ? const CircularProgressIndicator() : const Text('Save Post')),
      ],
    );
  }
}
