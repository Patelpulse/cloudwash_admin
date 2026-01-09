import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FirebaseCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage
  Future<String> uploadCategoryImage(
      Uint8List imageBytes, String fileName) async {
    try {
      final ref = _storage.ref().child('categories/$fileName');
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );
      final snapshot = await uploadTask;
      final downloadUrl = await snapshot.ref.getDownloadURL();
      return downloadUrl;
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  /// Create a new category in Firebase
  Future<String> createCategory({
    required String name,
    required double price,
    required String description,
    required String imageUrl,
    required bool isActive,
  }) async {
    try {
      final docRef = await _firestore.collection('categories').add({
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create category: $e');
    }
  }

  /// Update an existing category in Firebase
  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required double price,
    required String description,
    String? imageUrl,
    required bool isActive,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'price': price,
        'description': description,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await _firestore
          .collection('categories')
          .doc(categoryId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update category: $e');
    }
  }

  /// Delete a category from Firebase
  Future<void> deleteCategory(String categoryId) async {
    try {
      await _firestore.collection('categories').doc(categoryId).delete();
    } catch (e) {
      throw Exception('Failed to delete category: $e');
    }
  }

  /// Get all categories from Firebase
  Stream<List<Map<String, dynamic>>> getCategories() {
    return _firestore
        .collection('categories')
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

  /// Get a single category by ID
  Future<Map<String, dynamic>?> getCategoryById(String categoryId) async {
    try {
      final doc =
          await _firestore.collection('categories').doc(categoryId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get category: $e');
    }
  }
}
