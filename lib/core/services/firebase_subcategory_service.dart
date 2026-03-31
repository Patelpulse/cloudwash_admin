import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseSubCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new sub-category in Firebase
  Future<String> createSubCategory({
    required String name,
    required String categoryId,
    required String description,
    required String imageUrl,
    required bool isActive,
    int? displayOrder,
  }) async {
    try {
      final nextOrder =
          displayOrder ?? await _getNextDisplayOrder(defaultValue: 100000);
      final docRef = await _firestore.collection('subCategories').add({
        'name': name,
        'categoryId': categoryId,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'displayOrder': nextOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create sub-category: $e');
    }
  }

  /// Update an existing sub-category in Firebase
  Future<void> updateSubCategory({
    required String subCategoryId,
    required String name,
    required String categoryId,
    required String description,
    String? imageUrl,
    required bool isActive,
    int? displayOrder,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'categoryId': categoryId,
        'description': description,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (displayOrder != null) {
        updateData['displayOrder'] = displayOrder;
      }

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await _firestore
          .collection('subCategories')
          .doc(subCategoryId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update sub-category: $e');
    }
  }

  /// Delete a sub-category from Firebase
  Future<void> deleteSubCategory(String subCategoryId) async {
    try {
      await _firestore.collection('subCategories').doc(subCategoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete sub-category: $e');
    }
  }

  /// Get all sub-categories from Firebase
  Stream<List<Map<String, dynamic>>> getSubCategories() {
    return _firestore
        .collection('subCategories')
        .snapshots()
        .map((snapshot) {
      final subs = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      subs.sort((a, b) {
        final aOrder = (a['displayOrder'] ?? 100000) as num;
        final bOrder = (b['displayOrder'] ?? 100000) as num;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aName = (a['name'] ?? '') as String;
        final bName = (b['name'] ?? '') as String;
        return aName.compareTo(bName);
      });
      return subs;
    });
  }

  /// Get sub-categories by category ID
  Stream<List<Map<String, dynamic>>> getSubCategoriesByCategoryId(
      String categoryId) {
    return _firestore
        .collection('subCategories')
        .where('categoryId', isEqualTo: categoryId)
        .snapshots()
        .map((snapshot) {
      final subs = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      subs.sort((a, b) {
        final aOrder = (a['displayOrder'] ?? 100000) as num;
        final bOrder = (b['displayOrder'] ?? 100000) as num;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aName = (a['name'] ?? '') as String;
        final bName = (b['name'] ?? '') as String;
        return aName.compareTo(bName);
      });
      return subs;
    });
  }

  /// Get a single sub-category by ID
  Future<Map<String, dynamic>?> getSubCategoryById(String subCategoryId) async {
    try {
      final doc =
          await _firestore.collection('subCategories').doc(subCategoryId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get sub-category: $e');
    }
  }

  /// Bulk update display order for sub-categories
  Future<void> updateDisplayOrders(
      List<Map<String, dynamic>> subCategories) async {
    final batch = _firestore.batch();
    for (var i = 0; i < subCategories.length; i++) {
      final id = subCategories[i]['id'] as String;
      batch.update(
        _firestore.collection('subCategories').doc(id),
        {
          'displayOrder': i * 10,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
    }
    await batch.commit();
  }

  Future<int> _getNextDisplayOrder({int defaultValue = 100000}) async {
    try {
      final snapshot = await _firestore
          .collection('subCategories')
          .orderBy('displayOrder', descending: true)
          .limit(1)
          .get();
      if (snapshot.docs.isNotEmpty) {
        final current = snapshot.docs.first.data()['displayOrder'];
        if (current is int) return current + 10;
        if (current is double) return current.toInt() + 10;
      }
      return defaultValue;
    } catch (_) {
      return defaultValue;
    }
  }
}
