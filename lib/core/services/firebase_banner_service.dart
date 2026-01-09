import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseBannerService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new banner in Firebase
  Future<String> createBanner({
    required String title,
    required String description,
    required String imageUrl,
    required bool isActive,
    int order = 0,
  }) async {
    try {
      final docRef = await _firestore.collection('banners').add({
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'order': order,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create banner: $e');
    }
  }

  /// Update an existing banner in Firebase
  Future<void> updateBanner({
    required String bannerId,
    required String title,
    required String description,
    String? imageUrl,
    required bool isActive,
    int? order,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'title': title,
        'description': description,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      if (order != null) {
        updateData['order'] = order;
      }

      await _firestore.collection('banners').doc(bannerId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update banner: $e');
    }
  }

  /// Delete a banner from Firebase
  Future<void> deleteBanner(String bannerId) async {
    try {
      await _firestore.collection('banners').doc(bannerId).delete();
    } catch (e) {
      throw Exception('Failed to delete banner: $e');
    }
  }

  /// Get all banners from Firebase
  Stream<List<Map<String, dynamic>>> getBanners() {
    return _firestore
        .collection('banners')
        .orderBy('order', descending: false)
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

  /// Get active banners only
  Stream<List<Map<String, dynamic>>> getActiveBanners() {
    return _firestore
        .collection('banners')
        .where('isActive', isEqualTo: true)
        .orderBy('order', descending: false)
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

  /// Get a single banner by ID
  Future<Map<String, dynamic>?> getBannerById(String bannerId) async {
    try {
      final doc = await _firestore.collection('banners').doc(bannerId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get banner: $e');
    }
  }
}
