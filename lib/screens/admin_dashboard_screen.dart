
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import 'login_screen.dart';
import 'admin_collaborator_applications_screen.dart';
import 'admin_management _screen.dart';
class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() =>
      _AdminDashboardScreenState();
}

class _AdminDashboardScreenState
    extends State<AdminDashboardScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============================================================
  // MESSAGES
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  // ============================================================
  // USER NOTIFICATIONS
  // ============================================================

  Future<void> _createUserNotification({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    if (userId.trim().isEmpty) {
      throw Exception('The post author ID is missing.');
    }

    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .add({
      'title': title,
      'message': message,
      'type': type,
      'isRead': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  // ============================================================
  // REJECT REASON DIALOG
  // ============================================================

  Future<String?> _askRejectionReason({
    required String title,
    required String itemName,
  }) async {
    final controller = TextEditingController();

    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reason for rejecting "$itemName":'),
              const SizedBox(height: 14),
              TextField(
                controller: controller,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  hintText: 'Enter the reason',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                  controller.text.trim().isEmpty
                      ? 'No reason provided'
                      : controller.text.trim(),
                );
              },
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    return result;
  }

  // ============================================================
  // EXPERT APPROVAL
  // ============================================================

 
Future<void> _approveExpert(
  String expertId,
  String expertName,
) async {
  try {
    await _firestore
        .collection('experts')
        .doc(expertId)
        .update({
      'status': 'approved',
      'verifiedAt': FieldValue.serverTimestamp(),
      'verifiedBy': _auth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await _sendExpertNotification(
        expertId: expertId,
        title: 'Application Approved',
        message:
            'Your expert application has been approved. You can now access expert features.',
      );
    } catch (e) {
      debugPrint('Could not send approval notification: $e');
    }

    _showMessage('$expertName has been approved.');
  } catch (e) {
    _showMessage('Could not approve expert: $e');
  }
}


  
Future<void> _rejectExpert(
  String expertId,
  String expertName,
) async {
  final reason = await _askRejectionReason(
    title: 'Reject Expert Application',
    itemName: expertName,
  );

  if (reason == null) return;

  try {
    await _firestore
        .collection('experts')
        .doc(expertId)
        .update({
      'status': 'rejected',
      'rejectionReason': reason,
      'rejectedAt': FieldValue.serverTimestamp(),
      'rejectedBy': _auth.currentUser?.uid,
      'updatedAt': FieldValue.serverTimestamp(),
    });

    try {
      await _sendExpertNotification(
        expertId: expertId,
        title: 'Application Rejected',
        message:
            'Your expert application was rejected. Reason: $reason',
      );
    } catch (e) {
      debugPrint('Could not send rejection notification: $e');
    }

    _showMessage('$expertName has been rejected.');
  } catch (e) {
    _showMessage('Could not reject expert: $e');
  }
}


  // ============================================================
  // EDUCATIONAL RESOURCE APPROVAL
  // ============================================================

  Future<void> _approveResource(
    String resourceId,
    String title,
  ) async {
    try {
      await _firestore
          .collection('educationalResources')
          .doc(resourceId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('"$title" has been approved.');
    } catch (e) {
      _showMessage('Could not approve resource: $e');
    }
  }

  Future<void> _rejectResource(
    String resourceId,
    String title,
  ) async {
    final reason = await _askRejectionReason(
      title: 'Reject Resource',
      itemName: title,
    );

    if (reason == null) return;

    try {
      await _firestore
          .collection('educationalResources')
          .doc(resourceId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('"$title" has been rejected.');
    } catch (e) {
      _showMessage('Could not reject resource: $e');
    }
  }

  // ============================================================
  // NORMAL EVENT APPROVAL
  // ============================================================

  Future<void> _approveEvent(
    String eventId,
    String title,
  ) async {
    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('"$title" has been approved.');
    } catch (e) {
      _showMessage('Could not approve event: $e');
    }
  }

  Future<void> _rejectEvent(
    String eventId,
    String title,
  ) async {
    final reason = await _askRejectionReason(
      title: 'Reject Event',
      itemName: title,
    );

    if (reason == null) return;

    try {
      await _firestore
          .collection('events')
          .doc(eventId)
          .update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      _showMessage('"$title" has been rejected.');
    } catch (e) {
      _showMessage('Could not reject event: $e');
    }
  }

  // ============================================================
  // COLLABORATION PROPOSAL APPROVAL
  // ============================================================

  Future<void> _approveCollaboration(
    String eventId,
    String title,
  ) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final ref =
            _firestore.collection('events').doc(eventId);

        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('The proposal no longer exists.');
        }

        final data = snapshot.data()!;

        if (data['eventCreatorType'] !=
                'communityCollaborator' ||
            data['collaborationStatus'] != 'pendingAdmin' ||
            data['status'] != 'pending') {
          throw Exception(
            'This proposal has already been processed.',
          );
        }

        transaction.update(ref, {
          'status': 'approved',
          'collaborationStatus': 'approved',
          'approvedAt': FieldValue.serverTimestamp(),
          'approvedBy': _auth.currentUser?.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      _showMessage(
        '"$title" has been approved and is ready for publication.',
      );
    } catch (e) {
      _showMessage(
        'Could not approve collaboration: $e',
      );
    }
  }

  Future<void> _rejectCollaboration(
    String eventId,
    String title,
  ) async {
    final reason = await _askRejectionReason(
      title: 'Reject Collaboration Proposal',
      itemName: title,
    );

    if (reason == null) return;

    try {
      await _firestore.runTransaction((transaction) async {
        final ref =
            _firestore.collection('events').doc(eventId);

        final snapshot = await transaction.get(ref);

        if (!snapshot.exists) {
          throw Exception('The proposal no longer exists.');
        }

        final data = snapshot.data()!;

        if (data['eventCreatorType'] !=
                'communityCollaborator' ||
            data['collaborationStatus'] != 'pendingAdmin' ||
            data['status'] != 'pending') {
          throw Exception(
            'This proposal has already been processed.',
          );
        }

        transaction.update(ref, {
          'status': 'rejected',
          'collaborationStatus': 'rejected',
          'rejectionReason': reason,
          'rejectedAt': FieldValue.serverTimestamp(),
          'rejectedBy': _auth.currentUser?.uid,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });

      _showMessage('"$title" has been rejected.');
    } catch (e) {
      _showMessage(
        'Could not reject collaboration: $e',
      );
    }
  }

  // ============================================================
  // COMMUNITY POST APPROVAL + NOTIFICATION
  // ============================================================

  Future<void> _approvePost(
    String postId,
    String title,
  ) async {
    try {
      final postRef =
          _firestore.collection('posts').doc(postId);

      final postSnapshot = await postRef.get();

      if (!postSnapshot.exists) {
        _showMessage('Post not found.');
        return;
      }

      final postData = postSnapshot.data()!;
      final userId = postData['userId']?.toString();

      if (userId == null || userId.trim().isEmpty) {
        _showMessage(
          'Cannot approve post: author ID is missing.',
        );
        return;
      }

      // Keep the existing post approval behavior.
      await postRef.update({
        'status': 'approved',
        'approvedAt': FieldValue.serverTimestamp(),
        'approvedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Notify the author after approval succeeds.
      try {
        await _createUserNotification(
          userId: userId,
          title: 'Post Approved! 🎉',
          message:
              'Your post "$title" has been approved and is now visible in the community.',
          type: 'post_approved',
        );

        _showMessage(
          'Post approved. Notification sent to the author.',
        );
      } catch (notificationError) {
        _showMessage(
          'Post approved, but notification failed: '
          '$notificationError',
        );
      }
    } catch (e) {
      _showMessage('Could not approve post: $e');
    }
  }

  // ============================================================
  // COMMUNITY POST REJECTION + NOTIFICATION
  // ============================================================

  Future<void> _rejectPost(
    String postId,
    String title,
  ) async {
    final reason = await _askRejectionReason(
      title: 'Reject Community Post',
      itemName: title,
    );

    if (reason == null) return;

    try {
      final postRef =
          _firestore.collection('posts').doc(postId);

      final postSnapshot = await postRef.get();

      if (!postSnapshot.exists) {
        _showMessage('Post not found.');
        return;
      }

      final postData = postSnapshot.data()!;
      final userId = postData['userId']?.toString();

      if (userId == null || userId.trim().isEmpty) {
        _showMessage(
          'Cannot reject post: author ID is missing.',
        );
        return;
      }

      await postRef.update({
        'status': 'rejected',
        'rejectionReason': reason,
        'rejectedAt': FieldValue.serverTimestamp(),
        'rejectedBy': _auth.currentUser?.uid,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      try {
        await _createUserNotification(
          userId: userId,
          title: 'Post Not Approved',
          message:
              'Your post "$title" was not approved. Reason: $reason',
          type: 'post_rejected',
        );

        _showMessage(
          'Post rejected. Notification sent to the author.',
        );
      } catch (notificationError) {
        _showMessage(
          'Post rejected, but notification failed: '
          '$notificationError',
        );
      }
    } catch (e) {
      _showMessage('Could not reject post: $e');
    }
  }

  // ============================================================
  // DETAILS DIALOG
  // ============================================================

  void _showDetails(
    String title,
    Map<String, dynamic> data,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: data.entries.map((entry) {
                final value = entry.value;

                final displayValue = value is Timestamp
                    ? value.toDate().toString()
                    : value?.toString() ?? 'Not provided';

                return Padding(
                  padding: const EdgeInsets.only(
                    bottom: 12,
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        _label(entry.key),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(height: 3),
                      SelectableText(displayValue),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () =>
                  Navigator.pop(dialogContext),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  String _label(String key) {
    return key
        .replaceAllMapped(
          RegExp(r'([A-Z])'),
          (match) => ' ${match.group(1)}',
        )
        .replaceAll('_', ' ')
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map(
          (part) =>
              '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  // ============================================================
  // COMMON SECTION HEADER
  // ============================================================

  Widget _sectionHeader(
    String title,
    String subtitle,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8ECE9),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 32,
            color: AppTheme.primaryDark,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS CHIP
  // ============================================================

  Widget _statusChip(String status) {
    final color = status == 'approved'
        ? AppTheme.pastelGreen
        : status == 'rejected'
            ? AppTheme.pastelPink
            : AppTheme.pastelYellow;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ============================================================
  // GENERIC MODERATION CARD
  // ============================================================

  Widget _moderationCard({
    required String id,
    required String title,
    required String subtitle,
    required String status,
    required Map<String, dynamic> data,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    required bool showActions,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: iconColor,
                  child: Icon(
                    icon,
                    color: AppTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                ),
                _statusChip(status),
              ],
            ),
            const SizedBox(height: 14),
            Text(
              data['description']?.toString() ??
                  data['content']?.toString() ??
                  'No description provided.',
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppTheme.textGrey,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: () => _showDetails(title, data),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('View Details'),
            ),
            if (showActions) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onReject,
                      icon: const Icon(Icons.close),
                      label: const Text('Reject'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onApprove,
                      icon: const Icon(Icons.check),
                      label: const Text('Approve'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ============================================================
  // STREAM SECTION
  // ============================================================

  Widget _streamSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Stream<QuerySnapshot<Map<String, dynamic>>>
        stream,
    required Widget Function(
      QueryDocumentSnapshot<Map<String, dynamic>> doc,
    ) itemBuilder,
    required String emptyMessage,
  }) {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: stream,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              'Could not load $title: ${snapshot.error}',
            ),
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(20),
            child: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        final docs = snapshot.data?.docs ?? [];

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              title,
              '${docs.length} item${docs.length == 1 ? '' : 's'} waiting for review',
              icon,
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  emptyMessage,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                  ),
                ),
              )
            else
              ...docs.map(itemBuilder),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ============================================================
  // EXPERT SECTION
  // ============================================================

  Widget _expertSection() {
    return _streamSection(
      title: 'Expert Verification',
      subtitle: 'Review professional applications',
      icon: Icons.medical_services_outlined,
      stream: _firestore
          .collection('experts')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      emptyMessage: 'No pending expert applications.',
      itemBuilder: (doc) {
        final data = doc.data();
        final name =
            data['name']?.toString() ?? 'Unknown Expert';

        return _moderationCard(
          id: doc.id,
          title: name,
          subtitle:
              '${data['expertType'] ?? 'Expert'} • ${data['qualification'] ?? 'Qualification not provided'}',
          status: 'pending',
          data: data,
          icon: Icons.medical_services_outlined,
          iconColor: AppTheme.pastelGreen,
          showActions: true,
          onApprove: () => _approveExpert(doc.id, name),
          onReject: () => _rejectExpert(doc.id, name),
        );
      },
    );
  }
  
Future<void> _sendExpertNotification({
  required String expertId,
  required String title,
  required String message,
}) async {
  await _firestore
      .collection('experts')
      .doc(expertId)
      .collection('notifications')
      .add({
    'title': title,
    'message': message,
    'isRead': false,
    'createdAt': FieldValue.serverTimestamp(),
  });
}


  // ============================================================
  // RESOURCE SECTION
  // ============================================================

  Widget _resourceSection() {
    return _streamSection(
      title: 'Educational Resources',
      subtitle: 'Review resources submitted by experts',
      icon: Icons.menu_book_outlined,
      stream: _firestore
          .collection('educationalResources')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      emptyMessage: 'No pending educational resources.',
      itemBuilder: (doc) {
        final data = doc.data();
        final title =
            data['title']?.toString() ?? 'Untitled Resource';

        return _moderationCard(
          id: doc.id,
          title: title,
          subtitle:
              '${data['category'] ?? 'General'} • ${data['expertName'] ?? 'Unknown Expert'}',
          status: 'pending',
          data: data,
          icon: Icons.menu_book_outlined,
          iconColor: AppTheme.pastelBlue,
          showActions: true,
          onApprove: () => _approveResource(doc.id, title),
          onReject: () => _rejectResource(doc.id, title),
        );
      },
    );
  }

  // ============================================================
  // NORMAL EVENT SECTION
  // ============================================================

  Widget _normalEventSection() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('events')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Could not load events: ${snapshot.error}',
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((doc) {
          final data = doc.data();

          return data['eventCreatorType'] !=
              'communityCollaborator';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Event Management',
              '${docs.length} normal event${docs.length == 1 ? '' : 's'} waiting for review',
              Icons.event_outlined,
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No pending normal events.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                  ),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();
                final title =
                    data['title']?.toString() ??
                        'Untitled Event';

                return _moderationCard(
                  id: doc.id,
                  title: title,
                  subtitle:
                      '${data['eventType'] ?? 'General'} • ${data['expertName'] ?? 'Unknown Expert'}',
                  status: 'pending',
                  data: data,
                  icon: Icons.event_outlined,
                  iconColor: AppTheme.pastelYellow,
                  showActions: true,
                  onApprove: () =>
                      _approveEvent(doc.id, title),
                  onReject: () =>
                      _rejectEvent(doc.id, title),
                );
              }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  // ============================================================
  // COLLABORATION PROPOSALS
  // ============================================================

  Widget _collaborationSection() {
    return StreamBuilder<
        QuerySnapshot<Map<String, dynamic>>>(
      stream: _firestore
          .collection('events')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Text(
            'Could not load collaboration proposals: ${snapshot.error}',
          );
        }

        if (snapshot.connectionState ==
            ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final docs = (snapshot.data?.docs ?? [])
            .where((doc) {
          final data = doc.data();

          return data['eventCreatorType'] ==
                  'communityCollaborator' &&
              data['collaborationStatus'] ==
                  'pendingAdmin';
        }).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              'Collaboration Proposals',
              '${docs.length} proposal${docs.length == 1 ? '' : 's'} accepted by experts and waiting for your decision',
              Icons.handshake_outlined,
            ),
            const SizedBox(height: 14),
            if (docs.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'No collaboration proposals awaiting approval.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                  ),
                ),
              )
            else
              ...docs.map((doc) {
                final data = doc.data();

                final title =
                    data['title']?.toString() ??
                        'Untitled Proposal';

                final collaborator =
                    data['collaboratorName']?.toString() ??
                        'Community Collaborator';

                final expert =
                    data['expertName']?.toString() ??
                        'Assigned Expert';

                final eventDate =
                    data['date']?.toString() ??
                        data['eventDate']?.toString() ??
                        'Date not provided';

                final eventTime =
                    data['time']?.toString() ??
                        'Time not provided';

                final mode =
                    data['mode']?.toString() ??
                        'Not specified';

                final venue =
                    data['venue']?.toString() ??
                        data['location']?.toString() ??
                        'Not specified';

                return Card(
                  margin: const EdgeInsets.only(
                    bottom: 16,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const CircleAvatar(
                              backgroundColor:
                                  AppTheme.pastelGreen,
                              child: Icon(
                                Icons.handshake_outlined,
                                color: AppTheme.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textDark,
                                ),
                              ),
                            ),
                            _statusChip('pendingAdmin'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          data['description']?.toString() ??
                              'No description provided.',
                          style: const TextStyle(
                            color: AppTheme.textGrey,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _proposalDetail('Collaborator', collaborator),
                        _proposalDetail('Assigned Expert', expert),
                        _proposalDetail('Date', eventDate),
                        _proposalDetail('Time', eventTime),
                        _proposalDetail('Mode', mode),
                        _proposalDetail('Venue', venue),
                        const SizedBox(height: 12),
                        OutlinedButton.icon(
                          onPressed: () =>
                              _showDetails(title, data),
                          icon: const Icon(
                            Icons.visibility_outlined,
                          ),
                          label: const Text(
                            'View Full Proposal',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () =>
                                    _rejectCollaboration(
                                  doc.id,
                                  title,
                                ),
                                icon: const Icon(Icons.close),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor:
                                      Colors.redAccent,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () =>
                                    _approveCollaboration(
                                  doc.id,
                                  title,
                                ),
                                icon: const Icon(Icons.check),
                                label: const Text('Approve'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              }),
            const SizedBox(height: 24),
          ],
        );
      },
    );
  }

  Widget _proposalDetail(
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.textDark,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppTheme.textGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // COMMUNITY POST SECTION
  // ============================================================

  Widget _postSection() {
    return _streamSection(
      title: 'Community Post Moderation',
      subtitle: 'Review posts before community publication',
      icon: Icons.people_outline,
      stream: _firestore
          .collection('posts')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      emptyMessage: 'No pending community posts.',
      itemBuilder: (doc) {
        final data = doc.data();
        final title =
            data['title']?.toString() ?? 'Community Post';

        final author =
            data['authorName']?.toString() ??
                data['userName']?.toString() ??
                data['name']?.toString() ??
                'Community User';

        return _moderationCard(
          id: doc.id,
          title: title,
          subtitle:
              '$author • ${data['category'] ?? 'General'}',
          status: 'pending',
          data: data,
          icon: Icons.people_outline,
          iconColor: AppTheme.pastelGreen,
          showActions: true,
          onApprove: () => _approvePost(doc.id, title),
          onReject: () => _rejectPost(doc.id, title),
        );
      },
    );
  }

  // ============================================================
  // COMMUNITY COLLABORATOR APPLICATIONS
  // ============================================================

  Widget _collaboratorApplicationsCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Community Collaborators',
          'Manage community members who want to collaborate',
          Icons.people_alt_outlined,
        ),
        const SizedBox(height: 14),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppTheme.pastelGreen,
                      child: Icon(
                        Icons.manage_accounts_outlined,
                        color: AppTheme.primaryDark,
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Collaborator Applications',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'Review applications from community members who want to work with experts.',
                  style: TextStyle(
                    color: AppTheme.textGrey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const AdminCollaboratorApplicationsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.manage_accounts_outlined,
                    ),
                    label: const Text('Review Applications'),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> _logout() async {
    try {
      await _auth.signOut();

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => const LoginScreen(),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage('Could not log out: $e');
    }
  }

  // ============================================================
  // USER / EXPERT / RESOURCE MANAGEMENT
  // ============================================================

  Widget _managementToolsCard() {
    return Card(
      elevation: 0,
      color: AppTheme.pastelBlue,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(Icons.admin_panel_settings_outlined,
                  color: AppTheme.primaryDark),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Management Centre',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppTheme.textDark,
                      )),
                  SizedBox(height: 4),
                  Text('Search users, review all experts, and manage resources.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.textGrey,
                      )),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Open management centre',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AdminManagementScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward_ios_rounded),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Admin Panel',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          setState(() {});
          await Future<void>.delayed(
            const Duration(milliseconds: 300),
          );
        },
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            _managementToolsCard(),
            const SizedBox(height: 12),
            _expertSection(),
            _resourceSection(),
            _normalEventSection(),
            _collaborationSection(),
            _postSection(),
            _collaboratorApplicationsCard(),
          ],
        ),
      ),
    );
  }
}
