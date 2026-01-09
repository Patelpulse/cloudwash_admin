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
  }) async {
    try {
      final docRef = await _firestore.collection('subCategories').add({
        'name': name,
        'categoryId': categoryId,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
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
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'categoryId': categoryId,
        'description': description,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

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
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
    });
  }

  /// Get sub-categories by category ID
  Stream<List<Map<String, dynamic>>> getSubCategoriesByCategoryId(
      String categoryId) {
    return _firestore
        .collection('subCategories')
        .where('categoryId', isEqualTo: categoryId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();
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
}
