
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../theme/app_theme.dart';

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  final TextEditingController journalController =
      TextEditingController();

  final TextEditingController detailsController =
      TextEditingController();

  final ImagePicker _imagePicker = ImagePicker();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  File? selectedImage;
  bool isSaving = false;

  User? get currentUser => _auth.currentUser;

  @override
  void dispose() {
    journalController.dispose();
    detailsController.dispose();
    super.dispose();
  }

  // ============================================================
  // PICK IMAGE
  // ============================================================

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );

      if (image == null || !mounted) return;

      setState(() {
        selectedImage = File(image.path);
      });
    } catch (e) {
      debugPrint('IMAGE PICKER ERROR: $e');
      _showMessage('Unable to select image.');
    }
  }

  void _removeImage() {
    setState(() {
      selectedImage = null;
    });
  }

  // ============================================================
  // COMPRESS IMAGE
  // ============================================================

  Uint8List _compressImage(Uint8List originalBytes) {
    final decoded = img.decodeImage(originalBytes);

    if (decoded == null) {
      throw Exception('Unable to process this image.');
    }

    // Resize large images while preserving aspect ratio.
    final resized = decoded.width > 700
        ? img.copyResize(decoded, width: 700)
        : decoded;

    // Compress as JPEG.
    return Uint8List.fromList(
      img.encodeJpg(resized, quality: 45),
    );
  }

  // ============================================================
  // SAVE JOURNAL ENTRY
  // ============================================================

  Future<void> _saveEntry() async {
    final user = currentUser;

    if (user == null) {
      _showMessage('Please log in again to save your journal.');
      return;
    }

    if (isSaving) return;

    final journalText = journalController.text.trim();
    final detailsText = detailsController.text.trim();

    if (journalText.isEmpty &&
        detailsText.isEmpty &&
        selectedImage == null) {
      _showMessage(
        'Add a thought, detail or photo before saving.',
      );
      return;
    }

    setState(() {
      isSaving = true;
    });

    try {
      String imageBase64 = '';

      if (selectedImage != null) {
        final originalBytes = await selectedImage!.readAsBytes();
        final compressedBytes = _compressImage(originalBytes);

        imageBase64 = base64Encode(compressedBytes);
      }

      final documentReference = _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journalEntries')
          .doc();

      final entryData = <String, dynamic>{
        'userId': user.uid,
        'journalText': journalText,
        'details': detailsText,
        'imageBase64': imageBase64,
        'imageUrl': '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Check approximate serialized size before saving.
      final estimatedBytes = utf8.encode(
        jsonEncode({
          ...entryData,
          'createdAt': DateTime.now().toIso8601String(),
        }),
      ).length;

      // Keep a safety margin below Firestore's 1 MiB document limit.
      if (estimatedBytes > 850000) {
        throw Exception(
          'Photo is too large. Please select a smaller photo.',
        );
      }

      await documentReference.set(entryData);

      if (!mounted) return;

      journalController.clear();
      detailsController.clear();

      setState(() {
        selectedImage = null;
        isSaving = false;
      });

      _showMessage('Journal entry saved successfully.');
    } catch (e) {
      debugPrint('SAVE JOURNAL ERROR: $e');

      if (!mounted) return;

      setState(() {
        isSaving = false;
      });

      final message = e.toString().contains('too large')
          ? 'Photo is too large. Please choose a smaller photo.'
          : 'Unable to save journal entry. Please try again.';

      _showMessage(message);
    }
  }

  // ============================================================
  // SHOW MESSAGE
  // ============================================================

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // OPEN OLD FIREBASE STORAGE IMAGE
  // ============================================================

  void _openFullScreenImage(String imageUrl) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenJournalImage(
          imageUrl: imageUrl,
        ),
      ),
    );
  }

  void _openBase64Image(Uint8List imageBytes) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenJournalBase64Image(
          imageBytes: imageBytes,
        ),
      ),
    );
  }

  // ============================================================
  // DELETE JOURNAL ENTRY
  // ============================================================

  Future<void> _deleteEntry(
    DocumentSnapshot document,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          title: const Text(
            'Delete Entry?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          content: const Text(
            'This journal entry and its photo will be permanently removed.',
            style: TextStyle(color: AppTheme.textGrey),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryDark,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) return;

    try {
      final user = currentUser;
      if (user == null) return;

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('journalEntries')
          .doc(document.id)
          .delete();

      if (!mounted) return;

      _showMessage('Journal entry deleted.');
    } catch (e) {
      debugPrint('DELETE JOURNAL ERROR: $e');

      if (!mounted) return;

      _showMessage('Unable to delete journal entry.');
    }
  }

  // ============================================================
  // FORMAT DATE
  // ============================================================

  String _formatDate(Timestamp? timestamp) {
    if (timestamp == null) return 'Saving...';

    final date = timestamp.toDate();

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  // ============================================================
  // BUILD SCREEN
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final user = currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textDark,
          ),
        ),
        title: const Text(
          'My Journal',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 14),
            child: Icon(
              Icons.lock_outline_rounded,
              color: AppTheme.primaryDark,
              size: 21,
            ),
          ),
        ],
      ),
      body: user == null
          ? const Center(
              child: Text(
                'Please log in to access your journal.',
              ),
            )
          : SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  20,
                  10,
                  20,
                  30,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // INTRODUCTION
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: AppTheme.pastelGreen,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.auto_stories_rounded,
                              color: AppTheme.primaryDark,
                              size: 26,
                            ),
                          ),
                          const SizedBox(width: 14),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Your Personal Space',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textDark,
                                  ),
                                ),
                                SizedBox(height: 6),
                                Text(
                                  'Record your thoughts, progress, experiences and photos privately.',
                                  style: TextStyle(
                                    fontSize: 13,
                                    height: 1.5,
                                    color: AppTheme.textGrey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 25),

                    const Text(
                      'New Journal Entry',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Capture a moment from your journey.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // JOURNAL TEXT
                    TextField(
                      controller: journalController,
                      maxLines: 5,
                      maxLength: 500,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'How are you feeling today?',
                        hintStyle: const TextStyle(
                          color: AppTheme.textGrey,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(17),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8ECE9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    // SELECTED PHOTO
                    if (selectedImage != null)
                      Stack(
                        children: [
                          GestureDetector(
                            onTap: () {
                              _openLocalImage(selectedImage!);
                            },
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: Image.file(
                                selectedImage!,
                                width: double.infinity,
                                height: 280,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 10,
                            right: 10,
                            child: GestureDetector(
                              onTap: _removeImage,
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickImage,
                        icon: const Icon(
                          Icons.add_a_photo_outlined,
                        ),
                        label: const Text('Add Photo'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryDark,
                          side: const BorderSide(
                            color: AppTheme.primary,
                          ),
                          minimumSize: const Size(
                            double.infinity,
                            48,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13),
                          ),
                        ),
                      ),

                    const SizedBox(height: 15),

                    // DETAILS
                    TextField(
                      controller: detailsController,
                      maxLines: 4,
                      maxLength: 300,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        labelText: 'Progress / Details',
                        hintText:
                            'What would you like to remember about this moment?',
                        hintStyle: const TextStyle(
                          color: AppTheme.textGrey,
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.all(17),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: Color(0xFFE8ECE9),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(18),
                          borderSide: const BorderSide(
                            color: AppTheme.primary,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // SAVE BUTTON
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        onPressed: isSaving ? null : _saveEntry,
                        icon: isSaving
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(
                                Icons.bookmark_add_outlined,
                              ),
                        label: Text(
                          isSaving
                              ? 'Saving...'
                              : 'Save to My Journal',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryDark,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppTheme.primaryDark.withOpacity(0.6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 30),

                    const Text(
                      'My Photo Timeline',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'A personal record of your journey.',
                      style: TextStyle(
                        fontSize: 13,
                        color: AppTheme.textGrey,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // FIRESTORE TIMELINE
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _firestore
                          .collection('users')
                          .doc(user.uid)
                          .collection('journalEntries')
                          .orderBy(
                            'createdAt',
                            descending: true,
                          )
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(30),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return _buildErrorTimeline(
                            snapshot.error.toString(),
                          );
                        }

                        final documents = snapshot.data?.docs ?? [];

                        if (documents.isEmpty) {
                          return _buildEmptyTimeline();
                        }

                        return Column(
                          children: documents
                              .map(_buildTimelineEntry)
                              .toList(),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ============================================================
  // LOCAL FULL-SCREEN IMAGE
  // ============================================================

  void _openLocalImage(File image) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenLocalImage(image: image),
      ),
    );
  }

  // ============================================================
  // EMPTY TIMELINE
  // ============================================================

  Widget _buildEmptyTimeline() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE8ECE9),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              color: AppTheme.pastelBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.photo_library_outlined,
              color: AppTheme.primaryDark,
              size: 29,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Your timeline is empty',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Add your first photo and journal entry to start recording your journey.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // ERROR TIMELINE
  // ============================================================

  Widget _buildErrorTimeline(String error) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.pastelPink,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: AppTheme.primaryDark,
            size: 32,
          ),
          const SizedBox(height: 10),
          const Text(
            'Unable to load your journal',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.textGrey,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // TIMELINE ENTRY
  // ============================================================

  Widget _buildTimelineEntry(
    QueryDocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final journalText = data['journalText']?.toString() ?? '';
    final details = data['details']?.toString() ?? '';
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final imageBase64 = data['imageBase64']?.toString() ?? '';

    final Timestamp? createdAt =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    Uint8List? imageBytes;

    try {
      if (imageBase64.isNotEmpty) {
        imageBytes = base64Decode(imageBase64);
      }
    } catch (e) {
      debugPrint('JOURNAL IMAGE DECODE ERROR: $e');
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFE8ECE9),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // PHOTO: supports new Base64 entries and old image URLs.
          if (imageBytes != null || imageUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                if (imageBytes != null) {
                  _openBase64Image(imageBytes!);
                } else {
                  _openFullScreenImage(imageUrl);
                }
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20),
                ),
                child: imageBytes != null
                    ? Image.memory(
                        imageBytes!,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _brokenImage(),
                      )
                    : Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 300,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;

                          return const SizedBox(
                            height: 300,
                            child: Center(
                              child: CircularProgressIndicator(),
                            ),
                          );
                        },
                        errorBuilder: (_, __, ___) => _brokenImage(),
                      ),
              ),
            ),

          // CONTENT
          Padding(
            padding: const EdgeInsets.all(17),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 15,
                      color: AppTheme.primaryDark,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _formatDate(createdAt),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textGrey,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => _deleteEntry(document),
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),

                if (journalText.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    journalText,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.5,
                      color: AppTheme.textDark,
                    ),
                  ),
                ],

                if (details.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: AppTheme.pastelYellow,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.edit_note_rounded,
                          size: 20,
                          color: AppTheme.primaryDark,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            details,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.45,
                              color: AppTheme.textDark,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _brokenImage() {
    return Container(
      height: 300,
      color: AppTheme.pastelBlue,
      child: const Center(
        child: Icon(
          Icons.broken_image_outlined,
          size: 45,
          color: AppTheme.primaryDark,
        ),
      ),
    );
  }
}

// ================================================================
// FULL-SCREEN OLD FIREBASE IMAGE
// ================================================================

class FullScreenJournalImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenJournalImage({
    super.key,
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;

              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            },
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FULL-SCREEN BASE64 IMAGE
// ================================================================

class FullScreenJournalBase64Image extends StatelessWidget {
  final Uint8List imageBytes;

  const FullScreenJournalBase64Image({
    super.key,
    required this.imageBytes,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.memory(
            imageBytes,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}

// ================================================================
// FULL-SCREEN LOCAL IMAGE
// ================================================================

class FullScreenLocalImage extends StatelessWidget {
  final File image;

  const FullScreenLocalImage({
    super.key,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 1,
          maxScale: 4,
          child: Image.file(
            image,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}
