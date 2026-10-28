
import 'package:cloud_firestore/cloud_firestore.dart';

class NotificationService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  /// Creates an in-app notification for another user.
  static Future<void> sendToUser({
    required String recipientId,
    required String title,
    required String message,
    required String type,
    Map<String, dynamic>? extraData,
  }) async {
    if (recipientId.trim().isEmpty) return;

    await _firestore
        .collection('users')
        .doc(recipientId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
      if (extraData != null) ...extraData,
    });
  }
}
