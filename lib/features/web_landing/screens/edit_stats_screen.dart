import 'package:cloud_admin/features/web_landing/models/stats_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_admin/core/config/app_config.dart';

class EditStatsScreen extends ConsumerStatefulWidget {
  const EditStatsScreen({super.key});

  @override
  ConsumerState<EditStatsScreen> createState() => _EditStatsScreenState();
}

class _EditStatsScreenState extends ConsumerState<EditStatsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _happyClientsController;
  late TextEditingController _branchesController;
  late TextEditingController _citiesController;
  late TextEditingController _ordersController;

  bool _isLoading = false;
  bool _isActive = true;
  final String _baseUrl = AppConfig.apiUrl;

  @override
  void initState() {
    super.initState();
    _happyClientsController = TextEditingController();
    _branchesController = TextEditingController();
    _citiesController = TextEditingController();
    _ordersController = TextEditingController();
    _fetchData();
  }

  @override
  void dispose() {
    _happyClientsController.dispose();
    _branchesController.dispose();
    _citiesController.dispose();
    _ordersController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse('$_baseUrl/web-content/stats'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final stats = StatsModel.fromJson(data);

        _happyClientsController.text = stats.happyClients;
        _branchesController.text = stats.totalBranches;
        _citiesController.text = stats.totalCities;
        _ordersController.text = stats.totalOrders;

        setState(() {
          _isActive = stats.isActive;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      // Using MultipartRequest to be consistent with others, though basic PUT works too
      var request = http.MultipartRequest(
          'PUT', Uri.parse('$_baseUrl/web-content/stats'));

      request.fields['happyClients'] = _happyClientsController.text;
      request.fields['totalBranches'] = _branchesController.text;
      request.fields['totalCities'] = _citiesController.text;
      request.fields['totalOrders'] = _ordersController.text;
      request.fields['isActive'] = _isActive.toString();

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Saved Successfully')));
      } else {
        throw Exception('Failed to save');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Stats')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _happyClientsController,
                      decoration: const InputDecoration(
                        labelText: 'Happy Clients',
                        hintText: 'e.g. 500+',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _branchesController,
                      decoration: const InputDecoration(
                        labelText: 'Total Branches',
                        hintText: 'e.g. 10+',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _citiesController,
                      decoration: const InputDecoration(
                        labelText: 'Total Cities',
                        hintText: 'e.g. 5+',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _ordersController,
                      decoration: const InputDecoration(
                        labelText: 'Total Orders',
                        hintText: 'e.g. 1000+',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SwitchListTile(
                      title: const Text('Is Active?'),
                      value: _isActive,
                      onChanged: (v) => setState(() => _isActive = v),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _save,
                        child: const Text('Save Changes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
