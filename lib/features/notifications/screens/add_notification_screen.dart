import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:cloud_admin/core/config/app_config.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddNotificationScreen extends StatefulWidget {
  final Map<String, dynamic>? notificationToEdit;
  const AddNotificationScreen({super.key, this.notificationToEdit});

  @override
  State<AddNotificationScreen> createState() => _AddNotificationScreenState();
}

class _AddNotificationScreenState extends State<AddNotificationScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _titleController = TextEditingController();
  final _messageController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isActive = true;
  String _selectedType = 'info';
  String _selectedAudience = 'all';
  DateTime? _scheduledDate;

  final List<Map<String, String>> _types = [
    {'value': 'info', 'label': 'Info', 'icon': '📢'},
    {'value': 'success', 'label': 'Success', 'icon': '✅'},
    {'value': 'warning', 'label': 'Warning', 'icon': '⚠️'},
    {'value': 'error', 'label': 'Error', 'icon': '❌'},
    {'value': 'promotional', 'label': 'Promotional', 'icon': '🎉'},
  ];

  final List<Map<String, String>> _audiences = [
    {'value': 'all', 'label': 'All Users'},
    {'value': 'customers', 'label': 'Customers Only'},
    {'value': 'providers', 'label': 'Service Providers'},
  ];

  @override
  void initState() {
    super.initState();
    if (widget.notificationToEdit != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final notification = widget.notificationToEdit!;
    _titleController.text = notification['title'] ?? '';
    _messageController.text = notification['message'] ?? '';
    _selectedType = notification['type'] ?? 'info';
    _selectedAudience = notification['targetAudience'] ?? 'all';
    _isActive = notification['isActive'] == true;

    if (notification['scheduledFor'] != null) {
      _scheduledDate = DateTime.parse(notification['scheduledFor']);
    }
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _scheduledDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null && mounted) {
      final time = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_scheduledDate ?? DateTime.now()),
      );

      if (time != null && mounted) {
        setState(() {
          _scheduledDate = DateTime(
            date.year,
            date.month,
            date.day,
            time.hour,
            time.minute,
          );
        });
      }
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final baseUrl = AppConfig.apiUrl;
      final isEditing = widget.notificationToEdit != null;
      final url = isEditing
          ? '$baseUrl/notifications/${widget.notificationToEdit!['_id']}'
          : '$baseUrl/notifications';

      final body = {
        'title': _titleController.text,
        'message': _messageController.text,
        'type': _selectedType,
        'targetAudience': _selectedAudience,
        'isActive': _isActive.toString(),
        'scheduledFor': _scheduledDate?.toIso8601String(),
      };

      final response = isEditing
          ? await http.put(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            )
          : await http.post(
              Uri.parse(url),
              headers: {'Content-Type': 'application/json'},
              body: json.encode(body),
            );

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isEditing
                  ? 'Notification updated!'
                  : 'Notification created!'),
            ),
          );
          context.pop();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content:
                  Text('Failed: ${response.statusCode} - ${response.body}'),
            ),
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
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.notificationToEdit != null;

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
                  isEditing ? 'Edit Notification' : 'Create New Notification',
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
                    isEditing ? 'Edit Details' : 'Notification Details',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Divider(height: 32),

                  // Title
                  _buildTextField(
                    controller: _titleController,
                    label: 'Title',
                    hint: 'e.g. New Feature Launched!',
                  ),
                  const SizedBox(height: 24),

                  // Message
                  _buildTextField(
                    controller: _messageController,
                    label: 'Message',
                    hint: 'Enter notification message...',
                    maxLines: 4,
                  ),
                  const SizedBox(height: 24),

                  // Type Selection
                  const Text(
                    'Notification Type',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _types.map((type) {
                      final isSelected = _selectedType == type['value'];
                      return ChoiceChip(
                        label: Text('${type['icon']} ${type['label']}'),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() => _selectedType = type['value']!);
                        },
                        selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Target Audience
                  const Text(
                    'Target Audience',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _audiences.map((audience) {
                      final isSelected = _selectedAudience == audience['value'];
                      return ChoiceChip(
                        label: Text(audience['label']!),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(
                              () => _selectedAudience = audience['value']!);
                        },
                        selectedColor: const Color(0xFF8B5CF6).withOpacity(0.2),
                        backgroundColor: Colors.grey.shade100,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),

                  // Schedule DateTime
                  const Text(
                    'Schedule (Optional)',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectDateTime,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.grey.shade50,
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _scheduledDate == null
                                ? 'Send immediately'
                                : 'Send on ${_scheduledDate!.toString().substring(0, 16)}',
                            style: TextStyle(
                              color: _scheduledDate == null
                                  ? Colors.grey.shade600
                                  : Colors.black87,
                            ),
                          ),
                          const Spacer(),
                          if (_scheduledDate != null)
                            IconButton(
                              icon: const Icon(Icons.clear, size: 20),
                              onPressed: () =>
                                  setState(() => _scheduledDate = null),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Status Toggle
                  Row(
                    children: [
                      const Text(
                        'Status:',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 12),
                      Switch(
                        value: _isActive,
                        onChanged: (v) => setState(() => _isActive = v),
                        activeColor: AppTheme.successGreen,
                      ),
                      Text(_isActive ? ' Active' : ' Inactive'),
                    ],
                  ),

                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () => context.pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 16,
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
                            vertical: 16,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(isEditing
                                ? 'Update Notification'
                                : 'Create Notification'),
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
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Required';
            }
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
