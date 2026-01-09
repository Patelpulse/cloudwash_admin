import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseAddonService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new addon in Firebase
  Future<String> createAddon({
    required String name,
    required String description,
    required double price,
    required String imageUrl,
    required bool isActive,
  }) async {
    try {
      final docRef = await _firestore.collection('addons').add({
        'name': name,
        'description': description,
        'price': price,
        'imageUrl': imageUrl,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create addon: $e');
    }
  }

  /// Update an existing addon in Firebase
  Future<void> updateAddon({
    required String addonId,
    required String name,
    required String description,
    required double price,
    String? imageUrl,
    required bool isActive,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'description': description,
        'price': price,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await _firestore.collection('addons').doc(addonId).update(updateData);
    } catch (e) {
      throw Exception('Failed to update addon: $e');
    }
  }

  /// Delete an addon from Firebase
  Future<void> deleteAddon(String addonId) async {
    try {
      await _firestore.collection('addons').doc(addonId).delete();
    } catch (e) {
      throw Exception('Failed to delete addon: $e');
    }
  }

  /// Get all addons from Firebase
  Stream<List<Map<String, dynamic>>> getAddons() {
    return _firestore
        .collection('addons')
        .orderBy('name', descending: false)
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

  /// Get active addons only
  Stream<List<Map<String, dynamic>>> getActiveAddons() {
    return _firestore
        .collection('addons')
        .where('isActive', isEqualTo: true)
        .orderBy('name', descending: false)
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

  /// Get a single addon by ID
  Future<Map<String, dynamic>?> getAddonById(String addonId) async {
    try {
      final doc = await _firestore.collection('addons').doc(addonId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get addon: $e');
    }
  }
}
