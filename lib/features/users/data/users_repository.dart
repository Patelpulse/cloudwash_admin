import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'user_admin_model.dart';

class UsersRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all users from Firebase Firestore users collection
  Future<List<UserAdminModel>> getAllUsers() async {
    try {
      debugPrint('Fetching users from Firestore collection: users');
      final snapshot = await _firestore.collection('users').get();

      debugPrint('Firestore query returned ${snapshot.docs.length} documents');

      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserAdminModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          role: data['role'] ?? 'user',
          profileImage: data['profileImage'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isVerified: data['isVerified'] ?? false,
        );
      }).toList();
    } catch (e) {
      throw Exception('Failed to load users from Firebase: $e');
    }
  }

  /// Get user by ID from Firebase Firestore
  Future<UserAdminModel> getUserById(String id) async {
    try {
      final doc = await _firestore.collection('users').doc(id).get();

      if (!doc.exists) {
        throw Exception('User not found');
      }

      final data = doc.data()!;
      return UserAdminModel(
        id: doc.id,
        name: data['name'] ?? '',
        email: data['email'] ?? '',
        phone: data['phone'] ?? '',
        role: data['role'] ?? 'user',
        profileImage: data['profileImage'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        isVerified: data['isVerified'] ?? false,
      );
    } catch (e) {
      throw Exception('Failed to load user from Firebase: $e');
    }
  }

  /// Delete user from Firebase Firestore
  Future<void> deleteUser(String id) async {
    try {
      await _firestore.collection('users').doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete user from Firebase: $e');
    }
  }

  /// Get user stats from Firestore orders
  Future<Map<String, dynamic>> getUserStats(String userId) async {
    try {
      // First try to fetch orders where userId matches
      var ordersSnapshot = await _firestore
          .collection('orders')
          .where('userId', isEqualTo: userId)
          .get();

      // If no orders found, try to fetch where user._id matches (common in MongoDB synced data)
      if (ordersSnapshot.docs.isEmpty) {
        ordersSnapshot = await _firestore
            .collection('orders')
            .where('user._id', isEqualTo: userId)
            .get();
      }

      double totalSpend = 0;
      for (var doc in ordersSnapshot.docs) {
        final data = doc.data();
        final priceSummary = data['priceSummary'];
        if (priceSummary != null && priceSummary['total'] != null) {
          totalSpend += (priceSummary['total'] as num).toDouble();
        }
      }

      return {
        'totalOrders': ordersSnapshot.docs.length,
        'totalSpend': totalSpend,
      };
    } catch (e) {
      debugPrint('Error fetching stats from Firebase: $e');
      return {'totalOrders': 0, 'totalSpend': 0.0};
    }
  }

  /// Stream orders for a specific user
  Stream<List<Map<String, dynamic>>> getUserOrdersStream(String userId) {
    return _firestore
        .collection('orders')
        .where('user._id', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  /// Stream all users (real-time updates)
  Stream<List<UserAdminModel>> getUsersStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        return UserAdminModel(
          id: doc.id,
          name: data['name'] ?? '',
          email: data['email'] ?? '',
          phone: data['phone'] ?? '',
          role: data['role'] ?? 'user',
          profileImage: data['profileImage'],
          createdAt:
              (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
          isVerified: data['isVerified'] ?? false,
        );
      }).toList();
    });
  }
}
