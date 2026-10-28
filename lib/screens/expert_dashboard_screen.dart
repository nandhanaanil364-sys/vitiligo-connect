import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/event_model.dart';
import '../theme/app_theme.dart';
import 'create_event_screen.dart';
import 'event_participants_screen.dart';
import 'login_screen.dart';
import 'collaboration_requests_screen.dart';


class ExpertDashboardScreen extends StatefulWidget {
  final String expertName;
  final String expertType;

  const ExpertDashboardScreen({
    super.key,
    required this.expertName,
    required this.expertType,
  });

  @override
  State<ExpertDashboardScreen> createState() =>
      _ExpertDashboardScreenState();
}

class _ExpertDashboardScreenState
    extends State<ExpertDashboardScreen> {
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  final FirebaseAuth _auth =
      FirebaseAuth.instance;

  bool isLoading = false;

  // =========================================================
  // ADD EDUCATIONAL RESOURCE
  // =========================================================

  void _showAddResourceDialog() {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    String selectedCategory = 'Awareness';

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                'Add Educational Resource',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Create an educational resource for the Vitiligo Connect community.',
                      style: TextStyle(
                        color: AppTheme.textGrey,
                        height: 1.4,
                      ),
                    ),

                    const SizedBox(height: 20),

                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Enter resource title',
                        prefixIcon:
                            Icon(Icons.title_rounded),
                      ),
                    ),

                    const SizedBox(height: 15),

                    DropdownButtonFormField<String>(
                      initialValue: selectedCategory,
                      decoration:
                          const InputDecoration(
                        labelText: 'Category',
                        prefixIcon:
                            Icon(Icons.category_outlined),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Awareness',
                          child: Text('Awareness'),
                        ),
                        DropdownMenuItem(
                          value: 'Treatment',
                          child: Text('Treatment'),
                        ),
                        DropdownMenuItem(
                          value: 'Skin Care',
                          child: Text('Skin Care'),
                        ),
                        DropdownMenuItem(
                          value: 'Mental Health',
                          child: Text('Mental Health'),
                        ),
                        DropdownMenuItem(
                          value: 'Lifestyle',
                          child: Text('Lifestyle'),
                        ),
                        DropdownMenuItem(
                          value: 'Myths & Facts',
                          child: Text('Myths & Facts'),
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

                    const SizedBox(height: 15),

                    TextField(
                      controller: contentController,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Content',
                        hintText:
                            'Write the educational content here...',
                        alignLabelWithHint: true,
                        prefixIcon: Padding(
                          padding:
                              EdgeInsets.only(bottom: 90),
                          child: Icon(
                            Icons.article_outlined,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(dialogContext);
                  },
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: isLoading
                      ? null
                      : () async {
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
                                  'Please enter both title and content.',
                                ),
                              ),
                            );
                            return;
                          }

                          await _submitResource(
                            dialogContext,
                            title,
                            selectedCategory,
                            content,
                          );
                        },
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Submit'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =========================================================
  // SUBMIT RESOURCE
  // =========================================================

  Future<void> _submitResource(
    BuildContext dialogContext,
    String title,
    String category,
    String content,
  ) async {
    final user = _auth.currentUser;

    if (user == null) return;

    setState(() {
      isLoading = true;
    });

    try {
      final expertDoc = await _firestore
          .collection('experts')
          .doc(user.uid)
          .get();

      final expertData =
          expertDoc.data() ?? {};

      final expertName =
          expertData['name']?.toString() ??
              widget.expertName;

      final expertType =
          expertData['expertType']?.toString() ??
              widget.expertType;

      await _firestore
          .collection('educationalResources')
          .add({
        'title': title,
        'category': category,
        'content': content,
        'expertId': user.uid,
        'expertName': expertName,
        'expertType': expertType,
        'status': 'pending',
        'createdAt':
            FieldValue.serverTimestamp(),
        'updatedAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      Navigator.pop(dialogContext);

      setState(() {
        isLoading = false;
      });

      _showSuccessMessage(
        'Resource submitted successfully. It is now waiting for admin approval.',
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Unable to submit resource: $e',
          ),
        ),
      );
    }
  }

  // =========================================================
  // SHOW SUCCESS MESSAGE
  // =========================================================

  void _showSuccessMessage(String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: AppTheme.primaryDark,
              ),
              SizedBox(width: 10),
              Text(
                'Submitted',
                style: TextStyle(
                  color: AppTheme.textDark,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(
              color: AppTheme.textGrey,
              height: 1.5,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text(
                'OK',
                style: TextStyle(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // =========================================================
  // VIEW MY RESOURCES
  // =========================================================

  void _showMyResources() {
    final user = _auth.currentUser;

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.80,
          child: Column(
            children: [
              const SizedBox(height: 15),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'My Educational Resources',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _firestore
                      .collection(
                          'educationalResources')
                      .where(
                        'expertId',
                        isEqualTo: user.uid,
                      )
                      .snapshots(),
                  builder:
                      (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(
                                  20),
                          child: Text(
                            'Unable to load resources.\n\n${snapshot.error}',
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

                    if (documents.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.article_outlined,
                              size: 60,
                              color:
                                  AppTheme.textGrey,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'No resources yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Add your first educational resource.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.all(20),
                      itemCount:
                          documents.length,
                      itemBuilder:
                          (context, index) {
                        final data =
                            documents[index].data();

                        return _ResourceCard(
                          title:
                              data['title']
                                      ?.toString() ??
                                  'Untitled',
                          category:
                              data['category']
                                      ?.toString() ??
                                  'General',
                          status:
                              data['status']
                                      ?.toString() ??
                                  'pending',
                          content:
                              data['content']
                                      ?.toString() ??
                                  '',
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // OPEN CREATE EVENT SCREEN
  // =========================================================

  void _openCreateEventScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const CreateEventScreen(),
      ),
    );
  }

  // =========================================================
  // VIEW MY EVENTS
  // =========================================================

  void _showMyEvents() {
    final user = _auth.currentUser;

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.80,
          child: Column(
            children: [
              const SizedBox(height: 15),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'My Events',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('events')
                      .where(
                        'expertId',
                        isEqualTo: user.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Text(
                            'Unable to load your events.\n\n${snapshot.error}',
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

                    if (documents.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.event_outlined,
                              size: 60,
                              color:
                                  AppTheme.textGrey,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'No events yet',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 5),
                            Text(
                              'Events you create will appear here.',
                              textAlign:
                                  TextAlign.center,
                              style: TextStyle(
                                color:
                                    AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.all(20),
                      itemCount:
                          documents.length,
                      itemBuilder:
                          (context, index) {
                        final document =
                            documents[index];

                        final event =
                            Event.fromMap(
                          document.id,
                          document.data(),
                        );

                        return _MyEventCard(
                          event: event,
                          onTap: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EventParticipantsScreen(
                                  event: event,
                                ),
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // QUESTIONS FROM USERS
  // =========================================================

  void _showUserQuestions() {
    final user = _auth.currentUser;

    if (user == null) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(25),
        ),
      ),
      builder: (context) {
        return SizedBox(
          height:
              MediaQuery.of(context).size.height *
                  0.85,
          child: Column(
            children: [
              const SizedBox(height: 15),

              Container(
                width: 45,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius:
                      BorderRadius.circular(10),
                ),
              ),

              const SizedBox(height: 20),

              const Text(
                'Questions from Users',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 5),

              const Padding(
                padding:
                    EdgeInsets.symmetric(
                  horizontal: 20,
                ),
                child: Text(
                  'Answer questions submitted by users who selected you.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textGrey,
                  ),
                ),
              ),

              const SizedBox(height: 15),

              Expanded(
                child: StreamBuilder<
                    QuerySnapshot<
                        Map<String, dynamic>>>(
                  stream: _firestore
                      .collection('expertQuestions')
                      .where(
                        'expertId',
                        isEqualTo: user.uid,
                      )
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState ==
                        ConnectionState.waiting) {
                      return const Center(
                        child:
                            CircularProgressIndicator(),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Padding(
                          padding:
                              const EdgeInsets.all(20),
                          child: Text(
                            'Unable to load questions.\n\n${snapshot.error}',
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

                    final allDocuments =
                        snapshot.data?.docs ?? [];

                    // Only show pending questions.
                    final documents =
                        allDocuments.where((doc) {
                      final data = doc.data();

                      return data['status']
                              ?.toString() ==
                          'pending';
                    }).toList();

                    if (documents.isEmpty) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.question_answer_outlined,
                              size: 65,
                              color:
                                  AppTheme.textGrey,
                            ),
                            SizedBox(height: 15),
                            Text(
                              'No pending questions',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight:
                                    FontWeight.w600,
                                color:
                                    AppTheme.textDark,
                              ),
                            ),
                            SizedBox(height: 6),
                            Padding(
                              padding:
                                  EdgeInsets.symmetric(
                                horizontal: 30,
                              ),
                              child: Text(
                                'Questions from users will appear here when they ask you something.',
                                textAlign:
                                    TextAlign.center,
                                style: TextStyle(
                                  color:
                                      AppTheme.textGrey,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      padding:
                          const EdgeInsets.all(20),
                      itemCount:
                          documents.length,
                      itemBuilder:
                          (context, index) {
                        final document =
                            documents[index];

                        final data =
                            document.data();

                        return _QuestionCard(
                          questionId:
                              document.id,
                          userName:
                              data['userName']
                                      ?.toString() ??
                                  'User',
                          userEmail:
                              data['userEmail']
                                      ?.toString() ??
                                  '',
                          question:
                              data['question']
                                      ?.toString() ??
                                  '',
                          createdAt:
                              data['createdAt'],
                          onAnswered: () {},
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // =========================================================
  // LOGOUT
  // =========================================================

  Future<void> _logout() async {
    await _auth.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            const LoginScreen(),
      ),
      (route) => false,
    );
  }

  // =========================================================
  // BUILD
  // =========================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'Expert Dashboard',
          style: TextStyle(
            color: AppTheme.textDark,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            onPressed: _logout,
            tooltip: 'Logout',
            icon: const Icon(
              Icons.logout_rounded,
              color: AppTheme.textDark,
            ),
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding:
            const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // WELCOME CARD
            // =================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(22),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.pastelGreen,
                borderRadius:
                    BorderRadius.circular(22),
              ),
              child: Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration:
                        const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons
                          .medical_services_outlined,
                      color:
                          AppTheme.primaryDark,
                      size: 30,
                    ),
                  ),

                  const SizedBox(width: 15),

                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome, ${widget.expertName}',
                          style:
                              const TextStyle(
                            fontSize: 19,
                            fontWeight:
                                FontWeight.bold,
                            color:
                                AppTheme.textDark,
                          ),
                        ),

                        const SizedBox(height: 5),

                        Text(
                          widget.expertType,
                          style:
                              const TextStyle(
                            fontSize: 14,
                            color:
                                AppTheme.primaryDark,
                            fontWeight:
                                FontWeight.w600,
                          ),
                        ),

                        const SizedBox(height: 4),

                        const Row(
                          children: [
                            Icon(
                              Icons.verified,
                              size: 15,
                              color:
                                  AppTheme.primaryDark,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Verified Expert',
                              style:
                                  TextStyle(
                                fontSize: 12,
                                color:
                                    AppTheme.textGrey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            const Text(
              'Professional Tools',
              style: TextStyle(
                fontSize: 21,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 15),

            // =================================================
            // EDUCATIONAL RESOURCES
            // =================================================

            _DashboardOption(
              icon:
                  Icons.menu_book_rounded,
              title:
                  'Educational Resources',
              subtitle:
                  'Create and manage educational content',
              color:
                  AppTheme.pastelBlue,
              onTap:
                  _showMyResources,
            ),

            const SizedBox(height: 12),

            // =================================================
            // ADD RESOURCE
            // =================================================

            _DashboardOption(
              icon:
                  Icons.add_circle_outline_rounded,
              title:
                  'Add Educational Resource',
              subtitle:
                  'Submit a new article for users',
              color:
                  AppTheme.pastelYellow,
              onTap:
                  _showAddResourceDialog,
            ),

            const SizedBox(height: 12),

            // =================================================
            // QUESTIONS FROM USERS
            // =================================================

            _DashboardOption(
              icon:
                  Icons.question_answer_outlined,
              title:
                  'Questions from Users',
              subtitle:
                  'View and answer questions sent to you',
              color:
                  AppTheme.pastelPink,
              onTap:
                  _showUserQuestions,
            ),

            const SizedBox(height: 12),

            // =================================================
            // CREATE EVENT
            // =================================================

            _DashboardOption(
              icon:
                  Icons.event_available_outlined,
              title:
                  'Create Event',
              subtitle:
                  'Submit an event for the community',
              color:
                  AppTheme.pastelGreen,
              onTap:
                  _openCreateEventScreen,
            ),

            const SizedBox(height: 12),

            // =================================================
            // MY EVENTS
            // =================================================

            _DashboardOption(
              icon:
                  Icons.people_alt_outlined,
              title:
                  'My Events',
              subtitle:
                  'View events and registered participants',
              color:
                  AppTheme.pastelBlue,
              onTap:
                  _showMyEvents,
            ),

            const SizedBox(height: 12),

            // =================================================
            // COLLABORATION REQUESTS
            // =================================================

            _DashboardOption(
              icon:
                  Icons.handshake_outlined,
              title:
                  'Collaboration Requests',
              subtitle:
                  'Review event proposals from collaborators',
              color:
                  AppTheme.pastelYellow,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        const CollaborationRequestsScreen(),
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            // =================================================
            // PROFILE
            // =================================================

            _DashboardOption(
              icon:
                  Icons.person_outline_rounded,
              title:
                  'Professional Profile',
              subtitle:
                  'View your registered professional details',
              color:
                  AppTheme.pastelPink,
              onTap: () {
                _showProfile();
              },
            ),

            const SizedBox(height: 12),

            

            

            // =================================================
            // INFORMATION
            // =================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(18),
              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(18),
                border: Border.all(
                  color:
                      const Color(0xFFE8ECE9),
                ),
              ),
              child: const Row(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    color:
                        AppTheme.primaryDark,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Educational resources and events submitted by experts are reviewed by an administrator before becoming visible to users.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color:
                            AppTheme.textGrey,
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
  }

  // =========================================================
  // PROFILE
  // =========================================================

  Future<void> _showProfile() async {
    final user = _auth.currentUser;

    if (user == null) return;

    try {
      final doc = await _firestore
          .collection('experts')
          .doc(user.uid)
          .get();

      final data =
          doc.data() ?? {};

      if (!mounted) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor:
            AppTheme.background,
        shape:
            const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(
            top: Radius.circular(25),
          ),
        ),
        builder: (context) {
          return Padding(
            padding:
                const EdgeInsets.all(24),
            child:
                SingleChildScrollView(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 70,
                      height: 70,
                      decoration:
                          const BoxDecoration(
                        color:
                            AppTheme.pastelGreen,
                        shape:
                            BoxShape.circle,
                      ),
                      child:
                          const Icon(
                        Icons.person_rounded,
                        size: 38,
                        color:
                            AppTheme.primaryDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),

                  const Center(
                    child: Text(
                      'Professional Profile',
                      style:
                          TextStyle(
                        fontSize: 21,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme.textDark,
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  _ProfileRow(
                    label: 'Name',
                    value:
                        data['name']
                                ?.toString() ??
                            widget.expertName,
                  ),

                  _ProfileRow(
                    label: 'Expert Type',
                    value:
                        data['expertType']
                                ?.toString() ??
                            widget.expertType,
                  ),

                  _ProfileRow(
                    label: 'Qualification',
                    value:
                        data['qualification']
                                ?.toString() ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'Experience',
                    value:
                        data['experience']
                                ?.toString() ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'Workplace',
                    value:
                        data['workplace']
                                ?.toString() ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'Registration Number',
                    value:
                        data['registrationNumber']
                                ?.toString() ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'District',
                    value:
                        data['district']
                                ?.toString() ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'Email',
                    value:
                        data['email']
                                ?.toString() ??
                            user.email ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'Phone',
                    value:
                        data['phone']
                                ?.toString() ??
                            'Not provided',
                  ),

                  _ProfileRow(
                    label: 'Status',
                    value:
                        data['status']
                                ?.toString() ??
                            'approved',
                  ),

                  const SizedBox(height: 15),

                  const Text(
                    'Professional Bio',
                    style:
                        TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          AppTheme.textDark,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    data['bio']
                            ?.toString() ??
                        'No professional bio provided.',
                    style:
                        const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),

                  const SizedBox(height: 25),
                ],
              ),
            ),
          );
        },
      );
    } catch (e) {
      if (!mounted) return;

      _showComingSoon(
        'Unable to load professional profile.',
      );
    }
  }

  // =========================================================
  // COMING SOON
  // =========================================================

  void _showComingSoon(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
      ),
    );
  }
}

// ===========================================================
// QUESTION CARD
// ===========================================================

class _QuestionCard extends StatefulWidget {
  final String questionId;
  final String userName;
  final String userEmail;
  final String question;
  final dynamic createdAt;
  final VoidCallback onAnswered;

  const _QuestionCard({
    required this.questionId,
    required this.userName,
    required this.userEmail,
    required this.question,
    required this.createdAt,
    required this.onAnswered,
  });

  @override
  State<_QuestionCard> createState() =>
      _QuestionCardState();
}

class _QuestionCardState
    extends State<_QuestionCard> {
  final TextEditingController _answerController =
      TextEditingController();

  bool isSubmitting = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  // =========================================================
  // SUBMIT ANSWER
  // =========================================================

  Future<void> _submitAnswer() async {
    final answer =
        _answerController.text.trim();

    if (answer.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Please enter a response.'),
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      await FirebaseFirestore.instance
          .collection('expertQuestions')
          .doc(widget.questionId)
          .update({
        'answer': answer,
        'status': 'answered',
        'answeredAt':
            FieldValue.serverTimestamp(),
      });

      if (!mounted) return;

      widget.onAnswered();

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content:
              Text('Response submitted successfully.'),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        isSubmitting = false;
      });

      ScaffoldMessenger.of(context)
          .showSnackBar(
        SnackBar(
          content:
              Text('Unable to submit response: $e'),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    }
  }

  // =========================================================
  // FORMAT DATE
  // =========================================================

  String _formatDate() {
    if (widget.createdAt == null) {
      return 'Date not available';
    }

    try {
      if (widget.createdAt is Timestamp) {
        final date =
            (widget.createdAt as Timestamp).toDate();

        return '${date.day.toString().padLeft(2, '0')}/'
            '${date.month.toString().padLeft(2, '0')}/'
            '${date.year}';
      }
    } catch (_) {}

    return 'Date not available';
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin:
          const EdgeInsets.only(bottom: 15),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(20),
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            // =================================================
            // USER INFORMATION
            // =================================================

            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration:
                      const BoxDecoration(
                    color:
                        AppTheme.pastelBlue,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color:
                        AppTheme.primaryDark,
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.userName,
                        style:
                            const TextStyle(
                          fontSize: 15,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppTheme.textDark,
                        ),
                      ),

                      if (widget.userEmail.isNotEmpty)
                        Text(
                          widget.userEmail,
                          style:
                              const TextStyle(
                            fontSize: 11,
                            color:
                                AppTheme.textGrey,
                          ),
                        ),
                    ],
                  ),
                ),

                Text(
                  _formatDate(),
                  style:
                      const TextStyle(
                    fontSize: 11,
                    color:
                        AppTheme.textGrey,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 18),

            // =================================================
            // QUESTION
            // =================================================

            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.all(15),
              decoration:
                  BoxDecoration(
                color:
                    AppTheme.pastelYellow,
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.help_outline_rounded,
                        size: 18,
                        color:
                            AppTheme.primaryDark,
                      ),
                      SizedBox(width: 7),
                      Text(
                        'Question',
                        style:
                            TextStyle(
                          fontSize: 13,
                          fontWeight:
                              FontWeight.bold,
                          color:
                              AppTheme.primaryDark,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  Text(
                    widget.question,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color:
                          AppTheme.textDark,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // =================================================
            // RESPONSE
            // =================================================

            const Text(
              'Your Response',
              style:
                  TextStyle(
                fontSize: 14,
                fontWeight:
                    FontWeight.bold,
                color:
                    AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller:
                  _answerController,
              maxLines: 5,
              enabled: !isSubmitting,
              decoration:
                  const InputDecoration(
                hintText:
                    'Write your response here...',
                alignLabelWithHint: true,
                prefixIcon: Padding(
                  padding:
                      EdgeInsets.only(
                    bottom: 55,
                  ),
                  child: Icon(
                    Icons.edit_outlined,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed:
                    isSubmitting
                        ? null
                        : _submitAnswer,
                icon: isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child:
                            CircularProgressIndicator(
                          strokeWidth: 2,
                          color:
                              Colors.white,
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                      ),
                label: Text(
                  isSubmitting
                      ? 'Submitting...'
                      : 'Submit Response',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// DASHBOARD OPTION
// ===========================================================

class _DashboardOption
    extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _DashboardOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius:
          BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.all(17),
        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(18),
          border: Border.all(
            color:
                const Color(0xFFE8ECE9),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration:
                  BoxDecoration(
                color: color,
                borderRadius:
                    BorderRadius.circular(15),
              ),
              child: Icon(
                icon,
                color:
                    AppTheme.primaryDark,
                size: 26,
              ),
            ),

            const SizedBox(width: 15),

            Expanded(
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style:
                        const TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.textDark,
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    subtitle,
                    style:
                        const TextStyle(
                      fontSize: 12,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),
                ],
              ),
            ),

            const Icon(
              Icons.chevron_right_rounded,
              color:
                  AppTheme.textGrey,
            ),
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// MY EVENT CARD
// ===========================================================

class _MyEventCard extends StatelessWidget {
  final Event event;
  final VoidCallback onTap;

  const _MyEventCard({
    required this.event,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    if (event.status == 'approved') {
      statusColor = Colors.green;
    } else if (event.status == 'rejected') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orange;
    }

    final bool unlimitedSeats =
        event.maxSeats == 0;

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      shape:
          RoundedRectangleBorder(
        borderRadius:
            BorderRadius.circular(18),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius:
            BorderRadius.circular(18),
        child: Padding(
          padding:
              const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration:
                        BoxDecoration(
                      color: event.color,
                      borderRadius:
                          BorderRadius.circular(
                              14),
                    ),
                    child: Icon(
                      event.icon,
                      color:
                          AppTheme.primaryDark,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Text(
                      event.title,
                      style:
                          const TextStyle(
                        fontSize: 16,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            AppTheme.textDark,
                      ),
                    ),
                  ),

                  const Icon(
                    Icons.chevron_right_rounded,
                    color:
                        AppTheme.textGrey,
                  ),
                ],
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  const Icon(
                    Icons.calendar_today_outlined,
                    size: 16,
                    color:
                        AppTheme.textGrey,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    event.date,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),

                  const SizedBox(width: 15),

                  const Icon(
                    Icons.access_time_outlined,
                    size: 16,
                    color:
                        AppTheme.textGrey,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    event.time,
                    style:
                        const TextStyle(
                      fontSize: 13,
                      color:
                          AppTheme.textGrey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 18,
                    color:
                        AppTheme.primaryDark,
                  ),

                  const SizedBox(width: 7),

                  Text(
                    unlimitedSeats
                        ? '${event.participants} registered'
                        : '${event.participants}/${event.maxSeats} registered',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          AppTheme.textDark,
                    ),
                  ),

                  const Spacer(),

                  Container(
                    padding:
                        const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration:
                        BoxDecoration(
                      color:
                          statusColor.withValues(
                        alpha: 0.12,
                      ),
                      borderRadius:
                          BorderRadius.circular(
                              20),
                    ),
                    child: Text(
                      event.status.toUpperCase(),
                      style:
                          TextStyle(
                        fontSize: 10,
                        fontWeight:
                            FontWeight.bold,
                        color:
                            statusColor,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              const Text(
                'Tap to view registered participants',
                style: TextStyle(
                  fontSize: 12,
                  color:
                      AppTheme.primaryDark,
                  fontWeight:
                      FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===========================================================
// RESOURCE CARD
// ===========================================================

class _ResourceCard
    extends StatelessWidget {
  final String title;
  final String category;
  final String status;
  final String content;

  const _ResourceCard({
    required this.title,
    required this.category,
    required this.status,
    required this.content,
  });

  @override
  Widget build(BuildContext context) {
    Color statusColor;

    if (status == 'approved') {
      statusColor = Colors.green;
    } else if (status == 'rejected') {
      statusColor = Colors.redAccent;
    } else {
      statusColor = Colors.orange;
    }

    return Card(
      margin:
          const EdgeInsets.only(
        bottom: 12,
      ),
      child: Padding(
        padding:
            const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
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
                ),

                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 5,
                  ),
                  decoration:
                      BoxDecoration(
                    color:
                        statusColor.withValues(
                      alpha: 0.12,
                    ),
                    borderRadius:
                        BorderRadius.circular(20),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style:
                        TextStyle(
                      fontSize: 10,
                      fontWeight:
                          FontWeight.bold,
                      color:
                          statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 7),

            Text(
              category,
              style:
                  const TextStyle(
                fontSize: 12,
                color:
                    AppTheme.primaryDark,
                fontWeight:
                    FontWeight.w600,
              ),
            ),

            const SizedBox(height: 10),

            Text(
              content,
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
          ],
        ),
      ),
    );
  }
}

// ===========================================================
// PROFILE ROW
// ===========================================================

class _ProfileRow
    extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding:
          const EdgeInsets.only(
        bottom: 15,
      ),
      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  AppTheme.textGrey,
            ),
          ),

          const SizedBox(height: 3),

          Text(
            value,
            style:
                const TextStyle(
              fontSize: 15,
              fontWeight:
                  FontWeight.w500,
              color:
                  AppTheme.textDark,
            ),
          ),
        ],
      ),
    );
  }
}