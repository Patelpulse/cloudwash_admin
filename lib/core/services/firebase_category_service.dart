import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:typed_data';

class FirebaseCategoryService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload image to Firebase Storage
  Future<String> uploadCategoryImage(
    Uint8List imageBytes,
    String fileName, {
    String contentType = 'image/jpeg',
  }) async {
    try {
      final ref = _storage.ref().child('categories/$fileName');
      final uploadTask = ref.putData(
        imageBytes,
        SettableMetadata(contentType: contentType),
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
    String? mongoId,
    int? displayOrder,
  }) async {
    try {
      final effectiveOrder =
          displayOrder ?? await _getNextDisplayOrder(defaultValue: 100000);
      final data = <String, dynamic>{
        'name': name,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'displayOrder': effectiveOrder,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (mongoId != null && mongoId.trim().isNotEmpty) {
        data['mongoId'] = mongoId.trim();
      }

      final docRef = await _firestore.collection('categories').add(data);
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
    String? mongoId,
    int? displayOrder,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'price': price,
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

      if (mongoId != null && mongoId.trim().isNotEmpty) {
        updateData['mongoId'] = mongoId.trim();
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
        .snapshots()
        .map((snapshot) {
      final categories = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          ...doc.data(),
        };
      }).toList();

      categories.sort((a, b) {
        final aOrder = (a['displayOrder'] ?? 100000) as num;
        final bOrder = (b['displayOrder'] ?? 100000) as num;
        if (aOrder != bOrder) return aOrder.compareTo(bOrder);
        final aName = (a['name'] ?? '') as String;
        final bName = (b['name'] ?? '') as String;
        return aName.compareTo(bName);
      });
      return categories;
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

  /// Bulk update display order for categories
  Future<void> updateDisplayOrders(List<Map<String, dynamic>> categories) async {
    final batch = _firestore.batch();
    for (var i = 0; i < categories.length; i++) {
      final id = categories[i]['id'] as String;
      batch.update(
        _firestore.collection('categories').doc(id),
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
          .collection('categories')
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
