import 'package:cloud_admin/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

class CategoryCard extends StatelessWidget {
  final String title;
  final String description;
  final String price;
  final String status;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onViewSubCategories;
  // In a real app, this would be a network image URL
  // For demo, we might use a color placeholder or asset
  final String? imageUrl;
  final Color placeholderColor;

  const CategoryCard({
    super.key,
    required this.title,
    required this.description,
    required this.price,
    required this.status,
    required this.onEdit,
    required this.onDelete,
    required this.onViewSubCategories,
    required this.placeholderColor,
    this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image Area
          Stack(
            children: [
              Container(
                height: 260,
                width: double.infinity,
                color: placeholderColor,
                alignment: Alignment.center,
                child: imageUrl != null && imageUrl!.isNotEmpty
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Icon(
                            Icons.broken_image,
                            size: 64,
                            color: Colors.white.withValues(alpha: 0.5)),
                      )
                    : Icon(Icons.image,
                        size: 64, color: Colors.white.withValues(alpha: 0.5)),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    _buildIconBtn(Icons.edit, Colors.grey.shade700, onEdit),
                    const SizedBox(width: 8),
                    _buildIconBtn(Icons.delete, Colors.red, onDelete),
                  ],
                ),
              ),
            ],
          ),
          // Content Area
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.successGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        status,
                        style: const TextStyle(
                          color: AppTheme.successGreen,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.local_offer,
                        size: 14, color: AppTheme.successGreen),
                    const SizedBox(width: 4),
                    Text(
                      price,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.successGreen,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: onViewSubCategories,
                  child: Row(
                    children: [
                      Text(
                        'View Sub Categories',
                        style: TextStyle(
                          color: AppTheme.primaryBlue,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.arrow_forward,
                          size: 12, color: AppTheme.primaryBlue),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconBtn(IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 16, color: color),
      ),
    );
  }
}
