import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/core/services/firebase_city_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AddCityScreen extends StatefulWidget {
  final Map<String, dynamic>? cityToEdit;
  const AddCityScreen({super.key, this.cityToEdit});

  @override
  State<AddCityScreen> createState() => _AddCityScreenState();
}

class _AddCityScreenState extends State<AddCityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firebaseCityService = FirebaseCityService();

  // Controllers
  final _nameController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController();

  // State
  bool _isLoading = false;
  bool _isActive = true;

  @override
  void initState() {
    super.initState();
    if (widget.cityToEdit != null) {
      _initializeEditMode();
    }
  }

  void _initializeEditMode() {
    final c = widget.cityToEdit!;
    _nameController.text = c['name'] ?? '';
    _stateController.text = c['state'] ?? '';
    _countryController.text = c['country'] ?? 'India';
    _isActive = c['isActive'] == true;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Save to Firebase Firestore
      if (widget.cityToEdit != null &&
          widget.cityToEdit!['firebaseId'] != null) {
        // Update existing in Firebase
        await _firebaseCityService.updateCity(
          cityId: widget.cityToEdit!['firebaseId'],
          name: _nameController.text,
          state: _stateController.text,
          country: _countryController.text,
          isActive: _isActive,
        );
      } else {
        // Create new in Firebase
        await _firebaseCityService.createCity(
          name: _nameController.text,
          state: _stateController.text,
          country: _countryController.text,
          isActive: _isActive,
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.cityToEdit != null
                ? 'City updated successfully!'
                : 'City created successfully!'),
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

  @override
  void dispose() {
    _nameController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.cityToEdit != null;

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
                  isEditing ? 'Edit City' : 'Add New City',
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
                  Text(isEditing ? 'Edit Details' : 'City Details',
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(height: 32),

                  // City Name
                  _buildTextField(
                    controller: _nameController,
                    label: 'City Name',
                    hint: 'e.g. Lucknow',
                  ),
                  const SizedBox(height: 24),

                  // State
                  _buildTextField(
                    controller: _stateController,
                    label: 'State',
                    hint: 'e.g. Uttar Pradesh',
                  ),
                  const SizedBox(height: 24),

                  // Country
                  _buildTextField(
                    controller: _countryController,
                    label: 'Country',
                    hint: 'e.g. India',
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
                          backgroundColor: const Color(0xFF3B82F6),
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
                            : Text(isEditing ? 'Update City' : 'Create City'),
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
