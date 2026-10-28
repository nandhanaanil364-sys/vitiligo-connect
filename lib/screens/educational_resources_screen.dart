import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
import 'add_resource_screen.dart';

class EducationalResourcesScreen extends StatefulWidget {
  const EducationalResourcesScreen({super.key});

  @override
  State<EducationalResourcesScreen> createState() =>
      _EducationalResourcesScreenState();
}

class _EducationalResourcesScreenState
    extends State<EducationalResourcesScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  // ======================================================
  // CHECK WHETHER CURRENT USER IS AN EXPERT
  // ======================================================

  Future<bool> _isExpert() async {
    final user = _auth.currentUser;

    if (user == null) return false;

    final expertDocument = await _firestore
        .collection('experts')
        .doc(user.uid)
        .get();

    return expertDocument.exists;
  }

  // ======================================================
  // DELETE RESOURCE
  // ======================================================

  Future<void> _deleteResource(
      String resourceId) async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      await _firestore
          .collection('educationalResources')
          .doc(resourceId)
          .delete();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Resource deleted successfully.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(
        'RESOURCE: Delete error: $e',
      );
    }
  }

  // ======================================================
  // CATEGORY ICON
  // ======================================================

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Awareness':
        return Icons.info_outline_rounded;

      case 'Treatment':
        return Icons.medical_services_outlined;

      case 'Skin Care':
        return Icons.spa_outlined;

      case 'Mental Health':
        return Icons.psychology_outlined;

      case 'Lifestyle':
        return Icons.favorite_outline_rounded;

      case 'Nutrition':
        return Icons.restaurant_outlined;

      case 'FAQ':
        return Icons.help_outline_rounded;

      default:
        return Icons.menu_book_outlined;
    }
  }

  // ======================================================
  // CATEGORY COLOR
  // ======================================================

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Awareness':
        return AppTheme.pastelBlue;

      case 'Treatment':
        return AppTheme.pastelGreen;

      case 'Skin Care':
        return AppTheme.pastelYellow;

      case 'Mental Health':
        return AppTheme.pastelPink;

      case 'Lifestyle':
        return AppTheme.pastelGreen;

      case 'Nutrition':
        return AppTheme.pastelYellow;

      case 'FAQ':
        return AppTheme.pastelBlue;

      default:
        return AppTheme.pastelGreen;
    }
  }

  // ======================================================
  // ADD RESOURCE
  // ======================================================

  Future<void> _openAddResource() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const AddResourceScreen(),
      ),
    );
  }

  // ======================================================
  // BUILD
  // ======================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        appBar: AppBar(
          title: const Text(
            'Educational Resources',
          ),
        ),
        body: const Center(
          child: Text(
            'Please login to continue.',
          ),
        ),
      );
    }

    return FutureBuilder<bool>(
      future: _isExpert(),
      builder: (context, expertSnapshot) {
        final bool isExpert =
            expertSnapshot.data ?? false;

        return Scaffold(
          backgroundColor:
              AppTheme.background,

          // ==================================================
          // APP BAR
          // ==================================================

          appBar: AppBar(
            backgroundColor:
                AppTheme.background,
            elevation: 0,

            title: const Text(
              'Educational Resources',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),
          ),

          // ==================================================
          // RESOURCE LIST
          // ==================================================

          body: StreamBuilder<
              QuerySnapshot<
                  Map<String, dynamic>>>(
            stream: isExpert
                ? _firestore
                    .collection(
                        'educationalResources')
                    .where(
                      'expertId',
                      isEqualTo: user.uid,
                    )
                    .snapshots()
                : _firestore
                    .collection(
                        'educationalResources')
                    .where(
                      'status',
                      isEqualTo: 'approved',
                    )
                    .snapshots(),

            builder: (context, snapshot) {
              // Loading
              if (snapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child:
                      CircularProgressIndicator(),
                );
              }

              // Error
              if (snapshot.hasError) {
                return Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(25),
                    child: Text(
                      'Unable to load resources.\n\n'
                      '${snapshot.error}',
                      textAlign:
                          TextAlign.center,
                      style:
                          const TextStyle(
                        color:
                            AppTheme.textGrey,
                      ),
                    ),
                  ),
                );
              }

              final documents =
                  snapshot.data?.docs ?? [];

              // Sort by createdAt
              documents.sort((a, b) {
                final Timestamp? timeA =
                    a.data()['createdAt']
                            is Timestamp
                        ? a.data()['createdAt']
                            as Timestamp
                        : null;

                final Timestamp? timeB =
                    b.data()['createdAt']
                            is Timestamp
                        ? b.data()['createdAt']
                            as Timestamp
                        : null;

                if (timeA == null &&
                    timeB == null) {
                  return 0;
                }

                if (timeA == null) {
                  return 1;
                }

                if (timeB == null) {
                  return -1;
                }

                return timeB
                    .compareTo(timeA);
              });

              // Empty state
              if (documents.isEmpty) {
                return _buildEmptyState(
                  isExpert,
                );
              }

              return ListView.builder(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                itemCount:
                    documents.length,
                itemBuilder:
                    (context, index) {
                  final document =
                      documents[index];

                  final data =
                      document.data();

                  return _buildResourceCard(
                    documentId:
                        document.id,
                    data: data,
                    isExpert:
                        isExpert,
                  );
                },
              );
            },
          ),

          // ==================================================
          // ADD RESOURCE BUTTON
          // ==================================================

          floatingActionButton: isExpert
              ? FloatingActionButton.extended(
                  onPressed:
                      _openAddResource,
                  backgroundColor:
                      AppTheme.primary,
                  foregroundColor:
                      Colors.white,
                  icon: const Icon(
                    Icons.add,
                  ),
                  label: const Text(
                    'Add Resource',
                  ),
                )
              : null,
        );
      },
    );
  }

  // ======================================================
  // RESOURCE CARD
  // ======================================================

  Widget _buildResourceCard({
    required String documentId,
    required Map<String, dynamic> data,
    required bool isExpert,
  }) {
    final String title =
        data['title']?.toString() ??
            'Untitled Resource';

    final String category =
        data['category']?.toString() ??
            'General';

    final String description =
        data['shortDescription']
                ?.toString() ??
            '';

    final String content =
        data['content']?.toString() ??
            '';

    final String status =
        data['status']?.toString() ??
            'pending';

    final String expertName =
        data['expertName']?.toString() ??
            '';

    final bool isApproved =
        status == 'approved';

    return GestureDetector(
      onTap: () {
        _showResourceDetails(
          title: title,
          category: category,
          description: description,
          content: content,
          expertName: expertName,
        );
      },

      child: Container(
        margin:
            const EdgeInsets.only(bottom: 14),

        padding:
            const EdgeInsets.all(16),

        decoration: BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(18),

          border: Border.all(
            color:
                const Color(0xFFE6EBE7),
          ),
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Row(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [
                // ICON
                Container(
                  width: 48,
                  height: 48,

                  decoration:
                      BoxDecoration(
                    color:
                        _getCategoryColor(
                            category),
                    shape:
                        BoxShape.circle,
                  ),

                  child: Icon(
                    _getCategoryIcon(
                        category),
                    color:
                        AppTheme.primaryDark,
                    size: 24,
                  ),
                ),

                const SizedBox(width: 13),

                // TITLE
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        title,

                        style:
                            const TextStyle(
                          fontSize: 16,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppTheme.textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 5,
                      ),

                      Text(
                        category,

                        style:
                            const TextStyle(
                          fontSize: 12,
                          color:
                              AppTheme
                                  .primaryDark,
                          fontWeight:
                              FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // STATUS FOR EXPERT
                if (isExpert)
                  _buildStatusBadge(
                    status,
                  ),
              ],
            ),

            const SizedBox(height: 12),

            Text(
              description,

              maxLines: 3,
              overflow:
                  TextOverflow.ellipsis,

              style:
                  const TextStyle(
                fontSize: 13,
                height: 1.4,
                color:
                    AppTheme.textGrey,
              ),
            ),

            if (expertName.isNotEmpty &&
                !isExpert) ...[
              const SizedBox(height: 10),

              Row(
                children: [
                  const Icon(
                    Icons
                        .verified_outlined,
                    size: 16,
                    color:
                        AppTheme.primaryDark,
                  ),

                  const SizedBox(
                    width: 5,
                  ),

                  Text(
                    'By $expertName',

                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ],

            // DELETE OPTION FOR EXPERT
            if (isExpert) ...[
              const SizedBox(height: 12),

              Align(
                alignment:
                    Alignment.centerRight,

                child: TextButton.icon(
                  onPressed: () {
                    _showDeleteConfirmation(
                      documentId,
                    );
                  },

                  icon: const Icon(
                    Icons
                        .delete_outline_rounded,
                    size: 18,
                  ),

                  label: const Text(
                    'Delete',
                  ),

                  style:
                      TextButton.styleFrom(
                    foregroundColor:
                        Colors.redAccent,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ======================================================
  // STATUS BADGE
  // ======================================================

  Widget _buildStatusBadge(
      String status) {
    String text;
    Color background;
    Color foreground;

    switch (status) {
      case 'approved':
        text = 'Approved';
        background =
            AppTheme.pastelGreen;
        foreground =
            AppTheme.primaryDark;
        break;

      case 'rejected':
        text = 'Rejected';
        background =
            const Color(0xFFFFE0E0);
        foreground =
            Colors.red.shade700;
        break;

      default:
        text = 'Pending';
        background =
            AppTheme.pastelYellow;
        foreground =
            Colors.orange.shade800;
    }

    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 9,
        vertical: 5,
      ),

      decoration: BoxDecoration(
        color: background,
        borderRadius:
            BorderRadius.circular(20),
      ),

      child: Text(
        text,

        style: TextStyle(
          fontSize: 10,
          fontWeight:
              FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }

  // ======================================================
  // RESOURCE DETAILS
  // ======================================================

  void _showResourceDetails({
    required String title,
    required String category,
    required String description,
    required String content,
    required String expertName,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,

      backgroundColor:
          Colors.transparent,

      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context)
                      .size
                      .height *
                  0.82,

          decoration:
              const BoxDecoration(
            color: Colors.white,

            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(25),
            ),
          ),

          child: Column(
            children: [
              const SizedBox(height: 12),

              Container(
                width: 45,
                height: 5,

                decoration:
                    BoxDecoration(
                  color:
                      const Color(
                    0xFFD9DFDB,
                  ),

                  borderRadius:
                      BorderRadius.circular(
                    10,
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding:
                      const EdgeInsets.all(
                    22,
                  ),

                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,

                    children: [
                      Text(
                        title,

                        style:
                            const TextStyle(
                          fontSize: 23,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppTheme
                                  .textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 8,
                      ),

                      Container(
                        padding:
                            const EdgeInsets
                                .symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),

                        decoration:
                            BoxDecoration(
                          color:
                              AppTheme
                                  .pastelGreen,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            20,
                          ),
                        ),

                        child: Text(
                          category,

                          style:
                              const TextStyle(
                            fontSize: 12,
                            fontWeight:
                                FontWeight
                                    .w600,
                            color:
                                AppTheme
                                    .primaryDark,
                          ),
                        ),
                      ),

                      const SizedBox(
                        height: 20,
                      ),

                      Text(
                        description,

                        style:
                            const TextStyle(
                          fontSize: 15,
                          height: 1.5,
                          fontWeight:
                              FontWeight.w500,
                          color:
                              AppTheme
                                  .textDark,
                        ),
                      ),

                      const SizedBox(
                        height: 18,
                      ),

                      const Divider(),

                      const SizedBox(
                        height: 18,
                      ),

                      Text(
                        content,

                        style:
                            const TextStyle(
                          fontSize: 14,
                          height: 1.7,
                          color:
                              AppTheme
                                  .textGrey,
                        ),
                      ),

                      if (expertName
                          .isNotEmpty) ...[
                        const SizedBox(
                          height: 25,
                        ),

                        Row(
                          children: [
                            const Icon(
                              Icons
                                  .verified_outlined,
                              color: AppTheme
                                  .primaryDark,
                            ),

                            const SizedBox(
                              width: 7,
                            ),

                            Text(
                              'Written by $expertName',

                              style:
                                  const TextStyle(
                                fontSize: 13,
                                fontWeight:
                                    FontWeight
                                        .w600,
                                color:
                                    AppTheme
                                        .textDark,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ======================================================
  // DELETE CONFIRMATION
  // ======================================================

  void _showDeleteConfirmation(
      String documentId) {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          title: const Text(
            'Delete Resource?',
          ),

          content: const Text(
            'Are you sure you want to delete this educational resource?',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () {
                Navigator.pop(context);

                _deleteResource(
                  documentId,
                );
              },

              child: const Text(
                'Delete',
                style: TextStyle(
                  color:
                      Colors.redAccent,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ======================================================
  // EMPTY STATE
  // ======================================================

  Widget _buildEmptyState(
      bool isExpert) {
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
                shape:
                    BoxShape.circle,
              ),

              child: const Icon(
                Icons.menu_book_rounded,
                size: 45,
                color:
                    AppTheme.primaryDark,
              ),
            ),

            const SizedBox(height: 20),

            Text(
              isExpert
                  ? 'No resources yet'
                  : 'No resources available',

              style:
                  const TextStyle(
                fontSize: 21,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            Text(
              isExpert
                  ? 'Add an educational resource to share helpful information with the community.'
                  : 'Approved educational resources will appear here.',

              textAlign:
                  TextAlign.center,

              style:
                  const TextStyle(
                color:
                    AppTheme.textGrey,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}