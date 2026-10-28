import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends State<NotificationsScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ======================================================
  // GET CURRENT USER
  // ======================================================

  String? get userId => _auth.currentUser?.uid;

  // ======================================================
  // MARK ONE NOTIFICATION AS READ
  // ======================================================

  Future<void> _markAsRead(String notificationId) async {
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .update({
        'isRead': true,
      });
    } catch (e) {
      debugPrint(
        'NOTIFICATION: Error marking as read: $e',
      );
    }
  }

  // ======================================================
  // MARK ALL NOTIFICATIONS AS READ
  // ======================================================

  Future<void> _markAllAsRead() async {
    if (userId == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .where('isRead', isEqualTo: false)
          .get();

      if (snapshot.docs.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'All notifications are already read.',
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.update(
          doc.reference,
          {
            'isRead': true,
          },
        );
      }

      await batch.commit();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'All notifications marked as read.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'NOTIFICATION: Error marking all as read: $e',
      );
    }
  }

  // ======================================================
  // DELETE NOTIFICATION
  // ======================================================

  Future<void> _deleteNotification(
      String notificationId) async {
    if (userId == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('notifications')
          .doc(notificationId)
          .delete();
    } catch (e) {
      debugPrint(
        'NOTIFICATION: Error deleting notification: $e',
      );
    }
  }

  // ======================================================
  // GET ICON BASED ON NOTIFICATION TYPE
  // ======================================================

  IconData _getNotificationIcon(String type) {
    switch (type) {
      case 'like':
        return Icons.favorite_rounded;

      case 'comment':
        return Icons.chat_bubble_rounded;

      case 'resource':
        return Icons.menu_book_rounded;

      case 'event':
        return Icons.event_rounded;

      case 'expert':
        return Icons.medical_services_rounded;

      case 'campaign':
        return Icons.campaign_rounded;

      default:
        return Icons.notifications_rounded;
    }
  }

  // ======================================================
  // FORMAT TIME
  // ======================================================

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) {
      return 'Just now';
    }

    final DateTime notificationTime =
        timestamp.toDate();

    final DateTime now = DateTime.now();

    final Duration difference =
        now.difference(notificationTime);

    if (difference.inMinutes < 1) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} min ago';
    }

    if (difference.inHours < 24) {
      return '${difference.inHours} hour'
          '${difference.inHours == 1 ? '' : 's'} ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${notificationTime.day}/'
        '${notificationTime.month}/'
        '${notificationTime.year}';
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    if (userId == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          backgroundColor: AppTheme.background,
          elevation: 0,
          automaticallyImplyLeading: false,
          title: const Text(
            'Notifications',
            style: TextStyle(
              fontSize: 21,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
        ),
        body: const Center(
          child: Text(
            'Please login to view notifications.',
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,

      // ==================================================
      // APP BAR
      // ==================================================

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,

        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),

        actions: [
          StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>>(
            stream: _firestore
                .collection('users')
                .doc(userId)
                .collection('notifications')
                .where(
                  'isRead',
                  isEqualTo: false,
                )
                .snapshots(),

            builder: (context, snapshot) {
              final unreadCount =
                  snapshot.data?.docs.length ?? 0;

              if (unreadCount == 0) {
                return const SizedBox();
              }

              return TextButton(
                onPressed: _markAllAsRead,
                child: const Text(
                  'Mark all read',
                  style: TextStyle(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ],
      ),

      // ==================================================
      // FIRESTORE NOTIFICATIONS
      // ==================================================

      body: StreamBuilder<
          QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {
          // Loading
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(30),
                child: Text(
                  'Unable to load notifications.\n\n'
                  '${snapshot.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppTheme.textGrey,
                  ),
                ),
              ),
            );
          }

          final documents =
              snapshot.data?.docs ?? [];

          // Empty
          if (documents.isEmpty) {
            return _buildEmptyState();
          }

          // Notifications
          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              30,
            ),
            itemCount: documents.length,

            itemBuilder: (context, index) {
              final document =
                  documents[index];

              final data =
                  document.data();

              final String title =
                  data['title']?.toString() ??
                      'Notification';

              final String message =
                  data['message']?.toString() ??
                      '';

              final String type =
                  data['type']?.toString() ??
                      'general';

              final bool isRead =
                  data['isRead'] == true;

              final Timestamp? createdAt =
                  data['createdAt']
                      is Timestamp
                  ? data['createdAt']
                      as Timestamp
                  : null;

              return _buildNotificationCard(
                documentId: document.id,
                title: title,
                message: message,
                type: type,
                isRead: isRead,
                createdAt: createdAt,
              );
            },
          );
        },
      ),
    );
  }

  // ======================================================
  // NOTIFICATION CARD
  // ======================================================

  Widget _buildNotificationCard({
    required String documentId,
    required String title,
    required String message,
    required String type,
    required bool isRead,
    required Timestamp? createdAt,
  }) {
    return Dismissible(
      key: ValueKey(documentId),

      direction:
          DismissDirection.endToStart,

      background: Container(
        margin: const EdgeInsets.only(
          bottom: 12,
        ),

        padding: const EdgeInsets.only(
          right: 20,
        ),

        alignment: Alignment.centerRight,

        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius:
              BorderRadius.circular(18),
        ),

        child: const Icon(
          Icons.delete_outline_rounded,
          color: Colors.white,
        ),
      ),

      onDismissed: (_) {
        _deleteNotification(documentId);
      },

      child: GestureDetector(
        onTap: () {
          if (!isRead) {
            _markAsRead(documentId);
          }
        },

        child: Container(
          margin: const EdgeInsets.only(
            bottom: 12,
          ),

          padding: const EdgeInsets.all(15),

          decoration: BoxDecoration(
            color: isRead
                ? Colors.white
                : AppTheme.pastelGreen,

            borderRadius:
                BorderRadius.circular(18),

            border: Border.all(
              color:
                  const Color(0xFFE6EBE7),
            ),
          ),

          child: Row(
            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              // ==========================================
              // ICON
              // ==========================================

              Container(
                width: 48,
                height: 48,

                decoration: BoxDecoration(
                  color: isRead
                      ? AppTheme.pastelBlue
                      : Colors.white,

                  shape: BoxShape.circle,
                ),

                child: Icon(
                  _getNotificationIcon(type),
                  color:
                      AppTheme.primaryDark,
                  size: 23,
                ),
              ),

              const SizedBox(width: 13),

              // ==========================================
              // CONTENT
              // ==========================================

              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,

                            style: TextStyle(
                              fontSize: 15,

                              fontWeight: isRead
                                  ? FontWeight.w600
                                  : FontWeight.bold,

                              color:
                                  AppTheme.textDark,
                            ),
                          ),
                        ),

                        // UNREAD DOT
                        if (!isRead)
                          Container(
                            width: 8,
                            height: 8,

                            decoration:
                                const BoxDecoration(
                              color: AppTheme
                                  .primaryDark,
                              shape:
                                  BoxShape.circle,
                            ),
                          ),
                      ],
                    ),

                    const SizedBox(height: 5),

                    Text(
                      message,

                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color:
                            AppTheme.textGrey,
                      ),
                    ),

                    const SizedBox(height: 7),

                    Text(
                      _formatTime(createdAt),

                      style: const TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ======================================================
  // EMPTY STATE
  // ======================================================

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 90,
              height: 90,

              decoration:
                  const BoxDecoration(
                color:
                    AppTheme.pastelGreen,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.notifications_none_rounded,
                size: 45,
                color:
                    AppTheme.primaryDark,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No notifications',
              style: TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'You are all caught up!',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                color:
                    AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}