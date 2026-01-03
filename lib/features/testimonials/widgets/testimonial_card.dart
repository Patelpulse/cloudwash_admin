import 'package:flutter/material.dart';

class TestimonialCard extends StatelessWidget {
  final String name;
  final String role; // e.g. "Customer"
  final double rating; // 1 to 5
  final String review;
  final String avatarLetter;
  final Color avatarColor;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const TestimonialCard({
    super.key,
    required this.name,
    required this.role,
    required this.rating,
    required this.review,
    required this.avatarLetter,
    required this.avatarColor,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          // Header: Avatar + Info + Status Dot
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: avatarColor.withValues(alpha: 0.2),
                child: Text(
                  avatarLetter,
                  style: TextStyle(
                    color: avatarColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      role,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              // Status Dot
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.green, // Active status green dot
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Star Rating
          Row(
            children: List.generate(5, (index) {
              return Icon(
                Icons.star,
                size: 16,
                color: index < rating ? Colors.amber : Colors.grey.shade300,
              );
            }),
          ),
          const SizedBox(height: 12),
          // Review Text
          Expanded(
            child: Text(
              '"$review"',
              style: TextStyle(
                fontSize: 14,
                fontStyle: FontStyle.italic,
                color: Colors.grey.shade700,
                height: 1.4,
              ),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Divider(height: 32),
          // Actions
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onEdit,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.edit,
                      size: 20, color: Colors.blueGrey.shade400),
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: onDelete,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.delete,
                      size: 20, color: Colors.redAccent.shade200),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
