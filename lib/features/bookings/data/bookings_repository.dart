import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final bookingsRepositoryProvider = Provider((ref) => BookingsRepository());

class BookingsRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> updateBookingStatus(
    String orderId,
    String status, {
    String? userId,
  }) async {
    try {
      final updates = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // 1. Update in main orders collection
      await _firestore.collection('orders').doc(orderId).update(updates);

      // 2. Update in user's orders subcollection if userId is known
      String? actualUserId = userId;

      // If userId wasn't provided, try to find it from the main order document
      if (actualUserId == null) {
        final doc = await _firestore.collection('orders').doc(orderId).get();
        actualUserId = doc.data()?['userId'];
      }

      if (actualUserId != null) {
        await _firestore
            .collection('users')
            .doc(actualUserId)
            .collection('orders')
            .doc(orderId)
            .update(updates);
      }

      print('✅ Order $orderId status updated to $status in Firestore');
    } catch (e) {
      print('❌ Firebase update status error: $e');
      throw Exception('Failed to update status in Firebase: $e');
    }
  }
}
