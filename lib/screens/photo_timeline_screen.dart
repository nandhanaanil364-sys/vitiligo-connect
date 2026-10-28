import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../theme/app_theme.dart';

class PhotoTimelineScreen extends StatefulWidget {
  const PhotoTimelineScreen({super.key});

  @override
  State<PhotoTimelineScreen> createState() =>
      _PhotoTimelineScreenState();
}

class _PhotoTimelineScreenState
    extends State<PhotoTimelineScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // ==========================================================
  // BUILD
  // ==========================================================

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        title: const Text(
          'My Photo Timeline',
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ),

      // ========================================================
      // ADD PHOTO BUTTON
      // ========================================================

      floatingActionButton: FloatingActionButton.extended(
        onPressed: user == null ? null : _addPhoto,
        backgroundColor: AppTheme.primaryDark,
        foregroundColor: Colors.white,
        icon: const Icon(
          Icons.add_a_photo_rounded,
        ),
        label: const Text(
          'Add Photo',
          style: TextStyle(
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // ========================================================
      // BODY
      // ========================================================

      body: user == null
          ? const Center(
              child: Text(
                'Please login to access your photo timeline.',
                style: TextStyle(
                  color: AppTheme.textGrey,
                ),
              ),
            )
          : StreamBuilder<
              QuerySnapshot<Map<String, dynamic>>
            >(
              stream: _firestore
                  .collection('users')
                  .doc(user.uid)
                  .collection('photoTimeline')
                  .orderBy(
                    'createdAt',
                    descending: true,
                  )
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
                  debugPrint(
                    'PHOTO TIMELINE ERROR: ${snapshot.error}',
                  );

                  return _errorState();
                }

                final documents =
                    snapshot.data?.docs ?? [];

                if (documents.isEmpty) {
                  return _emptyTimeline();
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    20,
                    10,
                    20,
                    100,
                  ),
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];

                    final photo =
                        PhotoEntry.fromFirestore(
                      document,
                    );

                    return _PhotoCard(
                      photo: photo,
                      onDelete: () {
                        _confirmDelete(
                          document.id,
                        );
                      },
                    );
                  },
                );
              },
            ),
    );
  }

  // ==========================================================
  // EMPTY TIMELINE
  // ==========================================================

  Widget _emptyTimeline() {
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
                color: AppTheme.pastelBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.photo_library_outlined,
                size: 42,
                color: AppTheme.primaryDark,
              ),
            ),

            const SizedBox(height: 22),

            const Text(
              'Your Private Photo Timeline',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 10),

            const Text(
              'Keep personal photos and memories of '
              'your journey in one private place.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.textGrey,
                height: 1.5,
              ),
            ),

            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 10,
              ),
              decoration: BoxDecoration(
                color: AppTheme.pastelYellow,
                borderRadius:
                    BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.lock_outline_rounded,
                    size: 17,
                    color: AppTheme.primaryDark,
                  ),
                  SizedBox(width: 7),
                  Text(
                    'Private photos',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textDark,
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

  // ==========================================================
  // ADD PHOTO DIALOG
  // ==========================================================

  void _addPhoto() {
    final captionController =
        TextEditingController();

    XFile? selectedImage;

    Uint8List? selectedImageBytes;

    bool isUploading = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (
            context,
            setDialogState,
          ) {
            return AlertDialog(
              title: const Text(
                'Add Photo',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              content: SizedBox(
                width: 420,

                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [

                      // ==================================================
                      // PHOTO PREVIEW AREA
                      // ==================================================

                      GestureDetector(
                        onTap: isUploading
                            ? null
                            : () async {
                                try {
                                  final image =
                                      await _picker.pickImage(
                                    source:
                                        ImageSource.gallery,
                                  );

                                  if (image == null) {
                                    return;
                                  }

                                  debugPrint(
                                    'PHOTO: Image selected.',
                                  );

                                  final originalBytes =
                                      await image.readAsBytes();

                                  debugPrint(
                                    'PHOTO: Image bytes read.',
                                  );

                                  // Compress image
                                  final compressedBytes =
                                      await _compressImage(
                                    originalBytes,
                                  );

                                  debugPrint(
                                    'PHOTO: Image compressed.',
                                  );

                                  setDialogState(() {
                                    selectedImage =
                                        image;

                                    selectedImageBytes =
                                        compressedBytes;
                                  });
                                } catch (e) {
                                  debugPrint(
                                    'IMAGE PICKER ERROR: $e',
                                  );

                                  if (!mounted) {
                                    return;
                                  }

                                  ScaffoldMessenger
                                          .of(context)
                                      .showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Unable to select image: $e',
                                      ),
                                    ),
                                  );
                                }
                              },

                        child: Container(
                          width: double.infinity,
                          height: 200,

                          decoration:
                              BoxDecoration(
                            color:
                                AppTheme.pastelBlue,
                            borderRadius:
                                BorderRadius.circular(
                              16,
                            ),
                          ),

                          child:
                              selectedImageBytes ==
                                      null

                                  // ==================================================
                                  // NO IMAGE
                                  // ==================================================

                                  ? const Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment
                                              .center,
                                      children: [
                                        Icon(
                                          Icons
                                              .add_a_photo_outlined,
                                          size: 42,
                                          color: AppTheme
                                              .primaryDark,
                                        ),

                                        SizedBox(
                                          height: 8,
                                        ),

                                        Text(
                                          'Tap to choose a photo',
                                          style:
                                              TextStyle(
                                            fontSize:
                                                13,
                                            color: AppTheme
                                                .textGrey,
                                          ),
                                        ),
                                      ],
                                    )

                                  // ==================================================
                                  // SELECTED IMAGE
                                  // ==================================================

                                  : ClipRRect(
                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        16,
                                      ),

                                      child:
                                          Image.memory(
                                        selectedImageBytes!,
                                        width:
                                            double.infinity,
                                        height: 200,
                                        fit: BoxFit.cover,

                                        gaplessPlayback:
                                            true,

                                        errorBuilder:
                                            (
                                          context,
                                          error,
                                          stackTrace,
                                        ) {
                                          return const Center(
                                            child:
                                                Icon(
                                              Icons
                                                  .broken_image_outlined,
                                              size: 50,
                                              color: AppTheme
                                                  .primaryDark,
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ==================================================
                      // CAPTION
                      // ==================================================

                      TextField(
                        controller:
                            captionController,
                        maxLines: 3,

                        decoration:
                            InputDecoration(
                          labelText: 'Caption',
                          hintText:
                              'Add a note about this photo (optional)',
                          alignLabelWithHint: true,

                          border:
                              OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(
                              12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ========================================================
              // BUTTONS
              // ========================================================

              actions: [
                TextButton(
                  onPressed: isUploading
                      ? null
                      : () {
                          Navigator.pop(
                            dialogContext,
                          );
                        },
                  child: const Text(
                    'Cancel',
                  ),
                ),

                ElevatedButton(
                  onPressed: isUploading
                      ? null
                      : () async {
                          if (selectedImage ==
                                  null ||
                              selectedImageBytes ==
                                  null) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Please select a photo first.',
                                ),
                              ),
                            );

                            return;
                          }

                          setDialogState(() {
                            isUploading = true;
                          });

                          debugPrint(
                            'PHOTO: Starting Firestore save...',
                          );

                          final success =
                              await _savePhotoToFirestore(
                            selectedImageBytes!,
                            captionController
                                .text
                                .trim(),
                          );

                          if (!mounted) {
                            return;
                          }

                          if (success) {
                            Navigator.pop(
                              dialogContext,
                            );

                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Photo added successfully. 📸',
                                ),
                                behavior:
                                    SnackBarBehavior
                                        .floating,
                              ),
                            );
                          } else {
                            setDialogState(() {
                              isUploading = false;
                            });
                          }
                        },

                  child: isUploading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                        ),
                ),
              ],
            );
          },
        );
      },
    ).then((_) {
      captionController.dispose();
    });
  }

  // ==========================================================
  // COMPRESS IMAGE
  // ==========================================================

  Future<Uint8List> _compressImage(
    Uint8List originalBytes,
  ) async {
    try {
      final decodedImage =
          img.decodeImage(originalBytes);

      if (decodedImage == null) {
        return originalBytes;
      }

      debugPrint(
        'Original image: '
        '${decodedImage.width} x ${decodedImage.height}',
      );

      // Resize large images.
      img.Image resizedImage =
          decodedImage;

      if (decodedImage.width > 900) {
        resizedImage = img.copyResize(
          decodedImage,
          width: 900,
        );
      }

      // Start with JPEG quality 65.
      Uint8List compressed =
          Uint8List.fromList(
        img.encodeJpg(
          resizedImage,
          quality: 65,
        ),
      );

      // If still large, reduce quality.
      if (compressed.length > 700000) {
        compressed =
            Uint8List.fromList(
          img.encodeJpg(
            resizedImage,
            quality: 50,
          ),
        );
      }

      // If still large, resize further.
      if (compressed.length > 700000) {
        final smaller =
            img.copyResize(
          resizedImage,
          width: 700,
        );

        compressed =
            Uint8List.fromList(
          img.encodeJpg(
            smaller,
            quality: 50,
          ),
        );
      }

      debugPrint(
        'Compressed size: '
        '${compressed.length} bytes',
      );

      return compressed;
    } catch (e) {
      debugPrint(
        'IMAGE COMPRESSION ERROR: $e',
      );

      return originalBytes;
    }
  }

  // ==========================================================
  // SAVE PHOTO TO FIRESTORE
  // ==========================================================

  Future<bool> _savePhotoToFirestore(
    Uint8List imageBytes,
    String caption,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        _showError(
          'Please login again.',
        );

        return false;
      }

      // Convert image bytes to Base64.
      final base64Image =
          base64Encode(imageBytes);

      debugPrint(
        'PHOTO: Base64 conversion complete.',
      );

      debugPrint(
        'PHOTO: Saving to Firestore...',
      );

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('photoTimeline')
          .add({
        'imageBase64': base64Image,
        'caption': caption,
        'createdAt':
            FieldValue.serverTimestamp(),
      });

      debugPrint(
        'PHOTO: Firestore save successful.',
      );

      return true;
    } catch (e) {
      debugPrint(
        'FIRESTORE PHOTO SAVE ERROR: $e',
      );

      if (mounted) {
        _showError(
          'Unable to save photo: $e',
        );
      }

      return false;
    }
  }

  // ==========================================================
  // DELETE CONFIRMATION
  // ==========================================================

  void _confirmDelete(
    String documentId,
  ) {
    showDialog(
      context: context,

      builder: (dialogContext) {
        return AlertDialog(
          title: const Text(
            'Delete Photo?',
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),

          content: const Text(
            'This photo will be permanently removed '
            'from your private timeline.',
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  dialogContext,
                );
              },

              child: const Text(
                'Cancel',
              ),
            ),

            TextButton(
              onPressed: () async {
                Navigator.pop(
                  dialogContext,
                );

                await _deletePhoto(
                  documentId,
                );
              },

              style: TextButton.styleFrom(
                foregroundColor:
                    Colors.redAccent,
              ),

              child: const Text(
                'Delete',
              ),
            ),
          ],
        );
      },
    );
  }

  // ==========================================================
  // DELETE PHOTO FROM FIRESTORE
  // ==========================================================

  Future<void> _deletePhoto(
    String documentId,
  ) async {
    try {
      final user = _auth.currentUser;

      if (user == null) {
        return;
      }

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('photoTimeline')
          .doc(documentId)
          .delete();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Photo removed.',
          ),
          behavior:
              SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint(
        'DELETE PHOTO ERROR: $e',
      );

      _showError(
        'Unable to delete photo.',
      );
    }
  }

  // ==========================================================
  // ERROR MESSAGE
  // ==========================================================

  void _showError(
    String message,
  ) {
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(
      SnackBar(
        content: Text(message),
        behavior:
            SnackBarBehavior.floating,
        duration:
            const Duration(seconds: 5),
      ),
    );
  }

  // ==========================================================
  // ERROR STATE
  // ==========================================================

  Widget _errorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_off_rounded,
              size: 55,
              color: AppTheme.primaryDark,
            ),

            const SizedBox(height: 15),

            const Text(
              'Unable to load photos',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textDark,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Please check your connection and try again.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppTheme.textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// PHOTO MODEL
// ============================================================

class PhotoEntry {
  final String id;
  final String imageBase64;
  final String caption;
  final DateTime date;

  PhotoEntry({
    required this.id,
    required this.imageBase64,
    required this.caption,
    required this.date,
  });

  factory PhotoEntry.fromFirestore(
    QueryDocumentSnapshot<
        Map<String, dynamic>> document,
  ) {
    final data = document.data();

    final Timestamp? timestamp =
        data['createdAt'] is Timestamp
            ? data['createdAt'] as Timestamp
            : null;

    return PhotoEntry(
      id: document.id,

      imageBase64:
          data['imageBase64']
                  ?.toString() ??
              '',

      caption:
          data['caption']
                  ?.toString() ??
              '',

      date:
          timestamp?.toDate() ??
              DateTime.now(),
    );
  }
}

// ============================================================
// PHOTO CARD
// ============================================================

class _PhotoCard extends StatelessWidget {
  final PhotoEntry photo;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Uint8List? imageBytes;

    // Convert Base64 back to bytes.
    try {
      if (photo.imageBase64.isNotEmpty) {
        imageBytes =
            base64Decode(
          photo.imageBase64,
        );
      }
    } catch (e) {
      debugPrint(
        'IMAGE DECODING ERROR: $e',
      );
    }

    return Container(
      margin:
          const EdgeInsets.only(
        bottom: 18,
      ),

      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius:
            BorderRadius.circular(18),
        border: Border.all(
          color:
              const Color(0xFFE8ECE9),
        ),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [

          // ==================================================
          // IMAGE
          // ==================================================

          SizedBox(
            width: double.infinity,
            height: 230,

            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(
                top: Radius.circular(18),
              ),

              child: imageBytes == null
                  ? const Center(
                      child: Icon(
                        Icons
                            .broken_image_outlined,
                        size: 55,
                        color:
                            AppTheme
                                .primaryDark,
                      ),
                    )

                  : Image.memory(
                      imageBytes,
                      width:
                          double.infinity,
                      height: 230,
                      fit: BoxFit.cover,

                      errorBuilder:
                          (
                        context,
                        error,
                        stackTrace,
                      ) {
                        return const Center(
                          child: Icon(
                            Icons
                                .broken_image_outlined,
                            size: 55,
                            color:
                                AppTheme
                                    .primaryDark,
                          ),
                        );
                      },
                    ),
            ),
          ),

          // ==================================================
          // DETAILS
          // ==================================================

          Padding(
            padding:
                const EdgeInsets.all(16),

            child: Column(
              crossAxisAlignment:
                  CrossAxisAlignment.start,

              children: [

                Row(
                  children: [
                    const Icon(
                      Icons
                          .calendar_today_outlined,
                      size: 15,
                      color:
                          AppTheme.textGrey,
                    ),

                    const SizedBox(
                      width: 6,
                    ),

                    Text(
                      _formatDate(
                        photo.date,
                      ),
                      style:
                          const TextStyle(
                        fontSize: 12,
                        color:
                            AppTheme.textGrey,
                      ),
                    ),

                    const Spacer(),

                    const Icon(
                      Icons
                          .lock_outline_rounded,
                      size: 15,
                      color:
                          AppTheme.textGrey,
                    ),

                    const SizedBox(
                      width: 4,
                    ),

                    const Text(
                      'Private',
                      style:
                          TextStyle(
                        fontSize: 11,
                        color:
                            AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),

                if (photo.caption
                    .isNotEmpty) ...[
                  const SizedBox(
                    height: 10,
                  ),

                  Text(
                    photo.caption,
                    style:
                        const TextStyle(
                      fontSize: 14,
                      color:
                          AppTheme.textDark,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(
                  height: 5,
                ),

                Align(
                  alignment:
                      Alignment.centerRight,

                  child: IconButton(
                    onPressed:
                        onDelete,

                    icon: const Icon(
                      Icons
                          .delete_outline_rounded,
                    ),

                    color:
                        Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================================
  // DATE FORMAT
  // ==========================================================

  static String _formatDate(
    DateTime date,
  ) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/'
        '${date.year}';
  }
}