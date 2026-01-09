import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestimonialService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Create a new testimonial in Firebase
  Future<String> createTestimonial({
    required String name,
    required String message,
    required String imageUrl,
    required double rating,
    required bool isActive,
    String? designation,
  }) async {
    try {
      final docRef = await _firestore.collection('testimonials').add({
        'name': name,
        'message': message,
        'imageUrl': imageUrl,
        'rating': rating,
        'isActive': isActive,
        'designation': designation ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create testimonial: $e');
    }
  }

  /// Update an existing testimonial in Firebase
  Future<void> updateTestimonial({
    required String testimonialId,
    required String name,
    required String message,
    String? imageUrl,
    required double rating,
    required bool isActive,
    String? designation,
  }) async {
    try {
      final Map<String, dynamic> updateData = {
        'name': name,
        'message': message,
        'rating': rating,
        'isActive': isActive,
        'designation': designation ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (imageUrl != null) {
        updateData['imageUrl'] = imageUrl;
      }

      await _firestore
          .collection('testimonials')
          .doc(testimonialId)
          .update(updateData);
    } catch (e) {
      throw Exception('Failed to update testimonial: $e');
    }
  }

  /// Delete a testimonial from Firebase
  Future<void> deleteTestimonial(String testimonialId) async {
    try {
      await _firestore.collection('testimonials').doc(testimonialId).delete();
    } catch (e) {
      throw Exception('Failed to delete testimonial: $e');
    }
  }

  /// Get all testimonials from Firebase
  Stream<List<Map<String, dynamic>>> getTestimonials() {
    return _firestore
        .collection('testimonials')
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

  /// Get active testimonials only
  Stream<List<Map<String, dynamic>>> getActiveTestimonials() {
    return _firestore
        .collection('testimonials')
        .where('isActive', isEqualTo: true)
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

  /// Get a single testimonial by ID
  Future<Map<String, dynamic>?> getTestimonialById(String testimonialId) async {
    try {
      final doc =
          await _firestore.collection('testimonials').doc(testimonialId).get();
      if (doc.exists) {
        return {
          'id': doc.id,
          ...doc.data() as Map<String, dynamic>,
        };
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get testimonial: $e');
    }
  }
}
