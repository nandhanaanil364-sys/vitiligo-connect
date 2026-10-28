import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class LearnScreen extends StatelessWidget {
  const LearnScreen({super.key});

static final FirebaseFirestore _firestore =
    FirebaseFirestore.instance;
    
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Learn',
          style: TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('educationalResources')
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
              child: CircularProgressIndicator(),
            );
          }

          // Error
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 55,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Unable to load resources',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final resources =
              snapshot.data?.docs ?? [];

          // No resources
          if (resources.isEmpty) {
            return ListView(
              padding: const EdgeInsets.all(24),
              children: [
                SizedBox(
                  height:
                      MediaQuery.of(context).size.height *
                          0.15,
                ),
                const Icon(
                  Icons.menu_book_outlined,
                  size: 70,
                  color: AppTheme.primary,
                ),
                const SizedBox(height: 20),
                const Text(
                  'No Resources Available Yet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textDark,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Educational resources approved by our team will appear here.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: AppTheme.textGrey,
                    height: 1.5,
                  ),
                ),
              ],
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ------------------------------------------------
              // HEADER
              // ------------------------------------------------

              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.pastelGreen,
                  borderRadius:
                      BorderRadius.circular(20),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 36,
                      color: AppTheme.primaryDark,
                    ),
                    SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Learn About Vitiligo',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.textDark,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Reliable educational content from verified professionals.',
                            style: TextStyle(
                              color: AppTheme.textGrey,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                'Educational Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 14),

              // ------------------------------------------------
              // RESOURCE LIST
              // ------------------------------------------------

              ...resources.map(
                (doc) {
                  final data =
                      doc.data() as Map<String, dynamic>;

                  return _resourceCard(
                    context,
                    data,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  // ==========================================================
  // RESOURCE CARD
  // ==========================================================

  Widget _resourceCard(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final title =
        data['title'] ?? 'Untitled Resource';

    final category =
        data['category'] ?? 'General';

    final content =
        data['content'] ?? '';

    final expertName =
        data['expertName'] ?? 'Verified Professional';

    final expertType =
        data['expertType'] ?? 'Expert';

    String preview = content.toString();

    if (preview.length > 150) {
      preview =
          '${preview.substring(0, 150)}...';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius:
            BorderRadius.circular(18),
        onTap: () {
          _showResource(
            context,
            data,
          );
        },
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
                  Container(
                    padding:
                        const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                          AppTheme.pastelBlue,
                      borderRadius:
                          BorderRadius.circular(
                        14,
                      ),
                    ),
                    child: const Icon(
                      Icons.menu_book_outlined,
                      color:
                          AppTheme.primaryDark,
                      size: 27,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          title.toString(),
                          style:
                              const TextStyle(
                            fontSize: 17,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(
                          height: 6,
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
                            color: AppTheme
                                .pastelYellow,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              20,
                            ),
                          ),
                          child: Text(
                            category.toString(),
                            style:
                                const TextStyle(
                              fontSize: 12,
                              fontWeight:
                                  FontWeight.w600,
                              color:
                                  AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              Text(
                preview.isEmpty
                    ? 'No content available.'
                    : preview,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.textGrey,
                  height: 1.5,
                ),
              ),

              const SizedBox(height: 15),

              Row(
                children: [
                  const Icon(
                    Icons.verified_outlined,
                    size: 18,
                    color: AppTheme.primaryDark,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      '$expertName • $expertType',
                      style:
                          const TextStyle(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w600,
                        color:
                            AppTheme.primaryDark,
                      ),
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios,
                    size: 15,
                    color:
                        AppTheme.textGrey,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ==========================================================
  // FULL RESOURCE VIEW
  // ==========================================================

  void _showResource(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final title =
        data['title'] ?? 'Untitled Resource';

    final category =
        data['category'] ?? 'General';

    final content =
        data['content'] ?? '';

    final expertName =
        data['expertName'] ??
            'Verified Professional';

    final expertType =
        data['expertType'] ?? 'Expert';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height:
              MediaQuery.of(context).size.height *
                  0.85,
          decoration: const BoxDecoration(
            color: AppTheme.background,
            borderRadius:
                BorderRadius.vertical(
              top: Radius.circular(28),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Handle
                const SizedBox(height: 10),
                Container(
                  width: 45,
                  height: 5,
                  decoration:
                      BoxDecoration(
                    color:
                        Color(0xFFD5DCD8),
                    borderRadius:
                        BorderRadius.circular(
                      10,
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // Header
                Padding(
                  padding:
                      const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Container(
                        padding:
                            const EdgeInsets
                                .all(12),
                        decoration:
                            BoxDecoration(
                          color: AppTheme
                              .pastelBlue,
                          borderRadius:
                              BorderRadius
                                  .circular(
                            14,
                          ),
                        ),
                        child: const Icon(
                          Icons
                              .menu_book_outlined,
                          color: AppTheme
                              .primaryDark,
                        ),
                      ),
                      const SizedBox(
                        width: 14,
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment
                                  .start,
                          children: [
                            Text(
                              title.toString(),
                              style:
                                  const TextStyle(
                                fontSize: 20,
                                fontWeight:
                                    FontWeight
                                        .bold,
                                color: AppTheme
                                    .textDark,
                              ),
                            ),
                            const SizedBox(
                              height: 6,
                            ),
                            Text(
                              category.toString(),
                              style:
                                  const TextStyle(
                                color: AppTheme
                                    .primaryDark,
                                fontWeight:
                                    FontWeight
                                        .w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () {
                          Navigator.pop(
                            context,
                          );
                        },
                        icon: const Icon(
                          Icons.close,
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(
                  height: 1,
                ),

                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(
                      20,
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment
                              .start,
                      children: [
                        Container(
                          width:
                              double.infinity,
                          padding:
                              const EdgeInsets
                                  .all(16),
                          decoration:
                              BoxDecoration(
                            color: AppTheme
                                .pastelGreen,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons
                                    .verified,
                                color: AppTheme
                                    .primaryDark,
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'Reviewed by $expertName ($expertType)',
                                  style:
                                      const TextStyle(
                                    fontSize: 13,
                                    fontWeight:
                                        FontWeight
                                            .w600,
                                    color: AppTheme
                                        .textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(
                          height: 24,
                        ),

                        Text(
                          content.toString(),
                          style:
                              const TextStyle(
                            fontSize: 16,
                            height: 1.7,
                            color:
                                AppTheme
                                    .textDark,
                          ),
                        ),

                        const SizedBox(
                          height: 30,
                        ),

                        Container(
                          padding:
                              const EdgeInsets
                                  .all(16),
                          decoration:
                              BoxDecoration(
                            color: AppTheme
                                .pastelYellow,
                            borderRadius:
                                BorderRadius
                                    .circular(
                              16,
                            ),
                          ),
                          child: const Row(
                            crossAxisAlignment:
                                CrossAxisAlignment
                                    .start,
                            children: [
                              Icon(
                                Icons
                                    .info_outline,
                                color: AppTheme
                                    .textDark,
                              ),
                              SizedBox(
                                width: 10,
                              ),
                              Expanded(
                                child: Text(
                                  'This content is provided for educational purposes and does not replace professional medical advice.',
                                  style:
                                      TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: AppTheme
                                        .textDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}