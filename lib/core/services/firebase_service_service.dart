import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseServiceService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new service in Firebase
  Future<String> createService({
    required String name,
    required String subCategoryId,
    required String categoryId,
    required double price,
    required String description,
    required String imageUrl,
    required bool isActive,
    String? unit,
  }) async {
    try {
      final docRef = await _firestore.collection('services').add({
        'name': name,
        'subCategoryId': subCategoryId,
        'categoryId': categoryId,
        'price': price,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'unit': unit ?? 'piece',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create service: $e');
    }
  }

  /// Update an existing service in Firebase
  Future<void> updateService({
    required String serviceId,
    required String name,
    required String subCategoryId,
    required String categoryId,
    required double price,
    required String description,
    String? imageUrl,
    required bool isActive,
    String? unit,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'subCategoryId': subCategoryId,
        'categoryId': categoryId,
        'price': price,
        'description': description,
        'isActive': isActive,
        'unit': unit ?? 'piece',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await _firestore.collection('services').doc(serviceId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update service: $e');
    }
  }

  /// Delete a service from Firebase
  Future<void> deleteService(String serviceId) async {
    try {
      await _firestore.collection('services').doc(serviceId).delete();
    } catch (e) {
      throw Exception('Failed to delete service: $e');
    }
  }

  /// Get all services from Firebase
  Stream<List<Map<String, dynamic>>> getServices() {
    return _firestore
        .collection('services')
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

  /// Get services by sub-category ID
  Stream<List<Map<String, dynamic>>> getServicesBySubCategoryId(
      String subCategoryId) {
    return _firestore
        .collection('services')
        .where('subCategoryId', isEqualTo: subCategoryId)
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

  /// Get services by category ID
  Stream<List<Map<String, dynamic>>> getServicesByCategoryId(
      String categoryId) {
    return _firestore
        .collection('services')
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

  /// Get a single service by ID
  Future<Map<String, dynamic>?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get service: $e');
    }
  }
}
