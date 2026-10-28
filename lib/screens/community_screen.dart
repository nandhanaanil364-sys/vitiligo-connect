import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../theme/app_theme.dart';

class CommunityScreen extends StatefulWidget {
  const CommunityScreen({super.key});

  @override
  State<CommunityScreen> createState() => _CommunityScreenState();
}

class _CommunityScreenState extends State<CommunityScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String currentUserName = 'You';

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
  }

  // ======================================================
  // LOAD CURRENT USER
  // ======================================================

  Future<void> _loadCurrentUser() async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      final document =
          await _firestore.collection('users').doc(user.uid).get();

      if (document.exists) {
        final data = document.data();

        final name = data?['name']?.toString().trim() ?? '';

        if (mounted && name.isNotEmpty) {
          setState(() {
            currentUserName = name;
          });
        }
      }
    } catch (e) {
      debugPrint('COMMUNITY USER ERROR: $e');
    }
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Community',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ),

      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreatePostDialog,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Create Post',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: _firestore
            .collection('posts')
            .where('status', isEqualTo: 'approved')
            .orderBy('createdAt', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          // =================================================
          // LOADING
          // =================================================

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppTheme.primaryDark,
              ),
            );
          }

          // =================================================
          // ERROR
          // =================================================

          if (snapshot.hasError) {
            debugPrint(
              'COMMUNITY FIRESTORE ERROR: ${snapshot.error}',
            );

            return _buildErrorState();
          }

          final documents = snapshot.data?.docs ?? [];

          // =================================================
          // EMPTY
          // =================================================

          if (documents.isEmpty) {
            return _buildEmptyState();
          }

          // =================================================
          // FEED
          // =================================================

          return ListView(
            padding: const EdgeInsets.fromLTRB(
              20,
              10,
              20,
              100,
            ),
            children: [
              _buildWelcomeCard(),

              const SizedBox(height: 24),

              const Text(
                'Community Feed',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 14),

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
    );
  }

  // ======================================================
  // WELCOME CARD
  // ======================================================

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pastelGreen,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 55,
            height: 55,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.groups_rounded,
              size: 30,
              color: AppTheme.primaryDark,
            ),
          ),

          const SizedBox(width: 14),

          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A space to connect',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),

                SizedBox(height: 5),

                Text(
                  'Share experiences, ask questions and support one another.',
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.4,
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

  // ======================================================
  // POST CARD
  // ======================================================

  Widget _buildPostCard(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final post = document.data();

    final String postId = document.id;

    final String name =
        post['name']?.toString() ?? 'Community Member';

    final String category =
        post['category']?.toString() ?? 'Experience';

    final String title =
        post['title']?.toString() ?? '';

    final String content =
        post['content']?.toString() ?? '';

    final int likes =
        (post['likes'] as num?)?.toInt() ?? 0;

    final int comments =
        (post['comments'] as num?)?.toInt() ?? 0;

    final String userId =
        post['userId']?.toString() ?? '';

    final bool isOwner =
        _auth.currentUser?.uid == userId;

    final Timestamp? createdAt =
        post['createdAt'] is Timestamp
            ? post['createdAt'] as Timestamp
            : null;

    final String timeText =
        createdAt != null
            ? _formatTime(createdAt)
            : 'Just now';

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _auth.currentUser == null
          ? null
          : _firestore
              .collection('posts')
              .doc(postId)
              .collection('likes')
              .doc(_auth.currentUser!.uid)
              .snapshots(),

      builder: (context, likeSnapshot) {
        final bool liked =
            likeSnapshot.data?.exists ?? false;

        return Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: const Color(0xFFE8ECE9),
            ),
          ),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // =================================================
              // USER DETAILS
              // =================================================

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
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
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

                  // CATEGORY

                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelYellow,
                      borderRadius:
                          BorderRadius.circular(20),
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

              // =================================================
              // TITLE
              // =================================================

              Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 7),

              // =================================================
              // CONTENT
              // =================================================

              Text(
                content,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.5,
                  color: AppTheme.textGrey,
                ),
              ),

              const SizedBox(height: 15),

              const Divider(
                height: 1,
                color: Color(0xFFE8ECE9),
              ),

              const SizedBox(height: 7),

              // =================================================
              // ACTIONS
              // =================================================

              Row(
                children: [

                  // LIKE

                  TextButton.icon(
                    onPressed: () {
                      _toggleLike(
                        postId,
                        liked,
                      );
                    },

                    icon: Icon(
                      liked
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      size: 21,
                      color: liked
                          ? Colors.redAccent
                          : AppTheme.textGrey,
                    ),

                    label: Text(
                      '$likes',
                      style: TextStyle(
                        color: liked
                            ? Colors.redAccent
                            : AppTheme.textGrey,
                      ),
                    ),
                  ),

                  const SizedBox(width: 5),

                  // COMMENT

                  TextButton.icon(
                    onPressed: () {
                      _showCommentsBottomSheet(postId);
                    },

                    icon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      size: 20,
                      color: AppTheme.textGrey,
                    ),

                    label: Text(
                      '$comments',
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // DELETE OWN POST

                  if (isOwner)
                    IconButton(
                      onPressed: () {
                        _showDeletePostDialog(postId);
                      },
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        color: AppTheme.textGrey,
                      ),
                    ),

                  // SHARE

                  IconButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context)
                          .showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Post sharing will be added later.',
                          ),
                          behavior:
                              SnackBarBehavior.floating,
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

  // ======================================================
  // CREATE POST
  // ======================================================

  void _showCreatePostDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    String selectedCategory = 'Experience';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Create Post',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),

              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [

                    // TITLE

                    TextField(
                      controller: titleController,
                      decoration: InputDecoration(
                        labelText: 'Post Title',
                        hintText: 'Enter a title',
                        prefixIcon: const Icon(
                          Icons.title_rounded,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CONTENT

                    TextField(
                      controller: contentController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: 'Your Post',
                        hintText:
                            'Share your thoughts...',
                        alignLabelWithHint: true,
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // CATEGORY

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,

                      decoration: InputDecoration(
                        labelText: 'Category',
                        prefixIcon: const Icon(
                          Icons.category_outlined,
                        ),
                        border: OutlineInputBorder(
                          borderRadius:
                              BorderRadius.circular(12),
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

                      onChanged: (value) {
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

                // CANCEL

                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text('Cancel'),
                ),

                // POST

                ElevatedButton(
                  onPressed: () async {
                    final title =
                        titleController.text.trim();

                    final content =
                        contentController.text.trim();

                    if (title.isEmpty ||
                        content.isEmpty) {
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

                    await _createPost(
                      title: title,
                      content: content,
                      category: selectedCategory,
                      dialogContext: dialogContext,
                    );
                  },

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                  ),

                  child: const Text('Post'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ======================================================
  // SAVE POST TO FIRESTORE
  // ======================================================

  Future<void> _createPost({
    required String title,
    required String content,
    required String category,
    required BuildContext dialogContext,
  }) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please login to create a post.',
            ),
          ),
        );

        return;
      }

      String name = currentUserName;

      final userDocument =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDocument.exists) {
        final data = userDocument.data();

        final storedName =
            data?['name']?.toString().trim() ?? '';

        if (storedName.isNotEmpty) {
          name = storedName;
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

        // Post needs admin approval

        'status': 'pending',
      });

      if (!mounted) return;

      Navigator.pop(dialogContext);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post submitted for approval! 🎉',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('CREATE POST ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to create post: $e',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ======================================================
  // LIKE / UNLIKE
  // ======================================================

  Future<void> _toggleLike(
    String postId,
    bool currentlyLiked,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      final postReference =
          _firestore.collection('posts').doc(postId);

      final likeReference =
          postReference
              .collection('likes')
              .doc(user.uid);

      if (currentlyLiked) {
        await likeReference.delete();

        await postReference.update({
          'likes': FieldValue.increment(-1),
        });
      } else {
        await likeReference.set({
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });

        await postReference.update({
          'likes': FieldValue.increment(1),
        });
      }
    } catch (e) {
      debugPrint('LIKE ERROR: $e');
    }
  }

  // ======================================================
  // COMMENTS BOTTOM SHEET
  // ======================================================

  void _showCommentsBottomSheet(String postId) {
    final commentController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,

      builder: (bottomSheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(bottomSheetContext)
                .viewInsets
                .bottom,
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

                // =================================================
                // HEADER
                // =================================================

                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    15,
                    10,
                    10,
                  ),

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
                        onPressed: () {
                          Navigator.pop(bottomSheetContext);
                        },
                        icon: const Icon(
                          Icons.close_rounded,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                  color: Color(0xFFE8ECE9),
                ),

                // =================================================
                // COMMENTS LIST
                // =================================================

                Expanded(
                  child: StreamBuilder<
                      QuerySnapshot<Map<String, dynamic>>>(
                    stream: _firestore
                        .collection('posts')
                        .doc(postId)
                        .collection('comments')
                        .orderBy(
                          'createdAt',
                          descending: false,
                        )
                        .snapshots(),

                    builder: (context, snapshot) {

                      // LOADING

                      if (snapshot.connectionState ==
                          ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryDark,
                          ),
                        );
                      }

                      // ERROR

                      if (snapshot.hasError) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(25),
                            child: Text(
                              'Unable to load comments.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppTheme.textGrey,
                              ),
                            ),
                          ),
                        );
                      }

                      final comments =
                          snapshot.data?.docs ?? [];

                      // EMPTY

                      if (comments.isEmpty) {
                        return _buildNoCommentsState();
                      }

                      // COMMENT LIST

                      return ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          20,
                          15,
                          20,
                          15,
                        ),

                        itemCount: comments.length,

                        itemBuilder: (context, index) {
                          final comment =
                              comments[index].data();

                          return _buildCommentItem(
                            comment,
                          );
                        },
                      );
                    },
                  ),
                ),

                // =================================================
                // ADD COMMENT
                // =================================================

                Container(
                  padding: const EdgeInsets.fromLTRB(
                    15,
                    10,
                    15,
                    15,
                  ),

                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(
                          alpha: 0.06,
                        ),
                        blurRadius: 10,
                        offset: const Offset(0, -3),
                      ),
                    ],
                  ),

                  child: Row(
                    crossAxisAlignment:
                        CrossAxisAlignment.end,
                    children: [

                      Expanded(
                        child: TextField(
                          controller: commentController,
                          maxLines: 3,
                          minLines: 1,

                          decoration: InputDecoration(
                            hintText:
                                'Write a comment...',
                            filled: true,
                            fillColor:
                                AppTheme.background,

                            contentPadding:
                                const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),

                            border: OutlineInputBorder(
                              borderRadius:
                                  BorderRadius.circular(22),
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
                            final comment =
                                commentController.text
                                    .trim();

                            if (comment.isEmpty) {
                              return;
                            }

                            await _addComment(
                              postId,
                              comment,
                              bottomSheetContext,
                            );

                            commentController.clear();
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
    );
  }

  // ======================================================
  // COMMENT ITEM
  // ======================================================

  Widget _buildCommentItem(
    Map<String, dynamic> comment,
  ) {
    final String name =
        comment['name']?.toString() ??
            'Community Member';

    final String text =
        comment['comment']?.toString() ?? '';

    final Timestamp? createdAt =
        comment['createdAt'] is Timestamp
            ? comment['createdAt'] as Timestamp
            : null;

    final String timeText =
        createdAt != null
            ? _formatTime(createdAt)
            : 'Just now';

    return Padding(
      padding: const EdgeInsets.only(
        bottom: 18,
      ),

      child: Row(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // AVATAR

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

          // COMMENT

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(13),

              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(15),
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,

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

  // ======================================================
  // NO COMMENTS
  // ======================================================

  Widget _buildNoCommentsState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

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
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ======================================================
  // ADD COMMENT
  // ======================================================

  Future<void> _addComment(
    String postId,
    String comment,
    BuildContext dialogContext,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      String name = currentUserName;

      final userDocument =
          await _firestore
              .collection('users')
              .doc(user.uid)
              .get();

      if (userDocument.exists) {
        final data = userDocument.data();

        final storedName =
            data?['name']?.toString().trim() ?? '';

        if (storedName.isNotEmpty) {
          name = storedName;
        }
      }

      final postReference =
          _firestore.collection('posts').doc(postId);

      // SAVE COMMENT

      await postReference
          .collection('comments')
          .add({
        'userId': user.uid,
        'name': name,
        'comment': comment,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      // UPDATE COMMENT COUNT

      await postReference.update({
        'comments': FieldValue.increment(1),
      });

    } catch (e) {
      debugPrint('COMMENT ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to add comment.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ======================================================
  // DELETE POST DIALOG
  // ======================================================

  void _showDeletePostDialog(String postId) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Post?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'Are you sure you want to delete this post?',
          ),

          actions: [

            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext);
              },
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

  // ======================================================
  // DELETE POST
  // ======================================================

  Future<void> _deletePost(String postId) async {
    try {
      await _firestore
          .collection('posts')
          .doc(postId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Post deleted.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('DELETE POST ERROR: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Unable to delete post.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ======================================================
  // TIME FORMAT
  // ======================================================

  String _formatTime(Timestamp timestamp) {
    final DateTime dateTime =
        timestamp.toDate();

    final Duration difference =
        DateTime.now().difference(dateTime);

    if (difference.inSeconds < 60) {
      return 'Just now';
    }

    if (difference.inMinutes < 60) {
      final int minutes =
          difference.inMinutes;

      return minutes == 1
          ? '1 minute ago'
          : '$minutes minutes ago';
    }

    if (difference.inHours < 24) {
      final int hours =
          difference.inHours;

      return hours == 1
          ? '1 hour ago'
          : '$hours hours ago';
    }

    if (difference.inDays == 1) {
      return 'Yesterday';
    }

    if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    }

    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }

  // ======================================================
  // ERROR STATE
  // ======================================================

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 90,
              height: 90,

              decoration: const BoxDecoration(
                color: AppTheme.pastelPink,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.cloud_off_rounded,
                size: 45,
                color: AppTheme.primaryDark,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'Unable to load community',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please check your internet connection and try again.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppTheme.textGrey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: () {
                setState(() {});
              },

              icon: const Icon(
                Icons.refresh_rounded,
              ),

              label: const Text(
                'Try Again',
              ),
            ),
          ],
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
        padding: const EdgeInsets.all(30),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [

            Container(
              width: 90,
              height: 90,

              decoration: const BoxDecoration(
                color: AppTheme.pastelGreen,
                shape: BoxShape.circle,
              ),

              child: const Icon(
                Icons.forum_outlined,
                size: 45,
                color: AppTheme.primaryDark,
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              'No posts yet',

              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Be the first person to share something with the community.',
              textAlign: TextAlign.center,

              style: TextStyle(
                color: AppTheme.textGrey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: _showCreatePostDialog,

              icon: const Icon(
                Icons.add,
              ),

              label: const Text(
                'Create Post',
              ),
            ),
          ],
        ),
      ),
    );
  }
}