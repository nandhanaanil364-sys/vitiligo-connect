
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';
import '../services/notification_service.dart';

import 'community_screen.dart';
import 'learn_screen.dart';
import 'experts_screen.dart';
import 'events_screen.dart';
import 'profile_screen.dart';
import 'notifications_screen.dart';
import 'journal_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userName = '';
  bool isLoadingName = true;

  @override
  void initState() {
    super.initState();
    _loadUserName();
  }

  // LOAD USER NAME

  Future<void> _loadUserName() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        if (!mounted) return;
        setState(() => isLoadingName = false);
        return;
      }

      final document =
          await _firestore.collection('users').doc(user.uid).get();

      final data = document.data();
      final name =
          (data?['name'] ?? data?['userName'])?.toString().trim() ?? '';

      if (!mounted) return;

      setState(() {
        userName = name;
        isLoadingName = false;
      });
    } catch (e) {
      debugPrint('HOME USER ERROR: $e');
      if (!mounted) return;
      setState(() => isLoadingName = false);
    }
  }

  // NAVIGATION

  void _openPersonalJournal() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const JournalScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openCommunity() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const CommunityScreen()),
    );
  }

  void _openEvents() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const EventsScreen()),
    );
  }

  void _openExperts() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ExpertsScreen()),
    );
  }

  void _openLearn() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const LearnScreen()),
    );
  }

  void _openProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ProfileScreen()),
    );
  }

  // BUILD

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            onPressed: _openPersonalJournal,
            tooltip: 'Personal Journal',
            icon: const Icon(
              Icons.auto_stories_rounded,
              color: AppTheme.primaryDark,
              size: 27,
            ),
          ),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isLoadingName
                  ? 'Hello! 👋'
                  : userName.isNotEmpty
                      ? 'Hello, $userName! 👋'
                      : 'Hello! 👋',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'Vitiligo Connect',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ],
        ),
        actions: [
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: currentUser == null
                ? null
                : _firestore
                    .collection('users')
                    .doc(currentUser.uid)
                    .collection('notifications')
                    .where('isRead', isEqualTo: false)
                    .snapshots(),
            builder: (context, snapshot) {
              final unreadCount = snapshot.data?.docs.length ?? 0;

              return IconButton(
                onPressed: _openNotifications,
                tooltip: 'Notifications',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(
                      Icons.notifications_none_rounded,
                      color: AppTheme.textDark,
                      size: 27,
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        right: -7,
                        top: -5,
                        child: Container(
                          constraints: const BoxConstraints(
                            minWidth: 18,
                            minHeight: 18,
                          ),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _firestore
              .collection('posts')
              .where('status', isEqualTo: 'approved')
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryDark,
                ),
              );
            }

            if (snapshot.hasError) {
              debugPrint('HOME COMMUNITY ERROR: ${snapshot.error}');
              return _buildErrorState();
            }

            final documents =
                List<QueryDocumentSnapshot<Map<String, dynamic>>>.from(
              snapshot.data?.docs ?? [],
            );

            documents.sort((a, b) {
              final aCreated = a.data()['createdAt'];
              final bCreated = b.data()['createdAt'];

              final aTime = aCreated is Timestamp ? aCreated : null;
              final bTime = bCreated is Timestamp ? bCreated : null;

              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;

              return bTime.compareTo(aTime);
            });

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 100),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Community',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                    Material(
                      color: AppTheme.primaryDark,
                      shape: const CircleBorder(),
                      child: InkWell(
                        onTap: _showCreatePostDialog,
                        customBorder: const CircleBorder(),
                        child: const SizedBox(
                          width: 42,
                          height: 42,
                          child: Icon(
                            Icons.add_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Connect, share and support one another.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                  ),
                ),
                const SizedBox(height: 18),
                if (documents.isEmpty)
                  _buildEmptyState()
                else
                  ...documents.map(
                    (document) => Padding(
                      padding: const EdgeInsets.only(bottom: 15),
                      child: _buildPostCard(document),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        elevation: 3,
        selectedIndex: 0,
        onDestinationSelected: (index) {
          if (index == 0) return;
          if (index == 1) {
            _openEvents();
          } else if (index == 2) {
            _openExperts();
          } else if (index == 3) {
            _openLearn();
          } else if (index == 4) {
            _openProfile();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.event_outlined),
            selectedIcon: Icon(Icons.event_rounded),
            label: 'Events',
          ),
          NavigationDestination(
            icon: Icon(Icons.medical_services_outlined),
            selectedIcon: Icon(Icons.medical_services_rounded),
            label: 'Experts',
          ),
          NavigationDestination(
            icon: Icon(Icons.menu_book_outlined),
            selectedIcon: Icon(Icons.menu_book_rounded),
            label: 'Learn',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  // POST CARD

  Widget _buildPostCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final post = document.data();
    final String postId = document.id;
    final String name = post['name']?.toString() ?? 'Community Member';
    final String category =
        post['category']?.toString() ?? 'Experience';
    final String title = post['title']?.toString() ?? '';
    final String content = post['content']?.toString() ?? '';
    final int likes = (post['likes'] as num?)?.toInt() ?? 0;
    final int comments = (post['comments'] as num?)?.toInt() ?? 0;
    final String authorId = post['userId']?.toString() ?? '';
    final bool isOwner = _auth.currentUser?.uid == authorId;

    final Timestamp? createdAt = post['createdAt'] is Timestamp
        ? post['createdAt'] as Timestamp
        : null;
    final String timeText =
        createdAt != null ? _formatTime(createdAt) : 'Just now';

    final currentUser = _auth.currentUser;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: currentUser == null
          ? null
          : _firestore
              .collection('posts')
              .doc(postId)
              .collection('likes')
              .doc(currentUser.uid)
              .snapshots(),
      builder: (context, likeSnapshot) {
        final bool liked = likeSnapshot.data?.exists ?? false;

        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFE8ECE9)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 45,
                    height: 45,
                    decoration: const BoxDecoration(
                      color: AppTheme.pastelBlue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryDark,
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          timeText,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppTheme.textGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelYellow,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      category,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              if (title.isNotEmpty)
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
              if (title.isNotEmpty) const SizedBox(height: 7),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textGrey,
                ),
              ),
              const SizedBox(height: 15),
              const Divider(height: 1, color: Color(0xFFE8ECE9)),
              const SizedBox(height: 7),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () => _toggleLike(postId, liked),
                    icon: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 21,
                      color:
                          liked ? Colors.redAccent : AppTheme.textGrey,
                    ),
                    label: Text(
                      '$likes',
                      style: TextStyle(
                        color:
                            liked ? Colors.redAccent : AppTheme.textGrey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  TextButton.icon(
                    onPressed: () => _showCommentsBottomSheet(postId),
                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: AppTheme.textGrey,
                    ),
                    label: Text(
                      '$comments',
                      style: const TextStyle(color: AppTheme.textGrey),
                    ),
                  ),
                  const Spacer(),
                  if (isOwner)
                    IconButton(
                      onPressed: () => _showDeletePostDialog(postId),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Post sharing will be added later.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.share_outlined,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  
  // CREATE POST DIALOG
  Future<void> _showCreatePostDialog() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    String selectedCategory = 'Experience';
    bool isSubmitting = false;

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogRouteContext) {
          return StatefulBuilder(
            builder: (dialogContext, setDialogState) {
              return AlertDialog(
                title: const Text(
                  'Create Post',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: titleController,
                        enabled: !isSubmitting,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Post Title',
                          hintText: 'Enter a title',
                          prefixIcon:
                              const Icon(Icons.title_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: contentController,
                        enabled: !isSubmitting,
                        minLines: 3,
                        maxLines: 15,
                        textCapitalization:
                            TextCapitalization.sentences,
                        decoration: InputDecoration(
                          labelText: 'Your Post',
                          hintText: 'Share your thoughts...',
                          alignLabelWithHint: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<String>(
                        initialValue: selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon:
                              const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Experience',
                            child: Text('Experience'),
                          ),
                          DropdownMenuItem(
                            value: 'Support',
                            child: Text('Support'),
                          ),
                          DropdownMenuItem(
                            value: 'Question',
                            child: Text('Question'),
                          ),
                          DropdownMenuItem(
                            value: 'Awareness',
                            child: Text('Awareness'),
                          ),
                        ],
                        onChanged: isSubmitting
                            ? null
                            : (value) {
                                if (value != null) {
                                  setDialogState(() {
                                    selectedCategory = value;
                                  });
                                }
                              },
                      ),
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(
                              dialogRouteContext,
                            ).pop(),
                    child: const Text('Cancel'),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: isSubmitting
                        ? null
                        : () async {
                            final title =
                                titleController.text.trim();
                            final content =
                                contentController.text.trim();

                            if (title.isEmpty || content.isEmpty) {
                              ScaffoldMessenger.of(context)
                                  .showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Please enter a title and post.',
                                  ),
                                  behavior:
                                      SnackBarBehavior.floating,
                                ),
                              );
                              return;
                            }

                            setDialogState(() {
                              isSubmitting = true;
                            });

                            final success = await _createPost(
                              title: title,
                              content: content,
                              category: selectedCategory,
                            );

                            if (!dialogContext.mounted) return;

                            if (success) {
                              Navigator.of(
                                dialogRouteContext,
                              ).pop();
                            } else {
                              setDialogState(() {
                                isSubmitting = false;
                              });
                            }
                          },
                    child: isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Submit Post'),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      // Let the dialog route finish its closing transition
      // before disposing the controllers used by its TextFields.
      await Future<void>.delayed(
        const Duration(milliseconds: 300),
      );

      titleController.dispose();
      contentController.dispose();
    }
  }

  // CREATE POST — Firestore write

  Future<bool> _createPost({
    required String title,
    required String content,
    required String category,
  }) async {
    final user = _auth.currentUser;

    if (user == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please log in to create a post.'),
          ),
        );
      }
      return false;
    }

    try {
      final userDocument =
          await _firestore.collection('users').doc(user.uid).get();
      final userData = userDocument.data();

      String name = userName.isNotEmpty ? userName : 'You';
      final storedName = userData?['name']?.toString().trim();

      if (storedName != null && storedName.isNotEmpty) {
        name = storedName;
      } else {
        final alternateName = userData?['userName']?.toString().trim();
        if (alternateName != null && alternateName.isNotEmpty) {
          name = alternateName;
        }
      }

      await _firestore.collection('posts').add({
        'userId': user.uid,
        'name': name,
        'title': title,
        'content': content,
        'category': category,
        'likes': 0,
        'comments': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'status': 'pending',
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Post submitted for approval! 🎉'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return true;
    } catch (e, stackTrace) {
      debugPrint('CREATE POST ERROR: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unable to create post: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      return false;
    }
  }

  // LIKE / UNLIKE + NOTIFICATION

  Future<void> _toggleLike(
    String postId,
    bool currentlyLiked,
  ) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final postReference = _firestore.collection('posts').doc(postId);
      final postSnapshot = await postReference.get();
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.data();
      if (postData == null) return;

      final String authorId = postData['userId']?.toString() ?? '';
      final likeReference =
          postReference.collection('likes').doc(user.uid);

      if (currentlyLiked) {
        await likeReference.delete();
        await postReference.update({
          'likes': FieldValue.increment(-1),
        });
        return;
      }

      if ((await likeReference.get()).exists) return;

      await likeReference.set({
        'userId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await postReference.update({
        'likes': FieldValue.increment(1),
      });

      if (authorId.isNotEmpty && authorId != user.uid) {
        String likerName = 'Someone';

        final userSnapshot =
            await _firestore.collection('users').doc(user.uid).get();
        final storedName =
            userSnapshot.data()?['name']?.toString().trim();

        if (storedName != null && storedName.isNotEmpty) {
          likerName = storedName;
        }

        try {
          await NotificationService.sendToUser(
            recipientId: authorId,
            title: 'New like ❤️',
            message: '$likerName liked your community post.',
            type: 'like',
            extraData: {
              'postId': postId,
              'actorId': user.uid,
            },
          );
        } catch (e) {
          debugPrint('LIKE NOTIFICATION ERROR: $e');
        }
      }
    } catch (e) {
      debugPrint('LIKE ERROR: $e');
    }
  }

  // COMMENTS BOTTOM SHEET

  void _showCommentsBottomSheet(String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext).viewInsets.bottom,
          ),
          child: Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(28),
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 15, 10, 10),
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: const BoxDecoration(
                          color: AppTheme.pastelGreen,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          color: AppTheme.primaryDark,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Comments',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: () =>
                            Navigator.pop(bottomSheetContext),
                        icon: const Icon(Icons.close_rounded),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0xFFE8ECE9)),
                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy('createdAt')
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryDark,
                          ),
                        );
                      }

                      if (snapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(25),
                            child: Text(
                              'Unable to load comments.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: AppTheme.textGrey),
                            ),
                          ),
                        );
                      }

                      final comments = snapshot.data?.docs ?? [];
                      if (comments.isEmpty) {
                        return _buildNoCommentsState();
                      }

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(20, 15, 20, 15),
                        itemCount: comments.length,
                        itemBuilder: (context, index) {
                          return _buildCommentItem(
                            comments[index].data(),
                          );
                        },
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.fromLTRB(15, 10, 15, 15),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.06),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: commentController,
                          maxLines: 3,
                          minLines: 1,
                          decoration: InputDecoration(
                            hintText: 'Write a comment...',
                            filled: true,
                            fillColor: AppTheme.background,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(22),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: AppTheme.primaryDark,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () async {
                            final comment = commentController.text.trim();
                            if (comment.isEmpty) return;

                            await _addComment(postId, comment);

                            if (commentController.text.trim() == comment) {
                              commentController.clear();
                            }
                          },
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                            size: 21,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    ).whenComplete(commentController.dispose);
  }

  // COMMENT ITEM

  Widget _buildCommentItem(Map<String, dynamic> comment) {
    final String name =
        comment['name']?.toString() ?? 'Community Member';
    final String text = comment['comment']?.toString() ?? '';

    final Timestamp? createdAt = comment['createdAt'] is Timestamp
        ? comment['createdAt'] as Timestamp
        : null;
    final String timeText =
        createdAt != null ? _formatTime(createdAt) : 'Just now';

    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              color: AppTheme.pastelBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_rounded,
              color: AppTheme.primaryDark,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ),
                      Text(
                        timeText,
                        style: const TextStyle(
                          fontSize: 10,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ADD COMMENT + NOTIFICATION

  Future<void> _addComment(String postId, String comment) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      String commenterName =
          userName.isNotEmpty ? userName : 'Someone';

      final userDocument =
          await _firestore.collection('users').doc(user.uid).get();
      final storedName =
          userDocument.data()?['name']?.toString().trim();

      if (storedName != null && storedName.isNotEmpty) {
        commenterName = storedName;
      }

      final postReference = _firestore.collection('posts').doc(postId);
      final postSnapshot = await postReference.get();
      if (!postSnapshot.exists) return;

      final postData = postSnapshot.data();
      if (postData == null) return;

      final String authorId = postData['userId']?.toString() ?? '';

      await postReference.collection('comments').add({
        'userId': user.uid,
        'name': commenterName,
        'comment': comment,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await postReference.update({
        'comments': FieldValue.increment(1),
      });

      if (authorId.isNotEmpty && authorId != user.uid) {
        final String postTitle =
            postData['title']?.toString().trim() ?? '';

        try {
          await NotificationService.sendToUser(
            recipientId: authorId,
            title: 'New comment 💬',
            message: postTitle.isEmpty
                ? '$commenterName commented on your post.'
                : '$commenterName commented on "$postTitle".',
            type: 'comment',
            extraData: {
              'postId': postId,
              'actorId': user.uid,
            },
          );
        } catch (e) {
          debugPrint('COMMENT NOTIFICATION ERROR: $e');
        }
      }
    } catch (e) {
      debugPrint('COMMENT ERROR: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to add comment.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // DELETE POST DIALOG

  void _showDeletePostDialog(String postId) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this post?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(dialogContext);
                await _deletePost(postId);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  // DELETE POST

  Future<void> _deletePost(String postId) async {
    try {
      await _firestore.collection('posts').doc(postId).delete();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Post deleted.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('DELETE POST ERROR: $e');

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to delete post.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // TIME FORMAT

  String _formatTime(Timestamp timestamp) {
    final DateTime dateTime = timestamp.toDate();
    final Duration difference = DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) return 'Just now';

    if (difference.inMinutes < 60) {
      final int minutes = difference.inMinutes;
      return minutes == 1 ? '1 minute ago' : '$minutes minutes ago';
    }

    if (difference.inHours < 24) {
      final int hours = difference.inHours;
      return hours == 1 ? '1 hour ago' : '$hours hours ago';
    }

    if (difference.inDays == 1) return 'Yesterday';
    if (difference.inDays < 7) return '${difference.inDays} days ago';

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // ERROR STATE

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: const BoxDecoration(
                color: AppTheme.pastelPink,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 40,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Unable to load community',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            ElevatedButton.icon(
              onPressed: () => setState(() {}),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try Again'),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY STATE

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.only(top: 70, left: 15, right: 15),
      child: Column(
        children: [
          Container(
            width: 85,
            height: 85,
            decoration: const BoxDecoration(
              color: AppTheme.pastelGreen,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.forum_outlined,
              size: 42,
              color: AppTheme.primaryDark,
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'No posts yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Be the first person to share something with the community.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textGrey,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _showCreatePostDialog,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Create Post'),
          ),
        ],
      ),
    );
  }

  // NO COMMENTS STATE

  Widget _buildNoCommentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(
                color: AppTheme.pastelGreen,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chat_bubble_outline_rounded,
                size: 36,
                color: AppTheme.primaryDark,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No comments yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Be the first person to share your thoughts.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
