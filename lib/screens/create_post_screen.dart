import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreatePostScreen extends StatefulWidget {
  const CreatePostScreen({super.key});

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController postController =
      TextEditingController();

  bool isAnonymous = false;

  @override
  void dispose() {
    postController.dispose();
    super.dispose();
  }

  void submitPost() {
    final post = postController.text.trim();

    if (post.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write something before posting.'),
        ),
      );
      return;
    }

    // For now, we only demonstrate successful submission.
    // Firebase/database will be connected later.

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Post created successfully!'),
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,

      appBar: AppBar(
        backgroundColor: AppTheme.background,
        elevation: 0,

        leading: IconButton(
          onPressed: () {
            Navigator.pop(context);
          },
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppTheme.textDark,
          ),
        ),

        title: const Text(
          'Create Post',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textDark,
          ),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ================= INTRODUCTION =================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),

                decoration: BoxDecoration(
                  color: AppTheme.pastelGreen,
                  borderRadius: BorderRadius.circular(18),
                ),

                child: const Row(
                  children: [

                    Icon(
                      Icons.favorite_rounded,
                      color: AppTheme.primaryDark,
                      size: 30,
                    ),

                    SizedBox(width: 12),

                    Expanded(
                      child: Text(
                        'Share your thoughts, experiences, '
                        'questions or encouragement with the community.',
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          color: AppTheme.textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              // ================= USER =================

              const Text(
                'Posting as',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textGrey,
                ),
              ),

              const SizedBox(height: 10),

              Row(
                children: [

                  const CircleAvatar(
                    radius: 24,
                    backgroundColor: AppTheme.pastelBlue,
                    child: Icon(
                      Icons.person_rounded,
                      color: AppTheme.primaryDark,
                    ),
                  ),

                  const SizedBox(width: 12),

                  const Expanded(
                    child: Text(
                      'My Profile',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textDark,
                      ),
                    ),
                  ),

                  Switch(
                    value: isAnonymous,
                    activeThumbColor: AppTheme.primary,

                    onChanged: (value) {
                      setState(() {
                        isAnonymous = value;
                      });
                    },
                  ),
                ],
              ),

              if (isAnonymous)
                const Padding(
                  padding: EdgeInsets.only(
                    left: 60,
                    top: 4,
                  ),
                  child: Text(
                    'Your name will be hidden from the post.',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.textGrey,
                    ),
                  ),
                ),

              const SizedBox(height: 25),

              // ================= POST LABEL =================

              const Text(
                'Your post',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textDark,
                ),
              ),

              const SizedBox(height: 10),

              // ================= TEXT FIELD =================

              TextField(
                controller: postController,

                maxLines: 8,
                maxLength: 500,

                textCapitalization:
                    TextCapitalization.sentences,

                decoration: InputDecoration(
                  hintText:
                      'Share your thoughts or ask the community...',
                  hintStyle: const TextStyle(
                    color: AppTheme.textGrey,
                  ),

                  filled: true,
                  fillColor: Colors.white,

                  contentPadding:
                      const EdgeInsets.all(18),

                  border: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: BorderSide.none,
                  ),

                  enabledBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: Color(0xFFE8ECE9),
                    ),
                  ),

                  focusedBorder: OutlineInputBorder(
                    borderRadius:
                        BorderRadius.circular(18),
                    borderSide: const BorderSide(
                      color: AppTheme.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 15),

              // ================= ADD IMAGE =================

              OutlinedButton.icon(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Image upload will be added later.',
                      ),
                    ),
                  );
                },

                icon: const Icon(
                  Icons.image_outlined,
                ),

                label: const Text(
                  'Add Image',
                ),

                style: OutlinedButton.styleFrom(
                  foregroundColor:
                      AppTheme.primaryDark,

                  side: const BorderSide(
                    color: AppTheme.primary,
                  ),

                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ================= COMMUNITY GUIDELINES =================

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),

                decoration: BoxDecoration(
                  color: AppTheme.pastelYellow,
                  borderRadius: BorderRadius.circular(16),
                ),

                child: const Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [

                    Row(
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 20,
                          color: AppTheme.primaryDark,
                        ),

                        SizedBox(width: 8),

                        Text(
                          'Community Guidelines',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.textDark,
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 10),

                    Text(
                      '• Be respectful and supportive.\n'
                      '• Do not share personal information.\n'
                      '• Avoid harmful or offensive content.\n'
                      '• Medical experiences should not replace professional advice.',
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.6,
                        color: AppTheme.textGrey,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              // ================= POST BUTTON =================

              SizedBox(
                width: double.infinity,
                height: 54,

                child: ElevatedButton(
                  onPressed: submitPost,

                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        AppTheme.primaryDark,

                    foregroundColor: Colors.white,

                    elevation: 0,

                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(15),
                    ),
                  ),

                  child: const Text(
                    'Publish Post',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}