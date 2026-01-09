import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseCityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new city in Firebase
  Future<String> createCity({
    required String name,
    required String state,
    required String country,
    required bool isActive,
  }) async {
    try {
      final docRef = await _firestore.collection('cities').add({
        'name': name,
        'state': state,
        'country': country,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create city: $e');
    }
  }

  /// Update an existing city in Firebase
  Future<void> updateCity({
    required String cityId,
    required String name,
    required String state,
    required String country,
    required bool isActive,
  }) async {
    try {
      await _firestore.collection('cities').doc(cityId).update({
        'name': name,
        'state': state,
        'country': country,
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update city: $e');
    }
  }

  /// Delete a city from Firebase
  Future<void> deleteCity(String cityId) async {
    try {
      await _firestore.collection('cities').doc(cityId).delete();
    } catch (e) {
      throw Exception('Failed to delete city: $e');
    }
  }

  /// Get all cities from Firebase
  Stream<List<Map<String, dynamic>>> getCities() {
    return _firestore
        .collection('cities')
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

  /// Get active cities only
  Stream<List<Map<String, dynamic>>> getActiveCities() {
    return _firestore
        .collection('cities')
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

  /// Get a single city by ID
  Future<Map<String, dynamic>?> getCityById(String cityId) async {
    try {
      final doc = await _firestore.collection('cities').doc(cityId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get city: $e');
    }
  }
}
