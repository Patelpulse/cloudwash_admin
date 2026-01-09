import 'package:cloud_admin/core/services/firebase_city_service.dart';
import 'package:cloud_admin/features/cities/widgets/city_table_row.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CitiesScreen extends StatefulWidget {
  const CitiesScreen({super.key});

  @override
  State<CitiesScreen> createState() => _CitiesScreenState();
}

class _CitiesScreenState extends State<CitiesScreen> {
  final _firebaseCityService = FirebaseCityService();

  Future<void> _deleteCity(String firebaseId, String? mongoId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: const Text('Are you sure you want to delete this city?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _firebaseCityService.deleteCity(firebaseId);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('City deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
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
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Countries & States',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.cloud_done,
                            size: 16, color: Colors.green.shade700),
                        const SizedBox(width: 6),
                        Text(
                          'Firebase',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.green.shade700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  ElevatedButton.icon(
                    onPressed: () async {
                      await context.push('/cities/add');
                    },
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: const Text('Add Country',
                        style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildCitiesStream(),
        ],
      ),
    );
  }

  Widget _buildCitiesStream() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _firebaseCityService.getCities(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40.0),
              child: CircularProgressIndicator(),
            ),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => setState(() {}),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
        }

        final cities = snapshot.data ?? [];

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              _buildTableHeader(),
              if (cities.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Column(
                    children: [
                      Icon(Icons.location_city_outlined,
                          size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No cities found',
                        style: TextStyle(
                            fontSize: 18, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              else
                ...cities.map((city) {
                  return CityTableRow(
                    name: city['name'] ?? 'No Name',
                    state: city['state'] ?? '',
                    isActive: city['isActive'] == true,
                    onEdit: () async {
                      final editData = {
                        ...city,
                        'firebaseId': city['id'],
                      };
                      await context.push('/cities/add', extra: editData);
                    },
                    onDelete: () => _deleteCity(city['id'], city['mongoId']),
                  );
                }).toList(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTableHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          _buildHeaderItem('COUNTRY NAME', 2),
          _buildHeaderItem('STATE', 2),
          _buildHeaderItem('STATUS', 1),
          _buildHeaderItem('ACTIONS', 1),
        ],
      ),
    );
  }

  Widget _buildHeaderItem(String label, int flex) {
    return Expanded(
      flex: flex,
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.grey,
        ),
      ),
    );
  }
}
