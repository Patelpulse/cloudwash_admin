import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:cloud_admin/features/users/widgets/user_list_item.dart';
import 'package:cloud_admin/features/users/widgets/user_stats_card.dart';
import 'package:flutter/material.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildStatsRow(context),
          const SizedBox(height: 32),
          _buildSearchBar(),
          const SizedBox(height: 32),
          const Text(
            'All Users (4)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          UserListItem(
            name: 'New User',
            email: 'No Email',
            phone: '9967853364',
            status: 'Active',
            joinedDate: 'Joined 12/15/2025',
            onDelete: () {},
          ),
          UserListItem(
            name: 'Patel',
            email: 'rohit@gmail.com',
            phone: '9411800280',
            status: 'Active',
            joinedDate: 'Joined 11/22/2025',
            onDelete: () {},
          ),
          UserListItem(
            name: 'Yogesh Thakur',
            email: 'yogesh@gmail.com', // Placeholder
            phone: '9876543210', // Placeholder
            status: 'Active',
            joinedDate: 'Joined 10/10/2025',
            onDelete: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        int crossAxisCount = 3;
        if (width < 800) crossAxisCount = 1;

        if (crossAxisCount == 1) {
          return Column(
            children: const [
              UserStatsCard(
                label: 'Total Users',
                value: '4',
                icon: Icons.people,
                color: Colors.indigo,
              ),
              SizedBox(height: 16),
              UserStatsCard(
                label: 'Active',
                value: '4',
                icon: Icons.check_circle,
                color: AppTheme.successGreen,
              ),
              SizedBox(height: 16),
              UserStatsCard(
                label: 'Blocked',
                value: '0',
                icon: Icons.block,
                color: Colors.pink,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: const UserStatsCard(
                label: 'Total Users',
                value: '4',
                icon: Icons.people,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const UserStatsCard(
                label: 'Active',
                value: '4',
                icon: Icons.check_circle,
                color: AppTheme.successGreen,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: const UserStatsCard(
                label: 'Blocked',
                value: '0',
                icon: Icons.block,
                color: Colors.pink,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: TextField(
        decoration: const InputDecoration(
          hintText: 'Search users...',
          border: InputBorder.none,
          icon: Icon(Icons.search, color: Colors.grey),
        ),
      ),
    );
  }
}
